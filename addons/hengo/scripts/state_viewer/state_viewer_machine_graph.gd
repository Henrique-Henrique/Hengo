@tool
class_name HenStateViewerMachineGraph extends Control

@onready var nodes_container: Control = %NodesContainer
@onready var edges_overlay: HenStateViewerEdgesOverlay = %HenStateViewerEdgesOverlay

var parser: HenStateViewerDataParser = HenStateViewerDataParser.new()
var measurer: HenStateViewerUIMeasurer = HenStateViewerUIMeasurer.new()
var layout: HenStateViewerLayoutEngine = HenStateViewerLayoutEngine.new()

var graph_root: HenStateViewerGraphTypes.DirectedGraphNode

const DIM_ALPHA: float = 0.2
const DOUBLE_CLICK_MS: int = 400
const CLICK_TOLERANCE: float = 6.0
const TRANSITION_ICON: String = 'arrow-right-to-line'
const TITLE_FONT_SIZE: int = 18
const MIN_TITLE_SCREEN_PX: float = 11.0

# same window the cnode border uses for its debug flash
const RUN_TIME_MS: int = 200

# the settings value is where rows disappear; they come back a bit later so a zoom
# resting on the threshold does not re-emit every card back and forth across it
const COMPACT_HYSTERESIS: float = 1.25
const CULL_MARGIN: float = 256.0

# graph node -> HenStateViewerCard
var _panels: Dictionary = {}
var _zoom: float = 1.0
var _rebuild_pending: bool = false
var _active_node: HenStateViewerGraphTypes.DirectedGraphNode = null
var _active_edge: HenStateViewerGraphTypes.DirectedGraphEdge = null
var _cam_node: HenCam = null
var _detail_level: int = HenStateViewerCard.Detail.FULL
var _lines_hidden: bool = false
var _structure_hash: int = 0
var _last_cull_origin: Vector2 = Vector2.INF
var _last_cull_zoom: float = -1.0

# hit test order (deepest last) with the absolute rects resolved at layout time
var _hover_nodes: Array[HenStateViewerGraphTypes.DirectedGraphNode] = []
var _hover_rects: Array[Rect2] = []
var _last_hover_pos: Vector2 = Vector2.INF
var _last_hover_edge: HenStateViewerGraphTypes.DirectedGraphEdge = null
var _hovered_card: HenStateViewerCard = null
var _editing_card: HenStateViewerCard = null
var _drop_card: HenStateViewerCard = null
var _drag_node: HenStateViewerGraphTypes.DirectedGraphNode = null
# card -> {action id -> expiry msec}
var _flashes: Dictionary = {}
var _tooltip_action: String = ''
var _editor: HenStateViewerCardEditor = null

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
		if not signal_bus.debug_action_flow.is_connected(_on_debug_action_flow):
			signal_bus.debug_action_flow.connect(_on_debug_action_flow)
		if not signal_bus.debug_session_stopped.is_connected(_on_debug_session_stopped):
			signal_bus.debug_session_stopped.connect(_on_debug_session_stopped)

	var general_popup: HenGeneralPopup = Engine.get_singleton(&'GeneralPopup')
	if general_popup and not general_popup.closed.is_connected(_on_popup_closed):
		general_popup.closed.connect(_on_popup_closed)

	_update_graph()


# an inner picker closing is not the edit ending, so it waits for the whole stack
func _on_popup_closed() -> void:
	var general_popup: HenGeneralPopup = Engine.get_singleton(&'GeneralPopup')

	if general_popup and general_popup.has_open_popups():
		return

	if _rebuild_pending:
		_rebuild_pending = false
		_update_graph()
		return

	if _editor and _editor.is_editing:
		_editor.is_editing = false
		_refresh_edited_card()


func _on_debug_action_flow(action_id: StringName, script_id: String) -> void:
	for node: HenStateViewerGraphTypes.DirectedGraphNode in _panels:
		if not script_id.is_empty() and String(node.data.get('script_id', '')) != script_id:
			continue

		if _arm_flash(_panels[node], action_id):
			return


