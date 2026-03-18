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
const LEAF_BG: Color = Color(0.20258576, 0.2025904, 0.2280235, 1)
const LEAF_BORDER: Color = Color(0.2, 0.2, 0.22, 1)
const LABEL_COLOR: Color = Color(0.9, 0.9, 0.9, 1)
const DIM_ALPHA: float = 0.2

var _panels: Dictionary = {}
var _active_node: HenStateViewerGraphTypes.DirectedGraphNode = null
var _active_edge: HenStateViewerGraphTypes.DirectedGraphEdge = null

var _debug_active_state_name: StringName = &''


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

		if not signal_bus.debug_state_changed.is_connected(_on_debug_state_changed):
			signal_bus.debug_state_changed.connect(_on_debug_state_changed)
		if not signal_bus.debug_flow_transition.is_connected(_on_debug_flow_transition):
			signal_bus.debug_flow_transition.connect(_on_debug_flow_transition)

	_update_graph()

func _on_graph_changed_no_args(_a = null, _b = null) -> void:
	_update_graph()

func _update_graph() -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	if not global or not global.SAVE_DATA:
		return
		
	var machine_dict: Dictionary = _build_dynamic_dict(global.SAVE_DATA)
	if machine_dict.is_empty():
		return
		
	build_graph(machine_dict)

func _on_cnode_changed(_id: String, _vc: HenVirtualCNode) -> void:
	if _vc.sub_type == HenVirtualCNode.SubType.STATE_TRANSITION:
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
	var s_dict: Dictionary = {}
	
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
	var route: HenRouteData = state.get_route(save_data)
	if route and route.virtual_cnode_list:
		for vc: HenVirtualCNode in route.virtual_cnode_list:
			if vc.sub_type == HenVirtualCNode.SubType.STATE_TRANSITION:
				var target_res: HenSaveState = null
				
				if vc.has_method('get_res'):
					target_res = vc.get_res(save_data) as HenSaveState
				
				if not target_res and vc.get('res_data') and vc.res_data.has('id'):
					target_res = _find_state_by_id(vc.res_data.id, save_data)
					
				if target_res:
					var event_name: String = vc.name_to_code if vc.name_to_code and not vc.name_to_code.is_empty() else 'go_to_' + target_res.name
					
					var target_path: String = target_res.name
						
					on_dict[event_name] = target_path

	if not on_dict.is_empty():
		s_dict.on = on_dict
		
	return s_dict

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

func _on_debug_state_changed(state_name: StringName) -> void:
	_debug_active_state_name = state_name
	_update_debug_highlight()

func _on_debug_flow_transition(vc_id: int, _port: StringName) -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	if not global or not global.SAVE_DATA: return

	var target_vc: HenVirtualCNode = null
	for state: HenSaveState in global.SAVE_DATA.states:
		var route = state.get_route(global.SAVE_DATA)
		if route and route.virtual_cnode_list:
			for vc in route.virtual_cnode_list:
				if int(vc.id) == vc_id:
					target_vc = vc
					break
		if target_vc: break
		
	if not target_vc:
		for parent_id in global.SAVE_DATA.sub_states:
			for state: HenSaveState in global.SAVE_DATA.sub_states[parent_id]:
				var route = state.get_route(global.SAVE_DATA)
				if route and route.virtual_cnode_list:
					for vc in route.virtual_cnode_list:
						if int(vc.id) == vc_id:
							target_vc = vc
							break
				if target_vc: break
			if target_vc: break

	if not target_vc or target_vc.sub_type != HenVirtualCNode.SubType.STATE_TRANSITION:
		return

	var target_res: HenSaveState = null
	if target_vc.has_method('get_res'):
		target_res = target_vc.get_res(global.SAVE_DATA) as HenSaveState
	
	if not target_res and target_vc.get('res_data') and target_vc.res_data.has('id'):
		target_res = _find_state_by_id(target_vc.res_data.id, global.SAVE_DATA)
		
	if target_res:
		var event_name: String = target_vc.name_to_code if target_vc.name_to_code and not target_vc.name_to_code.is_empty() else 'go_to_' + target_res.name
		
		var source_state_name: String = ""
		var route_id = target_vc.parent_route_id
		
		for state: HenSaveState in global.SAVE_DATA.states:
			var route = state.get_route(global.SAVE_DATA)
			if route and route.id == route_id:
				source_state_name = state.name
				break
		
		if source_state_name.is_empty():
			for parent_id in global.SAVE_DATA.sub_states:
				for state: HenSaveState in global.SAVE_DATA.sub_states[parent_id]:
					var route = state.get_route(global.SAVE_DATA)
					if route and route.id == route_id:
						source_state_name = state.name
						break
				if not source_state_name.is_empty(): break

		if not source_state_name.is_empty():
			edges_overlay.flash_edge(source_state_name, event_name)

func _update_debug_highlight() -> void:
	for node: HenStateViewerGraphTypes.DirectedGraphNode in _panels:
		var panel: Control = _panels[node]
		var style: StyleBoxFlat = panel.get_theme_stylebox('panel') as StyleBoxFlat
		if not style: continue
		
		var node_id: String = node.id
		var short_id: String = node_id.get_slice('.', node_id.get_slice_count('.') - 1)
		var is_compound: bool = not node.children.is_empty()

		var short_id_snake: String = short_id.strip_edges().to_lower().replace(" ", "_")
		if _debug_active_state_name != &'' and short_id_snake == String(_debug_active_state_name):
			style.border_color = Color('#63ff92')
			style.set_border_width_all(2)
		else:
			style.border_color = COMPOUND_BORDER if is_compound else LEAF_BORDER
			if is_compound:
				style.set_border_width_all(2)
			else:
				style.set_border_width_all(1)


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
	parser.resolve_edges(graph_root)

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
	_update_debug_highlight()


# depth-first to get breadth-first draw order (parents before children)
func _collect_draw_order(node: HenStateViewerGraphTypes.DirectedGraphNode, arr: Array[HenStateViewerGraphTypes.DirectedGraphNode]) -> void:
	arr.append(node)
	for child in node.children:
		_collect_draw_order(child, arr)


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
		style.bg_color = Color.TRANSPARENT
		style.border_color = COMPOUND_BORDER
		style.set_border_width_all(2)
		panel.add_theme_stylebox_override('panel', style)
	else:
		panel = PanelContainer.new()
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		style.bg_color = LEAF_BG
		style.border_color = LEAF_BORDER
		style.set_border_width_all(1)
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
		header_style.bg_color = COMPOUND_BG
		header_style.corner_radius_top_left = 6
		header_style.corner_radius_top_right = 6
		header_style.content_margin_left = 6
		header_style.content_margin_right = 6
		header_style.content_margin_top = 4
		header_style.content_margin_bottom = 4
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
	tex_rect.modulate = LABEL_COLOR
	return tex_rect


func _set_active_node(node: HenStateViewerGraphTypes.DirectedGraphNode) -> void:
	_active_node = node
	edges_overlay.set_active_node(node)
	
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
		
	# targets of active node
	for edge in _active_node.edges:
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
