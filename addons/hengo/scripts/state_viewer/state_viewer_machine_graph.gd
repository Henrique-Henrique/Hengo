@tool
class_name HenStateViewerMachineGraph extends Control

@onready var nodes_container: Control = %NodesContainer
@onready var edges_overlay: HenStateViewerEdgesOverlay = %HenStateViewerEdgesOverlay

var parser: HenStateViewerDataParser = HenStateViewerDataParser.new()
var measurer: HenStateViewerUIMeasurer = HenStateViewerUIMeasurer.new()
var layout: HenStateViewerLayoutEngine = HenStateViewerLayoutEngine.new()

var graph_root: HenStateViewerGraphTypes.DirectedGraphNode

const COMPOUND_BG: Color = Color(0.119071566, 0.119075276, 0.1496324, 1)
const COMPOUND_BORDER: Color = Color(0.18992361, 0.18994236, 0.23241404, 1)
const COMPOUND_BODY_BG: Color = Color(0.119071566, 0.119075276, 0.1496324, 0.35)
const LEAF_BG: Color = Color(0.20258576, 0.2025904, 0.2280235, 1)
const LEAF_BORDER: Color = Color(0.27, 0.27, 0.31, 1)
const LABEL_COLOR: Color = Color(0.9, 0.9, 0.9, 1)
const CURRENT_BORDER: Color = Color('#e67e22')
const DIM_ALPHA: float = 0.2
const DOUBLE_CLICK_MS: int = 400
const CLICK_TOLERANCE: float = 6.0
const TRANSITION_ICON: String = 'arrow-right-to-line'

var _panels: Dictionary = {}
var _active_node: HenStateViewerGraphTypes.DirectedGraphNode = null
var _active_edge: HenStateViewerGraphTypes.DirectedGraphEdge = null

# script display name -> active state (snake_case) for that script's machine
var _debug_active_states: Dictionary = {}

# when true the graph shows only the active script instead of the whole collection
var _only_current_script: bool = false

# left double-click tracking (toggles both side panels)
var _click_press_pos: Vector2 = Vector2.ZERO
var _click_last_time: int = 0
var _click_last_pos: Vector2 = Vector2.ZERO


func _ready() -> void:
	if HenUtils.disable_scene_with_owner(self ):
		return
	
	if EditorInterface.get_edited_scene_root() is HenHengoRoot:
		return

	nodes_container.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var signal_bus: HenSignalBus = Engine.get_singleton(&'SignalBus')
	if signal_bus:
		if not signal_bus.add_virtual_cnode_to_route.is_connected(_on_cnode_changed):
			signal_bus.add_virtual_cnode_to_route.connect(_on_cnode_changed)
		if not signal_bus.remove_virtual_cnode_from_route.is_connected(_on_cnode_changed):
			signal_bus.remove_virtual_cnode_from_route.connect(_on_cnode_changed)
		if not signal_bus.request_list_update.is_connected(_on_graph_changed_no_args):
			signal_bus.request_list_update.connect(_on_graph_changed_no_args)
		if not signal_bus.request_structural_update.is_connected(_on_graph_changed_no_args):
			signal_bus.request_structural_update.connect(_on_graph_changed_no_args)
		if not signal_bus.scripts_generation_finished.is_connected(_on_graph_changed_no_args):
			signal_bus.scripts_generation_finished.connect(_on_graph_changed_no_args)

		if not signal_bus.route_changed.is_connected(_on_route_changed):
			signal_bus.route_changed.connect(_on_route_changed)

		if not signal_bus.debug_state_changed.is_connected(_on_debug_state_changed):
			signal_bus.debug_state_changed.connect(_on_debug_state_changed)
		if not signal_bus.debug_flow_transition.is_connected(_on_debug_flow_transition):
			signal_bus.debug_flow_transition.connect(_on_debug_flow_transition)
		if not signal_bus.debug_state_flow.is_connected(_on_debug_state_flow):
			signal_bus.debug_state_flow.connect(_on_debug_state_flow)
		if not signal_bus.debug_state_transition.is_connected(_on_debug_state_transition):
			signal_bus.debug_state_transition.connect(_on_debug_state_transition)

	_update_graph()