# an update action re-arms every frame, so the expiry is pushed forward instead
# of the card being redrawn again
func _arm_flash(card: HenStateViewerCard, action_id: StringName) -> bool:
	if not card.has_row(action_id):
		return false

	var entries: Dictionary = _flashes.get(card, {})

	entries[str(action_id)] = Time.get_ticks_msec() + RUN_TIME_MS
	_flashes[card] = entries

	card.set_running(entries)

	return true


func _expire_flashes() -> void:
	var now: int = Time.get_ticks_msec()

	for card: Variant in _flashes.keys():
		var entries: Dictionary = _flashes[card]
		var changed: bool = false

		for id: Variant in entries.keys():
			if int(entries[id]) <= now:
				entries.erase(id)
				changed = true

		if entries.is_empty():
			_flashes.erase(card)

		if changed and is_instance_valid(card):
			(card as HenStateViewerCard).set_running(entries)


func _on_debug_session_stopped() -> void:
	_clear_flashes()


func _clear_flashes() -> void:
	for card: Variant in _flashes:
		if is_instance_valid(card):
			(card as HenStateViewerCard).set_running({})

	_flashes.clear()


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

	if is_click and _dispatch_card_click():
		_click_last_time = 0
		return

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
			global.HENGO_ROOT.toggle_fullscreen()
	else:
		_click_last_time = now
		_click_last_pos = mb.position


func _hit_under_mouse() -> Dictionary:
	if not is_instance_valid(nodes_container):
		return {}

	var pos: Vector2 = nodes_container.get_local_mouse_position()

	return _hit_in_card(_node_index_at(pos), pos)


# a nested row still has no cross-level reorder, so only top-level rows drag
func _get_drag_data(_pos: Vector2) -> Variant:
	var hit: Dictionary = _hit_under_mouse()

	if hit.get('kind', &'') != &'row' or int(hit.get('depth', 0)) != 0:
		return null

	var preview: Control = (hit.card as HenStateViewerCard).build_row_preview(hit.action)

	if preview:
		set_drag_preview(preview)

	_drag_node = hit.node

	return {type = &'hengo_action', action = hit.action}


func _can_drop_data(_pos: Vector2, _data: Variant) -> bool:
	var action: HenSaveAction = HenActionsPanel.dragged_action(_data)
	var hit: Dictionary = _hit_under_mouse()

	# reorder across cards is not a move this list knows how to make
	if not action or hit.is_empty() or hit.node != _drag_node:
		_clear_drop_hint()
		return false

	match StringName(str(hit.kind)):
		&'row':
			if hit.action == action or int(hit.depth) != 0:
				_clear_drop_hint()
				return false

			if not HenActionsPanel.can_use_phase(action, (hit.action as HenSaveAction).phase):
				_clear_drop_hint()
				return false

			_set_drop_hint(hit.card, &'row', hit.action, _is_upper_half(hit))
			return true
		&'phase', &'phase_add':
			if not HenActionsPanel.can_use_phase(action, hit.phase):
				_clear_drop_hint()
				return false

			_set_drop_hint(hit.card, &'phase', hit.phase, false)
			return true

	_clear_drop_hint()

	return false


func _drop_data(_pos: Vector2, _data: Variant) -> void:
	var action: HenSaveAction = HenActionsPanel.dragged_action(_data)
	var hit: Dictionary = _hit_under_mouse()

	_clear_drop_hint()

	if not action or hit.is_empty() or hit.node == null:
		return

	_editor_for(hit.node)

	match StringName(str(hit.kind)):
		&'row':
			var target: HenSaveAction = hit.action
			var index: int = HenActionsPanel.drop_index(
				_editor_actions(hit.node), target, action, _is_upper_half(hit)
			)

			if index >= 0:
				_editor.move_action(action, target.phase, index)
		&'phase', &'phase_add':
			_editor.move_action(action, hit.phase, 0)