func _gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return

	var mb: InputEventMouseButton = event as InputEventMouseButton
	if mb.button_index != MOUSE_BUTTON_LEFT:
		return

	if mb.pressed:
		_click_press_pos = mb.position
		return

	# drags never count as a click
	var is_click: bool = mb.position.distance_to(_click_press_pos) <= CLICK_TOLERANCE

	# a state under the cursor gets selected; only the empty background toggles the panels
	if _active_node != null or _active_edge != null:
		_click_last_time = 0
		if is_click and _is_state_node(_active_node):
			_open_state(_active_node)
		return

	if not is_click:
		_click_last_time = 0
		return

	var now: int = Time.get_ticks_msec()

	if now - _click_last_time <= DOUBLE_CLICK_MS and mb.position.distance_to(_click_last_pos) <= CLICK_TOLERANCE * 2.0:
		_click_last_time = 0
		var global: HenGlobal = Engine.get_singleton(&'Global') as HenGlobal
		if global and global.HENGO_ROOT:
			global.HENGO_ROOT.toggle_side_panels()
	else:
		_click_last_time = now
		_click_last_pos = mb.position


func _on_graph_changed_no_args(_a = null, _b = null) -> void:
	_update_graph()

func _update_graph() -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	if not global:
		return

	var scripts: Array = global.OPEN_SCRIPTS

	if _only_current_script:
		scripts = [global.SAVE_DATA] if global.SAVE_DATA else []

	build_graph(_build_collection_dict(scripts))


# switches between the whole collection and the active script only
func set_only_current_script(_value: bool) -> void:
	if _only_current_script == _value:
		return

	_only_current_script = _value
	_update_graph()


# wraps every open script as a labeled compound machine under a single root
func _build_collection_dict(open_scripts: Array) -> Dictionary:
	var root: Dictionary = { id = 'collection', states = {} }

	for save_data: HenSaveData in open_scripts:
		if not save_data:
			continue

		var script_dict: Dictionary = _build_dynamic_dict(save_data)
		if (script_dict.get('states', {}) as Dictionary).is_empty():
			continue

		root.states[save_data.identity.name] = script_dict

	return root

func _on_cnode_changed(_id: String, _vc: HenVirtualCNode) -> void:
	if _vc.sub_type == HenVirtualCNode.SubType.STATE_TRANSITION or _vc.sub_type == HenVirtualCNode.SubType.STATE_TRANSITION_FROM:
		_update_graph()

func _build_dynamic_dict(save_data: HenSaveData) -> Dictionary:
	var root_dict: Dictionary = {
		id = save_data.identity.name if save_data.identity else 'root',
		states = {}
	}
	
	var root_states: Array = []
	if save_data.states:
		for state: HenSaveState in save_data.states:
			if not state.is_sub_state:
				root_states.append(state)
	
	if root_states.is_empty():
		return root_dict
	
	root_dict.initial = root_states[0].name
	
	for state: HenSaveState in root_states:
		if state.start:
			root_dict.initial = state.name
		root_dict.states[state.name] = _build_state_dict(state, save_data)
		
	return root_dict

func _build_state_dict(state: HenSaveState, save_data: HenSaveData) -> Dictionary:
	# ids keep highlight and selection independent of state names
	var s_dict: Dictionary = {
		state_id = String(state.id),
		script_id = String(save_data.identity.id) if save_data.identity else ''
	}

	if not state.description.is_empty():
		s_dict.description = state.description

	var sub_states: Array = state.get_sub_states(save_data)
	if not sub_states.is_empty():
		s_dict.states = {}
		var valid_subs: Array = []
		
		for sub: HenSaveState in sub_states:
			if sub and is_instance_valid(sub):
				valid_subs.append(sub)
				
		if not valid_subs.is_empty():
			s_dict.initial = valid_subs[0].name
			for sub: HenSaveState in valid_subs:
				if sub.start:
					s_dict.initial = sub.name
				s_dict.states[sub.name] = _build_state_dict(sub, save_data)
	
	var on_dict: Dictionary = {}
	var on_meta: Dictionary = {}
	var route: HenRouteData = state.get_route(save_data)
	if route and route.virtual_cnode_list:
		for vc: HenVirtualCNode in route.virtual_cnode_list:
			var is_from: bool = vc.sub_type == HenVirtualCNode.SubType.STATE_TRANSITION_FROM
			if vc.sub_type == HenVirtualCNode.SubType.STATE_TRANSITION or is_from:
				var target_res: HenSaveState = null

				if vc.has_method('get_res'):
					target_res = vc.get_res(save_data) as HenSaveState

				if not target_res and not is_from and vc.get('res_data') and vc.res_data.has('id'):
					target_res = _find_state_by_id(vc.res_data.id, save_data)

				if target_res:
					var event_name: String = vc.name_to_code if vc.name_to_code and not vc.name_to_code.is_empty() else 'go_to_' + target_res.name

					var target_path: String = target_res.name

					# cross-script: qualify the target with the owning script name so the
					# edge resolves against the global graph (draws between machines)
					if is_from and vc.get('res_data') and vc.res_data.has('save_data_id'):
						var owner: String = _script_name_for_id(vc.res_data.save_data_id)
						if not owner.is_empty():
							target_path = owner + '.' + target_res.name

					on_dict[event_name] = target_path
					on_meta[event_name] = {
						kind = &'cross_script' if is_from else &'transition',
						icon = TRANSITION_ICON
					}

	_add_action_branch_edges(state, save_data, on_dict, on_meta)

	if not on_dict.is_empty():
		s_dict.on = on_dict
		s_dict.on_meta = on_meta

	return s_dict