func _editor_actions(node: HenStateViewerGraphTypes.DirectedGraphNode) -> Array:
	var save_data: HenSaveData = _save_data_for(node)

	if not save_data:
		return []

	return save_data.get_state_actions(StringName(str(node.data.get('state_id', ''))))


func _is_upper_half(hit: Dictionary) -> bool:
	var rect: Rect2 = hit.rect
	var local_y: float = nodes_container.get_local_mouse_position().y - (hit.origin as Vector2).y

	return local_y < rect.position.y + rect.size.y * 0.5


func _set_drop_hint(card: HenStateViewerCard, kind: StringName, ref: Variant, before: bool) -> void:
	if is_instance_valid(_drop_card) and _drop_card != card:
		_drop_card.set_drop_hint(&'', null, false)

	_drop_card = card

	if card:
		card.set_drop_hint(kind, ref, before)


func _clear_drop_hint() -> void:
	if is_instance_valid(_drop_card):
		_drop_card.set_drop_hint(&'', null, false)

	_drop_card = null


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		_clear_drop_hint()
		_drag_node = null


# the drawn rows are not controls, so the cam cannot tell a row press from the
# empty canvas by hit-testing the control tree
func blocks_pan() -> bool:
	return not _hit_under_mouse().is_empty()


# routes a click by the innermost thing under it; false lets the state open
func _dispatch_card_click() -> bool:
	var hit: Dictionary = _hit_under_mouse()

	if hit.is_empty():
		return false

	var card: HenStateViewerCard = hit.card
	var rect: Rect2 = _screen_rect(Rect2(hit.origin + (hit.rect as Rect2).position, (hit.rect as Rect2).size))

	_editing_card = card
	_editor_for(hit.node)

	match StringName(str(hit.kind)):
		&'chip':
			_editor.chip_pressed(hit.part, int(hit.index), rect, _chip_ring.bind(card, hit.origin))
		&'capsule':
			_editor.edit_action(hit.action, rect, true)
		&'row':
			_editor.edit_action(hit.action, rect, false)
		&'phase_add':
			_editor.open_search(hit.phase, null, null, rect)
		&'list_add':
			_editor.open_search(&'', null, null, rect)
		&'loop_add':
			_editor.open_search(&'', null, hit.loop, rect)

	return true


func _editor_for(node: HenStateViewerGraphTypes.DirectedGraphNode) -> void:
	if _editor == null:
		_editor = HenStateViewerCardEditor.new()
		_editor.changed.connect(_on_editor_changed)
		_editor.focus_requested.connect(_focus_script)

	_editor.target(_save_data_for(node), StringName(str(node.data.get('state_id', ''))))


func _on_editor_changed() -> void:
	_refresh_edited_card()


# a value edit usually leaves the card the same size, and then nothing outside it
# moved: relaying the whole collection out would be the expensive way to do nothing
func _refresh_edited_card() -> void:
	if not is_instance_valid(_editing_card):
		_on_actions_structure_changed()
		return

	var before: Vector2 = _editing_card.get_intrinsic_size()

	_editing_card.refresh_content()

	if _editing_card.get_intrinsic_size().is_equal_approx(before):
		return

	_on_actions_structure_changed()


func _focus_script(save_data: HenSaveData) -> void:
	if save_data:
		(Engine.get_singleton(&'Loader') as HenLoader).set_active_script(save_data)


# a hit rect lives in the container's space; popups position in viewport space
func _screen_rect(local_rect: Rect2) -> Rect2:
	var xform: Transform2D = nodes_container.get_global_transform()

	return Rect2(xform * local_rect.position, local_rect.size * xform.get_scale())


# every text-editable chip of the card, in reading order: the tab order. the card
# is re-emitted first because a committed value resizes the line it sits on
func _chip_ring(card: HenStateViewerCard, origin: Vector2) -> Array:
	var ring: Array = []

	if not is_instance_valid(card):
		return ring

	card.refresh_content()

	for hit: Dictionary in card.get_hits():
		if hit.kind != &'chip' or not bool((hit.part as Dictionary).get('editable', false)):
			continue

		ring.append({
			part = hit.part,
			index = hit.index,
			rect = _screen_rect(Rect2(origin + (hit.rect as Rect2).position, (hit.rect as Rect2).size))
		})

	return ring


func _on_graph_changed_no_args(_a = null, _b = null) -> void:
	_request_rebuild()


# a rebuild frees every card, so it waits instead of pulling a popup anchor away
func _request_rebuild() -> void:
	var general_popup: HenGeneralPopup = Engine.get_singleton(&'GeneralPopup')

	if general_popup and general_popup.has_open_popups():
		_rebuild_pending = true
		return

	_update_graph()


func _update_graph() -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	if not global:
		return

	var scripts: Array = global.OPEN_SCRIPTS

	if _only_current_script:
		scripts = [global.SAVE_DATA] if global.SAVE_DATA else []

	var dict: Dictionary = _build_collection_dict(scripts)
	# states, names and transitions all live in this dict, so an equal hash means
	# only action contents moved: re-measuring covers it without respawning a card
	var signature: int = dict.hash()

	if graph_root != null and signature == _structure_hash:
		_measure_and_layout()
		return

	_structure_hash = signature

	build_graph(dict)


# switches between the whole collection and the active script only
func set_only_current_script(_value: bool) -> void:
	if _only_current_script == _value:
		return

	_only_current_script = _value
	_update_graph()


func is_only_current_script() -> bool:
	return _only_current_script


# full rebuild for the toolbar button: the incremental paths keep the parsed graph
func refresh_graph() -> void:
	_structure_hash = 0
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
		_request_rebuild()