# branching actions transition too, so their targets draw as edges. the branch
# label is what names the arrow; unnamed falls back to go_to_<target>
func _add_action_branch_edges(state: HenSaveState, save_data: HenSaveData, on_dict: Dictionary, on_meta: Dictionary) -> void:
	for action: HenSaveAction in save_data.get_state_actions(state.id):
		var macro: HenSaveMacro = HenActionsPanel.find_macro(action.macro_id)

		for key: Variant in action.branches.keys():
			var branch: Variant = action.branches[key]

			if not branch is Dictionary:
				continue

			var target: HenSaveState = HenGeneratorAction.branch_target(save_data, action, str(key))

			if not target:
				continue

			var target_path: String = target.name
			var script_id: StringName = HenGeneratorAction.branch_script_id(save_data, action, str(key))

			# cross-script: qualify with the owning script so the edge draws between machines
			if not script_id.is_empty():
				var owner: String = _script_name_for_id(script_id)

				if owner.is_empty():
					continue

				target_path = owner + '.' + target.name

			var label: String = str((branch as Dictionary).get('label', ''))
			var event_name: String = label if not label.is_empty() else 'go_to_' + target.name

			on_dict[event_name] = target_path
			on_meta[event_name] = _branch_meta(macro, script_id)


# a branch reads as cross-script first, then conditional when the macro forks. the
# icon stays the macro's own so the action type is still recognizable on the line
func _branch_meta(macro: HenSaveMacro, script_id: StringName) -> Dictionary:
	var kind: StringName = &'transition'

	if not script_id.is_empty():
		kind = &'cross_script'
	elif macro and macro.flow_outputs.size() > 1:
		kind = &'condition'

	var icon: String = macro.icon if macro and not macro.icon.is_empty() else TRANSITION_ICON

	return {kind = kind, icon = icon}


# resolves a script's display name (the key used in the collection dict) from its id
func _script_name_for_id(save_data_id: StringName) -> String:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	if not global:
		return ''
	for sd: HenSaveData in global.OPEN_SCRIPTS:
		if sd and sd.identity and str(sd.identity.id) == str(save_data_id):
			return sd.identity.name
	return ''

func _find_state_by_id(id: Variant, save_data: HenSaveData) -> HenSaveState:
	var target_id := str(id)
	for state: HenSaveState in save_data.states:
		if str(state.id) == target_id:
			return state
			
	for parent_id: StringName in save_data.sub_states:
		var subs: Array = save_data.sub_states[parent_id]
		for state: HenSaveState in subs:
			if str(state.id) == target_id:
				return state
				
	return null

func _on_debug_state_changed(state_name: StringName, script_id: String) -> void:
	if state_name == &'' and script_id == '':
		_debug_active_states.clear()
	else:
		var script_name: String = _script_name_from_id(script_id)
		if not script_name.is_empty():
			_debug_active_states[script_name] = String(state_name)
	_update_node_styles()


func _script_name_from_id(script_id: String) -> String:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	if not global:
		return ''
	for save_data: HenSaveData in global.OPEN_SCRIPTS:
		if save_data and save_data.identity and String(save_data.identity.id) == script_id:
			return save_data.identity.name
	return ''

func _on_debug_flow_transition(vc_id: int, _port: StringName) -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	if not global or not global.SAVE_DATA: return

	_flash_transition_vc(vc_id, global.SAVE_DATA)


# a branch action carries its source state and event label directly (no vc), so
# it flashes the edge the same way _add_action_branch_edges keyed it
func _on_debug_state_transition(source: String, event: String, script_id: String) -> void:
	var script_name: String = _script_name_from_id(script_id)
	if script_name.is_empty():
		return
	edges_overlay.flash_edge(script_name, source, event)


# per-script transition events carry the owning script id, so any open machine can flash
func _on_debug_state_flow(vc_id: int, _port: StringName, script_id: String) -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	if not global: return

	for save_data: HenSaveData in global.OPEN_SCRIPTS:
		if save_data and save_data.identity and String(save_data.identity.id) == script_id:
			_flash_transition_vc(vc_id, save_data)
			return


func _flash_transition_vc(vc_id: int, save_data: HenSaveData) -> void:
	var target_vc: HenVirtualCNode = _find_transition_vc(vc_id, save_data)
	if not target_vc:
		return

	# cross-script transitions (STATE_TRANSITION_FROM) flash the same way
	var is_from: bool = target_vc.sub_type == HenVirtualCNode.SubType.STATE_TRANSITION_FROM
	if target_vc.sub_type != HenVirtualCNode.SubType.STATE_TRANSITION and not is_from:
		return

	var target_res: HenSaveState = null
	if target_vc.has_method('get_res'):
		target_res = target_vc.get_res(save_data) as HenSaveState

	if not target_res and not is_from and target_vc.get('res_data') and target_vc.res_data.has('id'):
		target_res = _find_state_by_id(target_vc.res_data.id, save_data)

	if target_res:
		var event_name: String = target_vc.name_to_code if target_vc.name_to_code and not target_vc.name_to_code.is_empty() else 'go_to_' + target_res.name
		var source_state_name: String = _find_state_name_by_route(target_vc.parent_route_id, save_data)

		if not source_state_name.is_empty():
			var script_name: String = save_data.identity.name if save_data.identity else ''
			edges_overlay.flash_edge(script_name, source_state_name, event_name)


func _find_transition_vc(vc_id: int, save_data: HenSaveData) -> HenVirtualCNode:
	for state: HenSaveState in save_data.states:
		var route = state.get_route(save_data)
		if route and route.virtual_cnode_list:
			for vc in route.virtual_cnode_list:
				if int(vc.id) == vc_id:
					return vc

	for parent_id in save_data.sub_states:
		for state: HenSaveState in save_data.sub_states[parent_id]:
			var route = state.get_route(save_data)
			if route and route.virtual_cnode_list:
				for vc in route.virtual_cnode_list:
					if int(vc.id) == vc_id:
						return vc

	return null


func _find_state_name_by_route(route_id: Variant, save_data: HenSaveData) -> String:
	for state: HenSaveState in save_data.states:
		var route = state.get_route(save_data)
		if route and route.id == route_id:
			return state.name

	for parent_id in save_data.sub_states:
		for state: HenSaveState in save_data.sub_states[parent_id]:
			var route = state.get_route(save_data)
			if route and route.id == route_id:
				return state.name

	return ''

# the running state wins over the one being edited; everything else rests
func _update_node_styles() -> void:
	var current_state_id: String = _current_state_id()

	for node: HenStateViewerGraphTypes.DirectedGraphNode in _panels:
		var panel: Control = _panels[node]
		var style: StyleBoxFlat = panel.get_theme_stylebox('panel') as StyleBoxFlat
		if not style: continue

		var node_id: String = node.id
		var slices: int = node_id.get_slice_count('.')
		var short_id: String = node_id.get_slice('.', slices - 1)
		# node.id is "collection.<script_name>.<state>..."; segment 1 scopes the script
		var script_seg: String = node_id.get_slice('.', 1) if slices > 1 else ''
		var is_compound: bool = not node.children.is_empty()

		var short_id_snake: String = short_id.strip_edges().to_snake_case()
		var active_state: String = _debug_active_states.get(script_seg, '')
		if active_state != '' and short_id_snake == active_state:
			style.border_color = Color('#63ff92')
			style.set_border_width_all(2)
			style.shadow_size = 10
			style.shadow_color = Color(0.39, 1.0, 0.57, 0.30)
			style.shadow_offset = Vector2.ZERO
		elif not current_state_id.is_empty() and String(node.data.get('state_id', '')) == current_state_id:
			style.border_color = CURRENT_BORDER
			style.set_border_width_all(2)
			style.shadow_size = 10
			style.shadow_color = Color(0.90, 0.49, 0.13, 0.28)
			style.shadow_offset = Vector2.ZERO
		else:
			_apply_base_border_shadow(style, is_compound)