func _build_dynamic_dict(save_data: HenSaveData) -> Dictionary:
	var root_dict: Dictionary = {
		id = save_data.identity.name if save_data.identity else 'root',
		states = {},
		script_type = String(save_data.identity.type) if save_data.identity else ''
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
					var custom_name: String = str(vc.name_to_code) if vc.name_to_code else ''
					var event_name: String = custom_name if not custom_name.is_empty() else 'go_to_' + target_res.name

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
						icon = TRANSITION_ICON,
						auto_label = custom_name.is_empty()
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
			on_meta[event_name] = _branch_meta(macro, script_id, label.is_empty())


# a branch reads as cross-script first, then conditional when the macro forks. the
# icon stays the macro's own so the action type is still recognizable on the line
func _branch_meta(macro: HenSaveMacro, script_id: StringName, auto_label: bool) -> Dictionary:
	var kind: StringName = &'transition'

	if not script_id.is_empty():
		kind = &'cross_script'
	elif macro and macro.flow_outputs.size() > 1:
		kind = &'condition'

	var icon: String = macro.icon if macro and not macro.icon.is_empty() else TRANSITION_ICON
	var color: String = macro.color if macro else ''

	return {kind = kind, icon = icon, color = color, auto_label = auto_label}


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
		(_panels[node] as HenStateViewerCard).set_highlight(_highlight_of(node, current_state_id))


# the running state wins over the one being edited
func _highlight_of(node: HenStateViewerGraphTypes.DirectedGraphNode, current_state_id: String) -> StringName:
	var node_id: String = node.id
	var slices: int = node_id.get_slice_count('.')
	# node.id is "collection.<script_name>.<state>..."; segment 1 scopes the script
	var script_seg: String = node_id.get_slice('.', 1) if slices > 1 else ''
	var short_id: String = node_id.get_slice('.', slices - 1)

	if _debug_active_states.get(script_seg, '') == short_id.strip_edges().to_snake_case():
		return &'running'

	if not current_state_id.is_empty() and String(node.data.get('state_id', '')) == current_state_id:
		return &'current'

	return &''


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


func _cam() -> HenCam:
	if not is_instance_valid(_cam_node):
		_cam_node = get_node_or_null('%Cam') as HenCam

	return _cam_node


func _current_zoom() -> float:
	var cam: HenCam = _cam()

	return maxf(cam.transform.x.x, 0.001) if cam else 1.0


func _update_zoom_scales() -> void:
	var zoom: float = _current_zoom()

	if is_equal_approx(zoom, _zoom):
		return

	_zoom = zoom
	_update_detail_level(zoom)


# holds the compact name at MIN_TITLE_SCREEN_PX once the cam shrinks it past that
func _title_factor(zoom: float) -> float:
	return maxf(1.0, MIN_TITLE_SCREEN_PX / (TITLE_FONT_SIZE * ThemeUtils.get_font_scale() * zoom))


func _update_detail_level(zoom: float) -> void:
	var rows_at: float = ProjectSettings.get_setting(HenSettings.STATE_ROWS_ZOOM_PATH, 0.25)
	var name_at: float = minf(ProjectSettings.get_setting(HenSettings.STATE_NAME_ZOOM_PATH, 0.15), rows_at)
	var lines_at: float = ProjectSettings.get_setting(HenSettings.STATE_LINES_ZOOM_PATH, 0.15)
	var level: int = _detail_level

	# stepping down uses the threshold, stepping back up needs the extra margin
	match _detail_level:
		HenStateViewerCard.Detail.FULL:
			if zoom < name_at:
				level = HenStateViewerCard.Detail.NAME
			elif zoom < rows_at:
				level = HenStateViewerCard.Detail.COMPACT
		HenStateViewerCard.Detail.COMPACT:
			if zoom < name_at:
				level = HenStateViewerCard.Detail.NAME
			elif zoom > rows_at * COMPACT_HYSTERESIS:
				level = HenStateViewerCard.Detail.FULL
		_:
			if zoom > rows_at * COMPACT_HYSTERESIS:
				level = HenStateViewerCard.Detail.FULL
			elif zoom > name_at * COMPACT_HYSTERESIS:
				level = HenStateViewerCard.Detail.COMPACT

	if _lines_hidden:
		if zoom > lines_at * COMPACT_HYSTERESIS:
			_lines_hidden = false
	elif zoom < lines_at:
		_lines_hidden = true

	edges_overlay.set_lines_hidden(_lines_hidden)

	var factor: float = _title_factor(zoom)
	var changed: bool = level != _detail_level

	_detail_level = level

	if changed:
		# the overlay only cares whether the pills are still readable
		edges_overlay.set_detail(
			HenStateViewerEdgesOverlay.Detail.FULL if level == HenStateViewerCard.Detail.FULL
			else HenStateViewerEdgesOverlay.Detail.COMPACT
		)

	for panel: Variant in _panels.values():
		if not panel is HenStateViewerCard:
			continue

		var card: HenStateViewerCard = panel

		if changed:
			card.set_detail(level)

		# a transform, so holding the name readable never reshapes its text
		card.set_title_scale(factor)


# what the cam currently shows, in the container's space
func _view_rect() -> Rect2:
	var cam: HenCam = _cam()

	if not cam:
		return Rect2(Vector2(-1e9, -1e9), Vector2(2e9, 2e9))

	return cam.get_rect().grow(CULL_MARGIN)


# cards enter and leave the view as the cam moves, and only then
func _update_culling() -> void:
	var cam: HenCam = _cam()

	if not cam:
		return

	var origin: Vector2 = cam.transform.origin
	var zoom: float = cam.transform.x.x

	if origin.is_equal_approx(_last_cull_origin) and is_equal_approx(zoom, _last_cull_zoom):
		return

	_last_cull_origin = origin
	_last_cull_zoom = zoom

	var view: Rect2 = _view_rect()

	for i: int in range(_hover_nodes.size()):
		var panel: Variant = _panels.get(_hover_nodes[i])

		if panel is HenStateViewerCard:
			(panel as HenStateViewerCard).set_culled(not view.intersects(_hover_rects[i]))


func _process(_delta: float) -> void:
	_update_zoom_scales()
	_update_culling()

	if not _flashes.is_empty():
		_expire_flashes()

	var mouse_pos: Vector2 = nodes_container.get_local_mouse_position()
	var hovered_edge: HenStateViewerGraphTypes.DirectedGraphEdge = edges_overlay.get_hovered_edge()

	if mouse_pos != _last_hover_pos or hovered_edge != _last_hover_edge:
		_last_hover_pos = mouse_pos
		_last_hover_edge = hovered_edge
		_update_hover(mouse_pos, hovered_edge)

	_update_cursor()


func _update_hover(mouse_pos: Vector2, hovered_edge: HenStateViewerGraphTypes.DirectedGraphEdge) -> void:
	var index: int = -1 if hovered_edge != null else _node_index_at(mouse_pos)
	var hovered_node: HenStateViewerGraphTypes.DirectedGraphNode = _hover_nodes[index] if index >= 0 else null

	_apply_card_hover(_hit_in_card(index, mouse_pos))

	var active_node_changed: bool = false
	if _active_node != hovered_node:
		_set_active_node(hovered_node)
		active_node_changed = true

	if hovered_node == null:
		if _active_edge != hovered_edge or active_node_changed:
			_active_edge = hovered_edge
			_set_active_edge(hovered_edge)
	else:
		_active_edge = null


# the cache is ordered parents -> children, so walking back hits the deepest first
func _node_index_at(pos: Vector2) -> int:
	for i: int in range(_hover_rects.size() - 1, -1, -1):
		if _hover_rects[i].has_point(pos):
			return i

	return -1


# chips and capsules are emitted before the row holding them, so the first rect
# that contains the point is always the innermost one
func _hit_in_card(index: int, pos: Vector2) -> Dictionary:
	if index < 0:
		return {}

	var card: Variant = _panels.get(_hover_nodes[index])

	if not card is HenStateViewerCard or not (card as HenStateViewerCard).visible:
		return {}

	var origin: Vector2 = _hover_rects[index].position
	var local: Vector2 = pos - origin

	for hit: Dictionary in (card as HenStateViewerCard).get_hits():
		if (hit.rect as Rect2).has_point(local):
			var out: Dictionary = hit.duplicate()
			out.card = card
			out.node = _hover_nodes[index]
			out.origin = origin
			return out

	return {}


func _apply_card_hover(hit: Dictionary) -> void:
	var card: HenStateViewerCard = hit.get('card')
	var kind: StringName = &''
	var ref: Variant = null

	match StringName(str(hit.get('kind', ''))):
		&'row':
			kind = &'row'
			ref = hit.action
		&'chip':
			kind = &'chip'
			ref = hit.index

	if is_instance_valid(_hovered_card) and _hovered_card != card:
		_hovered_card.set_hover(&'', null)

	_hovered_card = card

	if card:
		card.set_hover(kind, ref)

	_update_row_tooltip(hit, kind)


# the doc is only built when a row is actually hovered, never while the card draws
func _update_row_tooltip(hit: Dictionary, kind: StringName) -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')

	if not global or not global.TOOLTIP:
		return

	if kind != &'row':
		if not _tooltip_action.is_empty():
			_tooltip_action = ''
			global.TOOLTIP.close()
		return

	var action: HenSaveAction = hit.action

	if _tooltip_action == str(action.id):
		return

	_tooltip_action = str(action.id)

	var owner: HenSaveData = _save_data_for(hit.node)
	var doc: String = HenActionDoc.bbcode(HenActionsPanel.find_macro(action.macro_id))
	var values: String = HenActionsPanel.value_preview(action, owner)
	var content: String = doc

	if not values.is_empty():
		content += ('\n\n' if not doc.is_empty() else '') + '[color=#5f6a7a]Current: ' + values + '[/color]'

	if not content.is_empty():
		global.TOOLTIP.go_to(get_global_mouse_position(), content)


# absolute positions are recursive, so they are resolved once per layout
func _rebuild_hover_cache() -> void:
	_hover_nodes.clear()
	_hover_rects.clear()
	_last_hover_pos = Vector2.INF
	_last_cull_origin = Vector2.INF

	if graph_root == null:
		return

	var all_nodes: Array[HenStateViewerGraphTypes.DirectedGraphNode] = []
	_collect_draw_order(graph_root, all_nodes)

	for node: HenStateViewerGraphTypes.DirectedGraphNode in all_nodes:
		if node == graph_root:
			continue

		_hover_nodes.append(node)
		_hover_rects.append(Rect2(node.get_absolute(), Vector2(node.layout.width, node.layout.height)))


# panels ignore the mouse, so the cursor hint lives on the graph itself
func _update_cursor() -> void:
	var cam: HenCam = _cam()
	var shape: CursorShape = Control.CURSOR_ARROW

	if cam and cam.is_panning():
		shape = Control.CURSOR_DRAG
	elif _is_state_node(_active_node):
		shape = Control.CURSOR_POINTING_HAND

	if mouse_default_cursor_shape != shape:
		mouse_default_cursor_shape = shape


# orchestrates: parse -> build ui -> measure -> layout -> render
func build_graph(dict: Dictionary) -> void:
	for child in nodes_container.get_children():
		child.queue_free()

	_flashes.clear()
	_hovered_card = null
	_editing_card = null
	_drop_card = null
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
			_spawn_card(node)

	_measure_and_layout()
	# the containers have not sorted yet, so the first measure reads stale sizes


func _measure_and_layout() -> void:
	if graph_root == null:
		return

	measurer.calculate_rects(graph_root, ThemeDB.fallback_font, 14, true, _panels)
	layout.execute_layout(graph_root)

	var view: Rect2 = _view_rect()
	var factor: float = _title_factor(_current_zoom())

	for node: HenStateViewerGraphTypes.DirectedGraphNode in _panels:
		var card: HenStateViewerCard = _panels[node]
		var rect: Rect2 = Rect2(node.get_absolute(), Vector2(node.layout.width, node.layout.height))

		card.position = rect.position
		# culled before the size lands, so an offscreen card never builds a list
		card.set_culled(not view.intersects(rect))
		card.set_title_scale(factor)
		card.set_detail(_detail_level)
		card.apply_size(rect.size)

	edges_overlay.update_edges(graph_root)
	_update_node_styles()
	_rebuild_hover_cache()


# an action changed shape, so the card it lives in resized and everything around
# it has to move
func _on_actions_structure_changed() -> void:
	_measure_and_layout()


# depth-first to get breadth-first draw order (parents before children)
func _collect_draw_order(node: HenStateViewerGraphTypes.DirectedGraphNode, arr: Array[HenStateViewerGraphTypes.DirectedGraphNode]) -> void:
	arr.append(node)
	for child in node.children:
		_collect_draw_order(child, arr)


func _spawn_card(node: HenStateViewerGraphTypes.DirectedGraphNode) -> void:
	var card: HenStateViewerCard = HenStateViewerCard.new()
	var short_id: String = node.id.get_slice('.', node.id.get_slice_count('.') - 1)
	var is_initial: bool = node.parent != null and node.parent.data.get('initial', '') == short_id

	nodes_container.add_child(card)
	card.setup(self, _save_data_for(node), node.data, short_id, not node.children.is_empty(), is_initial)

	_panels[node] = card



func _save_data_for(node: HenStateViewerGraphTypes.DirectedGraphNode) -> HenSaveData:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var script_id: String = String(node.data.get('script_id', ''))

	if not global:
		return null

	for save_data: HenSaveData in global.OPEN_SCRIPTS:
		if save_data and save_data.identity and String(save_data.identity.id) == script_id:
			return save_data

	return null

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
		var p: CanvasItem = _panels[n]
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
		var p: CanvasItem = _panels[n]
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