# id of the state route being edited, empty when the route isn't a state
func _current_state_id() -> String:
	var router: HenRouter = Engine.get_singleton(&'Router')

	if not router or not router.current_route or router.current_route.type != HenRouter.ROUTE_TYPE.STATE:
		return ''

	return String(router.current_route.id)


func _on_route_changed(_route: HenRouteData) -> void:
	_update_node_styles()


func _is_state_node(node: HenStateViewerGraphTypes.DirectedGraphNode) -> bool:
	return node != null and node.data.has('state_id')


# selects the clicked state: switches script when needed, routes to it and shows its actions
func _open_state(node: HenStateViewerGraphTypes.DirectedGraphNode) -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	if not global:
		return

	var script_id: String = String(node.data.get('script_id', ''))
	var save_data: HenSaveData = null

	for sd: HenSaveData in global.OPEN_SCRIPTS:
		if sd and sd.identity and String(sd.identity.id) == script_id:
			save_data = sd
			break

	if not save_data:
		return

	var state: HenSaveState = _find_state_by_id(node.data.get('state_id', ''), save_data)
	if not state:
		return

	(Engine.get_singleton(&'Loader') as HenLoader).set_active_script(save_data)

	var route: HenRouteData = state.get_route(save_data)
	if route:
		(Engine.get_singleton(&'Router') as HenRouter).change_route(route)

	_focus_actions_tab()


func _focus_actions_tab() -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	if not global or not global.HENGO_ROOT:
		return

	var tabs: TabContainer = global.HENGO_ROOT.get_node_or_null('%SidebarTabContainer')
	if tabs:
		tabs.current_tab = HenActionsPanel.TAB_INDEX


func _process(_delta: float) -> void:
	# hover tracking
	var mouse_pos: Vector2 = nodes_container.get_local_mouse_position()
	var hovered_node: HenStateViewerGraphTypes.DirectedGraphNode = null
	
	if edges_overlay.get_hovered_edge() == null:
		if graph_root != null:
			var all_nodes: Array[HenStateViewerGraphTypes.DirectedGraphNode] = []
			_collect_draw_order(graph_root, all_nodes)
			
			# all_nodes is ordered parents -> children
			# iterate in reverse (children -> parents) to hit the deepest node first
			for i in range(all_nodes.size() - 1, -1, -1):
				var node: HenStateViewerGraphTypes.DirectedGraphNode = all_nodes[i]
				if node == graph_root:
					continue
					
				var rect: Rect2 = Rect2(node.get_absolute(), Vector2(node.layout.width, node.layout.height))
				if rect.has_point(mouse_pos):
					hovered_node = node
					break
					
	var active_node_changed: bool = false
	if _active_node != hovered_node:
		_set_active_node(hovered_node)
		active_node_changed = true
		
	if hovered_node == null:
		var hovered_edge: HenStateViewerGraphTypes.DirectedGraphEdge = edges_overlay.get_hovered_edge()
		if _active_edge != hovered_edge or active_node_changed:
			_active_edge = hovered_edge
			_set_active_edge(hovered_edge)
	else:
		_active_edge = null


# orchestrates: parse -> build ui -> measure -> layout -> render
func build_graph(dict: Dictionary) -> void:
	for child in nodes_container.get_children():
		child.queue_free()
	_panels.clear()

	graph_root = parser.parse_machine(dict)

	# resolve transitions within each script subtree so equally-named states
	# in different scripts never cross-link
	if graph_root.children.is_empty():
		parser.resolve_edges(graph_root)
	else:
		for machine_node in graph_root.children:
			parser._resolve_node_edges(machine_node, machine_node, graph_root)

	var all_nodes: Array[HenStateViewerGraphTypes.DirectedGraphNode] = []
	_collect_draw_order(graph_root, all_nodes)

	for node in all_nodes:
		if node != graph_root:
			_spawn_panel(node)

	var font: Font = ThemeDB.fallback_font
	var font_size: int = 14
	measurer.calculate_rects(graph_root, font, font_size, true, _panels)

	layout.execute_layout(graph_root)

	for node in all_nodes:
		if node != graph_root:
			var panel: Control = _panels[node]
			panel.position = node.get_absolute()
			
			if not node.children.is_empty():
				panel.size = Vector2(node.layout.width, node.layout.height)
			else:
				panel.size = Vector2(node.layout.width, node.layout.height)

	edges_overlay.update_edges(graph_root)
	_update_node_styles()


# depth-first to get breadth-first draw order (parents before children)
func _collect_draw_order(node: HenStateViewerGraphTypes.DirectedGraphNode, arr: Array[HenStateViewerGraphTypes.DirectedGraphNode]) -> void:
	arr.append(node)
	for child in node.children:
		_collect_draw_order(child, arr)


# applies the resting border and shadow shared by spawn and debug-highlight restore
func _apply_base_border_shadow(style: StyleBoxFlat, is_compound: bool) -> void:
	style.border_color = COMPOUND_BORDER if is_compound else LEAF_BORDER
	style.set_border_width_all(2 if is_compound else 1)
	style.shadow_size = 8 if is_compound else 6
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.25 if is_compound else 0.35)
	style.shadow_offset = Vector2(0, 2)


# spawns a panel for the node before measuring
func _spawn_panel(node: HenStateViewerGraphTypes.DirectedGraphNode) -> void:
	var is_compound: bool = not node.children.is_empty()

	var panel: Control
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8

	if is_compound:
		panel = PanelContainer.new()
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		style.bg_color = COMPOUND_BODY_BG
		_apply_base_border_shadow(style, true)
		panel.add_theme_stylebox_override('panel', style)
	else:
		panel = PanelContainer.new()
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		style.bg_color = LEAF_BG
		_apply_base_border_shadow(style, false)
		style.content_margin_left = 8
		style.content_margin_right = 8
		style.content_margin_top = 8
		style.content_margin_bottom = 8
		panel.add_theme_stylebox_override('panel', style)

	nodes_container.add_child(panel)
	_panels[node] = panel

	var short_id: String = node.id.get_slice('.', node.id.get_slice_count('.') - 1)
	var is_initial: bool = false
	if node.parent != null and node.parent.data.has('initial') and node.parent.data.initial == short_id:
		is_initial = true

	if is_compound:
		var compound_vbox: VBoxContainer = VBoxContainer.new()
		compound_vbox.add_theme_constant_override('separation', 0)
		compound_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(compound_vbox)

		var header_panel: PanelContainer = PanelContainer.new()
		header_panel.name = 'Header'
		header_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		compound_vbox.add_child(header_panel)

		var header_style: StyleBoxFlat = StyleBoxFlat.new()
		header_style.bg_color = Color(0.155, 0.155, 0.195, 1.0)
		header_style.corner_radius_top_left = 6
		header_style.corner_radius_top_right = 6
		header_style.border_width_bottom = 1
		header_style.border_color = COMPOUND_BORDER.lightened(0.2)
		header_style.content_margin_left = 8
		header_style.content_margin_right = 8
		header_style.content_margin_top = 5
		header_style.content_margin_bottom = 5
		header_panel.add_theme_stylebox_override('panel', header_style)

		var vbox: VBoxContainer = VBoxContainer.new()
		vbox.add_theme_constant_override('separation', 0)
		vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		header_panel.add_child(vbox)

		var hbox: HBoxContainer = HBoxContainer.new()
		hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(hbox)

		if is_initial:
			hbox.add_child(_create_initial_indicator())

		var title_label: Label = _create_graph_label(short_id)
		hbox.add_child(title_label)

		var desc_text: String = node.data.get('description', '')
		if not desc_text.is_empty():
			var desc: Label = _create_graph_label(desc_text)
			desc.add_theme_font_size_override('font_size', 14)
			desc.add_theme_color_override('font_color', LABEL_COLOR.darkened(0.3))
			vbox.add_child(desc)
	else:
		var vbox: VBoxContainer = VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(vbox)

		var hbox: HBoxContainer = HBoxContainer.new()
		hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		hbox.add_theme_constant_override('separation', 4)
		hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(hbox)

		if is_initial:
			hbox.add_child(_create_initial_indicator())

		hbox.add_child(_create_graph_label(short_id))

		var desc_text: String = node.data.get('description', '')
		if not desc_text.is_empty():
			var desc: Label = _create_graph_label(desc_text)
			desc.add_theme_font_size_override('font_size', 14)
			desc.add_theme_color_override('font_color', LABEL_COLOR.darkened(0.3))
			desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			vbox.add_child(desc)


# creates a reusable graph label
func _create_graph_label(text: String) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_color_override('font_color', LABEL_COLOR)
	label.add_theme_font_size_override('font_size', 18)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


# creates a panel that visually represents an initial state
func _create_initial_indicator() -> TextureRect:
	var tex_rect: TextureRect = TextureRect.new()
	tex_rect.texture = preload('res://addons/hengo/assets/new_icons/circle-play.svg')
	tex_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex_rect.custom_minimum_size = Vector2(16, 16)
	tex_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tex_rect.modulate = Color('#8eef97')
	return tex_rect


func _set_active_node(node: HenStateViewerGraphTypes.DirectedGraphNode) -> void:
	_active_node = node
	edges_overlay.set_active_node(node)

	# panels ignore the mouse, so the cursor hint lives on the graph itself
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if _is_state_node(node) else Control.CURSOR_ARROW

	if _active_node == null:
		for p in _panels.values():
			if p.modulate.a != 1.0:
				p.modulate.a = 1.0
		return
		
	var visible_nodes: Dictionary = {}

	# active node itself
	visible_nodes[_active_node] = true
	_add_descendants(visible_nodes, _active_node)

	var curr: HenStateViewerGraphTypes.DirectedGraphNode = _active_node
	while curr.parent != null:
		curr = curr.parent
		visible_nodes[curr] = true

	# targets of the active node and of any state inside it
	var scoped_sources: Array = visible_nodes.keys().filter(
		func(n): return n == _active_node or _is_inside(n, _active_node)
	)
	for source_node: HenStateViewerGraphTypes.DirectedGraphNode in scoped_sources:
		for edge in source_node.edges:
			var target: HenStateViewerGraphTypes.DirectedGraphNode = edge.target
			visible_nodes[target] = true
			_add_descendants(visible_nodes, target)

			var t_curr: HenStateViewerGraphTypes.DirectedGraphNode = target
			while t_curr.parent != null:
				t_curr = t_curr.parent
				visible_nodes[t_curr] = true
			
	for n in _panels:
		var p: Control = _panels[n]
		if visible_nodes.has(n):
			if p.modulate.a != 1.0:
				p.modulate.a = 1.0
		else:
			if p.modulate.a != DIM_ALPHA:
				p.modulate.a = DIM_ALPHA


func _set_active_edge(edge: HenStateViewerGraphTypes.DirectedGraphEdge) -> void:
	if edge == null and _active_node == null:
		for p in _panels.values():
			if p.modulate.a != 1.0:
				p.modulate.a = 1.0
		return
		
	if edge == null:
		return
		
	var visible_nodes: Dictionary = {}
	
	visible_nodes[edge.source] = true
	_add_descendants(visible_nodes, edge.source)
	var curr: HenStateViewerGraphTypes.DirectedGraphNode = edge.source
	while curr.parent != null:
		curr = curr.parent
		visible_nodes[curr] = true
		
	visible_nodes[edge.target] = true
	_add_descendants(visible_nodes, edge.target)
	curr = edge.target
	while curr.parent != null:
		curr = curr.parent
		visible_nodes[curr] = true
		
	for n in _panels:
		var p: Control = _panels[n]
		if visible_nodes.has(n):
			if p.modulate.a != 1.0:
				p.modulate.a = 1.0
		else:
			if p.modulate.a != DIM_ALPHA:
				p.modulate.a = DIM_ALPHA


func _add_descendants(dict: Dictionary, node: HenStateViewerGraphTypes.DirectedGraphNode) -> void:
	for child in node.children:
		dict[child] = true
		_add_descendants(dict, child)


func _is_inside(node: HenStateViewerGraphTypes.DirectedGraphNode, ancestor: HenStateViewerGraphTypes.DirectedGraphNode) -> bool:
	var current: HenStateViewerGraphTypes.DirectedGraphNode = node.parent
	while current != null:
		if current == ancestor:
			return true
		current = current.parent
	return false
