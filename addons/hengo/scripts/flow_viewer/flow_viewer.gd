@tool
class_name HenFlowViewer extends Control

# one script at a time, drawn as node graphs inside state frames. the frames, the
# grid they sit on and the transitions between them are the state viewer's layer,
# reused as is: a frame is just a leaf whose size comes from its inner graph

@onready var nodes_container: Node2D = %FlowNodes
@onready var edges_overlay: HenStateViewerEdgesOverlay = %FlowEdges

const LINES_HYSTERESIS: float = 1.15
const DETAIL_HYSTERESIS: float = 1.25
const TITLE_FONT_SIZE: int = HenFlowNodeCard.TITLE_SIZE
const MIN_TITLE_SCREEN_PX: float = 11.0
# a frame the hovered route does not touch steps back, the way the other routes do
const FRAME_DIM: float = 0.28
const CLICK_TOLERANCE: float = 6.0
const CULL_MARGIN: float = 256.0
const DOUBLE_CLICK_MS: int = 400
# HengoDebugger throttles a trace to one per 120ms per action, on purpose: an
# update action fires every frame. a shorter fade would strobe instead of glow
const RUN_TIME_MS: int = 200

var parser: HenStateViewerDataParser = HenStateViewerDataParser.new()
var measurer: HenStateViewerUIMeasurer = HenStateViewerUIMeasurer.new()
var layout: HenStateViewerLayoutEngine = HenStateViewerLayoutEngine.new()

var graph_root: HenStateViewerGraphTypes.DirectedGraphNode

# state id -> {graph, frame, cards, wires}
var _states: Dictionary = {}
var _frames: Dictionary = {}
var _rebuild_pending: bool = false
var _cam_node: HenCam
var _zoom: float = 0.0
var _lines_hidden: bool = false
var _detail: int = HenFlowNodeCard.Detail.FULL
var _hovered_edge: HenStateViewerGraphTypes.DirectedGraphEdge = null

# world rects of everything the mouse can reach, widest first: the last box that
# contains a point is the innermost one, which is what a hit means
var _hover_items: Array[Dictionary] = []
var _hovered_card: HenFlowNodeCard = null
var _hover_kind: StringName = &''
var _last_hover_pos: Vector2 = Vector2.INF
var _tooltip_action: String = ''
var _editor: HenStateViewerCardEditor = null
var _editing_card: HenFlowNodeCard = null
var _click_press_pos: Vector2 = Vector2.ZERO
var _context_press_pos: Vector2 = Vector2.ZERO
# action id, not the card: a rebuild frees every card, and the selection has to
# come back on the node the user picked
var _selected_action: String = ''
var _click_last_time: int = 0
var _click_last_pos: Vector2 = Vector2.ZERO
var _last_cull_origin: Vector2 = Vector2.INF
var _last_cull_zoom: float = -1.0

# action id -> expiry msec. keyed by action and not by card because a rebuild
# frees every card, and a flash tied to one would die with it
var _flashes: Dictionary = {}
# action id -> HenFlowNodeCard, resolved once per layout
var _cards_by_action: Dictionary = {}
# action id -> the state that owns it, which is the unit the history snapshots
var _state_by_action: Dictionary = {}
var _running_state: String = ''
var _history: HenFlowHistory = HenFlowHistory.new()
var _history_script: String = ''


func _ready() -> void:
	if HenUtils.disable_scene_with_owner(self ):
		return

	# EditorInterface only exists in the editor, and this scene also runs headless
	if Engine.is_editor_hint() and EditorInterface.get_edited_scene_root() is HenHengoRoot:
		return

	var signal_bus: HenSignalBus = Engine.get_singleton(&'SignalBus')

	if signal_bus:
		for signal_name: StringName in [&'request_list_update', &'request_structural_update', &'scripts_generation_finished']:
			if not signal_bus.get(signal_name).is_connected(_on_changed):
				signal_bus.get(signal_name).connect(_on_changed)

		for pair: Array in [
			[&'debug_state_changed', _on_debug_state_changed],
			[&'debug_action_flow', _on_debug_action_flow],
			[&'debug_state_transition', _on_debug_state_transition],
			[&'debug_session_stopped', _on_debug_session_stopped]
		]:
			if not signal_bus.get(pair[0]).is_connected(pair[1]):
				signal_bus.get(pair[0]).connect(pair[1])

	var general_popup: HenGeneralPopup = Engine.get_singleton(&'GeneralPopup')

	if general_popup and not general_popup.closed.is_connected(_on_popup_closed):
		general_popup.closed.connect(_on_popup_closed)

	rebuild()


func _on_changed(_a = null, _b = null) -> void:
	_request_rebuild()


# a rebuild frees every card, so it waits instead of pulling a popup anchor away
func _request_rebuild() -> void:
	var general_popup: HenGeneralPopup = Engine.get_singleton(&'GeneralPopup')

	if general_popup and general_popup.has_open_popups():
		_rebuild_pending = true
		return

	rebuild()


# an inner picker closing is not the edit ending, so it waits for the whole stack
func _on_popup_closed() -> void:
	var general_popup: HenGeneralPopup = Engine.get_singleton(&'GeneralPopup')

	if general_popup and general_popup.has_open_popups():
		return

	var global: HenGlobal = Engine.get_singleton(&'Global') if Engine.has_singleton(&'Global') else null

	_history.commit(global.SAVE_DATA if global else null, 'Edit Action')

	if _rebuild_pending:
		_rebuild_pending = false
		rebuild()
		return

	if _editor and _editor.is_editing:
		_editor.is_editing = false
		_refresh_edited_card()


# the states tab hides this one, and nothing here is worth a frame while it is
func _notification(what: int) -> void:
	if what != NOTIFICATION_VISIBILITY_CHANGED:
		return

	var showing: bool = is_visible_in_tree()

	set_process(showing)
	set_process_unhandled_key_input(showing)

	if not showing:
		_release_hover()
		_clear_flashes()


func _release_hover() -> void:
	_last_hover_pos = Vector2.INF
	_hover_kind = &''

	if is_instance_valid(_hovered_card):
		_hovered_card.set_hover(&'', null)
		_hovered_card = null

	_close_tooltip()

	if _hovered_edge != null:
		_hovered_edge = null

		for node: HenStateViewerGraphTypes.DirectedGraphNode in _frames:
			(_frames[node] as HenFlowStateFrame).modulate.a = 1.0


func _cam() -> HenCam:
	if not is_instance_valid(_cam_node):
		_cam_node = get_node_or_null('%Cam') as HenCam

	return _cam_node


func _process(_delta: float) -> void:
	var cam: HenCam = _cam()

	if not cam:
		return

	var mouse: Vector2 = nodes_container.get_local_mouse_position()

	if mouse != _last_hover_pos or edges_overlay.get_hovered_edge() != _hovered_edge:
		_last_hover_pos = mouse
		_update_hover(mouse)

	_update_cursor(cam)
	_update_culling(cam)

	if not _flashes.is_empty():
		_expire_flashes()

	var zoom: float = maxf(cam.transform.x.x, 0.001)

	if is_equal_approx(zoom, _zoom):
		return

	_zoom = zoom

	var lines_at: float = ProjectSettings.get_setting(HenSettings.STATE_LINES_ZOOM_PATH, 0.15)

	if _lines_hidden:
		if zoom > lines_at * LINES_HYSTERESIS:
			_lines_hidden = false
	elif zoom < lines_at:
		_lines_hidden = true

	for entry: Variant in _states.values():
		if not entry.has('wires'):
			continue

		var wires: HenFlowWires = entry.wires
		wires.visible = not _lines_hidden
		wires.set_screen_scale(1.0 / zoom)

	_update_detail(zoom)


# far enough out a node is only its badge and its name, and the name is held at a
# readable size by a transform instead of a redraw
func _update_detail(_zoom: float) -> void:
	var rows_at: float = ProjectSettings.get_setting(HenSettings.STATE_ROWS_ZOOM_PATH, 0.25)
	var level: int = _detail

	if _detail == HenFlowNodeCard.Detail.FULL:
		if _zoom < rows_at:
			level = HenFlowNodeCard.Detail.COMPACT
	elif _zoom > rows_at * DETAIL_HYSTERESIS:
		level = HenFlowNodeCard.Detail.FULL

	var changed: bool = level != _detail
	var factor: float = maxf(1.0, MIN_TITLE_SCREEN_PX / (TITLE_FONT_SIZE * ThemeUtils.get_font_scale() * _zoom))

	_detail = level

	for entry: Variant in _states.values():
		for card: HenFlowNodeCard in entry.cards:
			if changed:
				card.set_detail(level)

			card.set_title_scale(factor)


# cards enter and leave the view as the cam moves, and only then. the hit map
# already holds every world rect, so culling is a walk over it
func _update_culling(_cam: HenCam) -> void:
	var origin: Vector2 = _cam.transform.origin
	var zoom: float = _cam.transform.x.x

	if origin.is_equal_approx(_last_cull_origin) and is_equal_approx(zoom, _last_cull_zoom):
		return

	_last_cull_origin = origin
	_last_cull_zoom = zoom

	var view: Rect2 = _cam.get_rect().grow(CULL_MARGIN)

	for item: Dictionary in _hover_items:
		if item.kind != &'card':
			continue

		(item.card as HenFlowNodeCard).set_culled(not view.intersects(item.rect))


func _update_hover(_pos: Vector2) -> void:
	var hit: Dictionary = hit_at(_pos)

	_hover_kind = StringName(str(hit.get('kind', &'')))

	_apply_card_hover(hit)
	_update_tooltip(hit)

	# a card is a solid object and a route is a two pixel line, so whatever the
	# mouse is actually inside wins
	_update_focus(null if not hit.is_empty() else edges_overlay.get_hovered_edge())


func _apply_card_hover(_hit: Dictionary) -> void:
	var card: HenFlowNodeCard = _hit.get('card', null)

	if is_instance_valid(_hovered_card) and _hovered_card != card:
		_hovered_card.set_hover(&'', null)

	_hovered_card = card

	if card:
		card.set_hover(StringName(str(_hit.kind)), _hit.get('pin', null))


# hovering a route is a question about two states, so the rest steps back
func _update_focus(_hovered: HenStateViewerGraphTypes.DirectedGraphEdge) -> void:
	if _hovered == _hovered_edge:
		return

	_hovered_edge = _hovered

	for node: HenStateViewerGraphTypes.DirectedGraphNode in _frames:
		var lit: bool = _hovered == null or node == _hovered.source or node == _hovered.target

		(_frames[node] as HenFlowStateFrame).modulate.a = 1.0 if lit else FRAME_DIM


# the doc is only built while a card is actually hovered, never while one draws
func _update_tooltip(_hit: Dictionary) -> void:
	var card: HenFlowNodeCard = _hit.get('card', null)
	var action: HenSaveAction = card.node.action if card else null

	if not action:
		_close_tooltip()
		return

	if _tooltip_action == str(action.id):
		return

	_tooltip_action = str(action.id)

	var global: HenGlobal = Engine.get_singleton(&'Global') if Engine.has_singleton(&'Global') else null

	if not global or not global.TOOLTIP:
		return

	var doc: String = HenActionDoc.bbcode(HenActionsPanel.find_macro(action.macro_id))
	var values: String = HenActionsPanel.value_preview(action, global.SAVE_DATA)
	var content: String = doc

	if not values.is_empty():
		content += ('\n\n' if not doc.is_empty() else '') + '[color=#5f6a7a]Current: ' + values + '[/color]'

	if not content.is_empty():
		global.TOOLTIP.go_to(get_global_mouse_position(), content)


func _close_tooltip() -> void:
	if _tooltip_action.is_empty():
		return

	_tooltip_action = ''

	if not Engine.has_singleton(&'Global'):
		return

	var global: HenGlobal = Engine.get_singleton(&'Global')

	if global and global.TOOLTIP:
		global.TOOLTIP.close()


# the cards are drawn, not controls, so the cursor hint lives on the viewer
func _update_cursor(_cam: HenCam) -> void:
	var shape: CursorShape = Control.CURSOR_ARROW

	if _cam.is_panning():
		shape = Control.CURSOR_DRAG
	elif not _hover_kind.is_empty():
		shape = Control.CURSOR_POINTING_HAND

	if mouse_default_cursor_shape != shape:
		mouse_default_cursor_shape = shape


func rebuild() -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')

	if not global or not global.SAVE_DATA:
		_clear()
		return

	var save_data: HenSaveData = global.SAVE_DATA
	var script_id: String = String(save_data.identity.id) if save_data.identity else ''

	# an entry restores a list into the script it was taken from, so it means
	# nothing once another script is on screen
	if script_id != _history_script:
		_history_script = script_id
		_history.clear()

	_clear()
	_build_states(save_data)
	_build_outer(save_data)


func _clear() -> void:
	for child: Node in nodes_container.get_children():
		child.queue_free()

	_states.clear()
	_frames.clear()
	_hover_items.clear()
	_cards_by_action.clear()
	_state_by_action.clear()
	_flashes.clear()
	_last_cull_origin = Vector2.INF
	_hovered_card = null
	_editing_card = null
	graph_root = null
	# forces the next frame to push the wire scale into the wires built meanwhile
	_zoom = 0.0


# pass one: every state's own graph, measured and laid out in its own space
func _build_states(_save_data: HenSaveData) -> void:
	for state: HenSaveState in _all_states(_save_data):
		var graph: HenFlowGraphTypes.FlowGraph = HenFlowGraphBuilder.build(_save_data, state)
		var cards: Array[HenFlowNodeCard] = []

		for node: HenFlowGraphTypes.FlowNode in graph.nodes:
			var card: HenFlowNodeCard = HenFlowNodeCard.new()

			nodes_container.add_child(card)
			card.setup(self , node)
			card.compute_size()
			cards.append(card)

		var box: Rect2 = HenFlowFormatter.format(graph)

		# the formatter works around the entry, so the graph is pulled back to zero
		graph.translate(-box.position)

		_states[String(state.id)] = {
			graph = graph,
			cards = cards,
			size = box.size,
			state = state
		}


# a sub state is a state with its own actions, and it lives in its own dictionary
# instead of carrying the flag: skipping it left its parent framing nothing at all
func _all_states(_save_data: HenSaveData) -> Array[HenSaveState]:
	var out: Array[HenSaveState] = []

	for state: HenSaveState in _save_data.states:
		out.append(state)

	for key: Variant in _save_data.sub_states:
		for state: HenSaveState in _save_data.sub_states[key]:
			if not out.has(state):
				out.append(state)

	return out


# pass two: the frames on the state grid, which is the state viewer's own engine
func _build_outer(_save_data: HenSaveData) -> void:
	var dict: Dictionary = {
		id = 'collection',
		states = {_save_data.identity.name: HenStateGraphSource.script_dict(_save_data)}
	}

	graph_root = parser.parse_machine(dict)

	for machine: HenStateViewerGraphTypes.DirectedGraphNode in graph_root.children:
		parser._resolve_node_edges(machine, machine, graph_root)

	var nodes: Array[HenStateViewerGraphTypes.DirectedGraphNode] = []

	_collect_states(graph_root, nodes)

	for node: HenStateViewerGraphTypes.DirectedGraphNode in nodes:
		_spawn_frame(node)

	measurer.calculate_rects(graph_root, ThemeDB.fallback_font, 14, true, _frames)
	layout.execute_layout(graph_root)

	for node: HenStateViewerGraphTypes.DirectedGraphNode in _frames:
		_place_frame(node)

	_paint_edges(graph_root)
	edges_overlay.update_edges(graph_root)
	_rebuild_hover_cache()
	_apply_running_state()
	_apply_selection()


# every state, not only the childless ones: a state that owns sub states is still
# a state with its own graph. parents come first so a sub frame draws over its own
# parent instead of under it
func _collect_states(_node: HenStateViewerGraphTypes.DirectedGraphNode, _out: Array) -> void:
	if _node.data.has('state_id'):
		_out.append(_node)

	for child: HenStateViewerGraphTypes.DirectedGraphNode in _node.children:
		_collect_states(child, _out)


func _spawn_frame(_node: HenStateViewerGraphTypes.DirectedGraphNode) -> void:
	var entry: Variant = _states.get(String(_node.data.get('state_id', '')))

	if not entry:
		return

	var state: HenSaveState = entry.state
	var frame: HenFlowStateFrame = HenFlowStateFrame.new()

	nodes_container.add_child(frame)
	frame.setup(self , state.name, state.description, (entry.graph as HenFlowGraphTypes.FlowGraph).nodes.size(), _accent_for(state))
	frame.set_content_size(entry.size)

	_frames[_node] = frame
	entry.frame = frame


# the cards and the wires ride inside the frame, so the graph moves with it
func _place_frame(_node: HenStateViewerGraphTypes.DirectedGraphNode) -> void:
	var frame: HenFlowStateFrame = _frames[_node]
	var entry: Dictionary = _states[String(_node.data.get('state_id', ''))]

	frame.position = _node.get_absolute()
	frame.apply_size(Vector2(_node.layout.width, _node.layout.height))

	var origin: Vector2 = frame.content_origin()

	for card: HenFlowNodeCard in entry.cards:
		card.reparent(frame)
		card.position = origin + card.node.position
		card.apply_size(card.node.size)

	var wires: HenFlowWires = HenFlowWires.new()

	frame.add_child(wires)
	# behind the cards, so a wire passes under the box it runs into
	frame.move_child(wires, 0)
	wires.position = origin
	wires.build(entry.graph)

	entry.wires = wires


func _accent_for(_state: HenSaveState) -> Color:
	return HenActionVisuals.state_color(str(_state.id))


# --- debug ---

# the runtime reports the key of the generated state dictionary, which is the
# state name in snake_case. comparing against the editor name never matches and
# never errors: it just silently does nothing
func _on_debug_state_changed(_state_name: StringName, _script_id: String) -> void:
	if not _is_active_script(_script_id) and not String(_state_name).is_empty():
		return

	_running_state = String(_state_name)
	_apply_running_state()


func _apply_running_state() -> void:
	for entry: Variant in _states.values():
		if not entry.has('frame'):
			continue

		var state: HenSaveState = entry.state
		var running: bool = not _running_state.is_empty() \
			and state.name.strip_edges().to_snake_case() == _running_state

		(entry.frame as HenFlowStateFrame).set_running(running)


func _on_debug_action_flow(_action_id: StringName, _script_id: String) -> void:
	if not _is_active_script(_script_id):
		return

	var card: Variant = _cards_by_action.get(String(_action_id))

	if not card:
		return

	# an update action re-arms every frame, so the expiry is pushed forward
	# instead of the card being re-emitted again
	_flashes[String(_action_id)] = Time.get_ticks_msec() + RUN_TIME_MS

	(card as HenFlowNodeCard).set_running(true)


func _on_debug_state_transition(_source: String, _event: String, _script_id: String) -> void:
	if not _is_active_script(_script_id):
		return

	edges_overlay.flash_edge(_script_name(), _source, _event)


func _on_debug_session_stopped() -> void:
	_clear_flashes()

	_running_state = ''
	_apply_running_state()


func _clear_flashes() -> void:
	for id: Variant in _flashes:
		var card: Variant = _cards_by_action.get(id)

		if card and is_instance_valid(card):
			(card as HenFlowNodeCard).set_running(false)

	_flashes.clear()


func _expire_flashes() -> void:
	var now: int = Time.get_ticks_msec()

	for id: Variant in _flashes.keys():
		if int(_flashes[id]) > now:
			continue

		_flashes.erase(id)

		var card: Variant = _cards_by_action.get(id)

		if card and is_instance_valid(card):
			(card as HenFlowNodeCard).set_running(false)


# the flow shows one script, so anything reported for another one is not ours
func _is_active_script(_script_id: String) -> bool:
	if _script_id.is_empty():
		return true

	var global: HenGlobal = Engine.get_singleton(&'Global') if Engine.has_singleton(&'Global') else null

	return global != null and global.SAVE_DATA != null \
		and String(global.SAVE_DATA.identity.id) == _script_id


func _script_name() -> String:
	var global: HenGlobal = Engine.get_singleton(&'Global') if Engine.has_singleton(&'Global') else null

	return global.SAVE_DATA.identity.name if global and global.SAVE_DATA else ''


# --- hit map ---

# a card rect is local to the card, the card is local to its frame and the frame
# is world, so a hit crosses two offsets before it means anything to the mouse
func _rebuild_hover_cache() -> void:
	_hover_items.clear()
	_cards_by_action.clear()
	_state_by_action.clear()

	for node: HenStateViewerGraphTypes.DirectedGraphNode in _frames:
		var frame: HenFlowStateFrame = _frames[node]
		var entry: Variant = _states.get(String(node.data.get('state_id', '')))

		if not entry:
			continue

		_hover_items.append({
			kind = &'frame',
			rect = Rect2(frame.position + frame.header_rect().position, frame.header_rect().size),
			frame = frame,
			node = node,
			state = entry.state
		})

		for card: HenFlowNodeCard in entry.cards:
			_hover_items.append({
				kind = &'card',
				rect = Rect2(frame.position + card.position, card.node.size),
				frame = frame,
				node = node,
				state = entry.state,
				card = card
			})

			if card.node.action:
				_cards_by_action[str(card.node.action.id)] = card
				_state_by_action[str(card.node.action.id)] = (entry.state as HenSaveState).id

	# a loop card is grown to hold its body, so the body cards are strictly smaller
	# and sorting by area is what orders container before content
	_hover_items.sort_custom(func(a, b):
		var area_a: float = (a.rect as Rect2).size.x * (a.rect as Rect2).size.y
		var area_b: float = (b.rect as Rect2).size.x * (b.rect as Rect2).size.y

		return area_a > area_b
	)


func hit_at(_pos: Vector2) -> Dictionary:
	for i: int in range(_hover_items.size() - 1, -1, -1):
		var item: Dictionary = _hover_items[i]

		if not (item.rect as Rect2).has_point(_pos):
			continue

		if item.kind == &'frame':
			return _enrich(item, {kind = &'frame_header', rect = Rect2(Vector2.ZERO, (item.rect as Rect2).size)})

		var card: HenFlowNodeCard = item.card

		if not card.visible:
			continue

		var local: Vector2 = _pos - (item.rect as Rect2).position

		# the card emits the whole rect last, so an inner part is always found first
		for hit: Dictionary in card.get_hits():
			if (hit.rect as Rect2).has_point(local):
				return _enrich(item, hit)

	return {}


func _enrich(_item: Dictionary, _hit: Dictionary) -> Dictionary:
	var out: Dictionary = _hit.duplicate()

	out.origin = (_item.rect as Rect2).position
	out.frame = _item.frame
	out.node = _item.node
	out.state = _item.state

	if _item.has('card'):
		out.card = _item.card

	return out


# --- editing ---

func _gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return

	var button: InputEventMouseButton = event

	# the cam pans with the right button too, so only a press that did not travel
	# opens the menu
	if button.button_index == MOUSE_BUTTON_RIGHT:
		if button.pressed:
			_context_press_pos = button.position
		elif button.position.distance_to(_context_press_pos) <= CLICK_TOLERANCE:
			_dispatch_context_click()

		return

	if button.button_index != MOUSE_BUTTON_LEFT:
		return

	if button.pressed:
		_click_press_pos = button.position
		return

	# drags never count as a click
	var is_click: bool = button.position.distance_to(_click_press_pos) <= CLICK_TOLERANCE

	if is_click and _dispatch_click():
		_click_last_time = 0
		return

	if not is_click:
		_click_last_time = 0
		return

	_clear_selection()

	var now: int = Time.get_ticks_msec()

	# two clicks on the empty canvas open the panel full screen
	if now - _click_last_time <= DOUBLE_CLICK_MS and button.position.distance_to(_click_last_pos) <= CLICK_TOLERANCE * 2.0:
		_click_last_time = 0

		var global: HenGlobal = Engine.get_singleton(&'Global') if Engine.has_singleton(&'Global') else null

		if global and global.HENGO_ROOT:
			global.HENGO_ROOT.toggle_fullscreen()

		return

	_click_last_time = now
	_click_last_pos = button.position


func _unhandled_key_input(event: InputEvent) -> void:
	if not is_visible_in_tree() or not event is InputEventKey:
		return

	var key: InputEventKey = event

	if not key.pressed:
		return

	var general_popup: HenGeneralPopup = Engine.get_singleton(&'GeneralPopup') if Engine.has_singleton(&'GeneralPopup') else null

	if general_popup and general_popup.has_open_popups():
		return

	if not _handle_shortcut(key):
		return

	get_viewport().set_input_as_handled()


func _handle_shortcut(_key: InputEventKey) -> bool:
	match _key.keycode:
		KEY_ESCAPE:
			if _selected_action.is_empty():
				return false

			_clear_selection()
			return true
		KEY_DELETE:
			return _delete_selected()
		KEY_Z:
			if not _key.ctrl_pressed:
				return false

			return _redo() if _key.shift_pressed else _undo()
		KEY_Y:
			return _redo() if _key.ctrl_pressed else false

	return false


# --- history ---

func _undo() -> bool:
	var global: HenGlobal = Engine.get_singleton(&'Global') if Engine.has_singleton(&'Global') else null

	if not global or not _history.undo(global.SAVE_DATA):
		return false

	_notify_structural()

	return true


func _redo() -> bool:
	var global: HenGlobal = Engine.get_singleton(&'Global') if Engine.has_singleton(&'Global') else null

	if not global or not _history.redo(global.SAVE_DATA):
		return false

	_notify_structural()

	return true


func _delete_selected() -> bool:
	var global: HenGlobal = Engine.get_singleton(&'Global') if Engine.has_singleton(&'Global') else null
	var action: HenSaveAction = selected_action()

	if not global or not global.SAVE_DATA or not action:
		return false

	var state_id: StringName = _state_by_action.get(_selected_action, &'')

	if state_id.is_empty():
		return false

	_history.begin(global.SAVE_DATA, state_id)

	if not global.SAVE_DATA.remove_action_anywhere(state_id, action):
		_history.abort()
		return false

	_history.commit(global.SAVE_DATA, 'Delete Action')
	_clear_selection()
	_notify_structural()

	return true


# the same signal the card editor fires, so codegen and the save flow see the edit
func _notify_structural() -> void:
	var signal_bus: HenSignalBus = Engine.get_singleton(&'SignalBus') if Engine.has_singleton(&'SignalBus') else null

	if signal_bus:
		signal_bus.request_structural_update.emit()
	else:
		rebuild()


# returns whether the click landed on something, so the caller can tell a miss
# from a hit and only count the miss toward the double click
func _dispatch_click() -> bool:
	var hit: Dictionary = hit_under_mouse()

	if hit.is_empty():
		return false

	if hit.kind == &'frame_header':
		_open_state(hit.state)
		return true

	var card: HenFlowNodeCard = hit.card

	# a transition card names where the flow goes, so it takes the reader there
	if card.node.kind == &'transition' and _focus_state(card.node.title):
		return true

	if hit.kind == &'exec_out' and _focus_branch(card, hit.pin):
		return true

	var action: HenSaveAction = card.node.action

	if not action:
		return true

	var origin: Vector2 = hit.origin
	var rect: Rect2 = screen_rect(Rect2(origin + (hit.rect as Rect2).position, (hit.rect as Rect2).size))

	if hit.kind == &'pin':
		_editing_card = card
		_editor_for(hit.node)
		_editor.open_producer((hit.part as Dictionary).get('slot', {}), rect)
		return true

	if hit.kind == &'chip':
		_editing_card = card
		_editor_for(hit.node)

		# an edit with no popup (a bool toggle) never reaches _on_popup_closed, and
		# the snapshot taken above would sit open until some later edit commits it
		if not _editor.chip_pressed(hit.part, int(hit.index), rect, _chip_ring.bind(card, origin)):
			var global: HenGlobal = Engine.get_singleton(&'Global') if Engine.has_singleton(&'Global') else null

			_history.commit(global.SAVE_DATA if global else null, 'Edit Action')

		return true

	_select_card(card)

	return true


# the action menu still lives in the inspector until the card grows its own
func _dispatch_context_click() -> bool:
	var hit: Dictionary = hit_under_mouse()

	if hit.is_empty() or not hit.has('card'):
		return false

	var card: HenFlowNodeCard = hit.card
	var action: HenSaveAction = card.node.action

	if not action:
		return false

	_select_card(card)

	var origin: Vector2 = hit.origin
	var rect: Rect2 = screen_rect(Rect2(origin + (hit.rect as Rect2).position, (hit.rect as Rect2).size))

	_editing_card = card
	_editor_for(hit.node)

	# a producer is not in the state's action list, so replace and delete would
	# look there and miss it
	_editor.edit_action(action, rect, card.node.kind == &'producer')

	return true


# --- selection ---

func _select_card(_card: HenFlowNodeCard) -> void:
	var action: HenSaveAction = _card.node.action

	if not action:
		_clear_selection()
		return

	_selected_action = str(action.id)
	_apply_selection()


func _clear_selection() -> void:
	if _selected_action.is_empty():
		return

	_selected_action = ''
	_apply_selection()


func _apply_selection() -> void:
	if not _selected_action.is_empty() and not _cards_by_action.has(_selected_action):
		_selected_action = ''

	for id: String in _cards_by_action:
		(_cards_by_action[id] as HenFlowNodeCard).set_selected(id == _selected_action)


func selected_action() -> HenSaveAction:
	var card: Variant = _cards_by_action.get(_selected_action)

	return card.node.action if card else null


# --- navigation ---

func _open_state(_state: HenSaveState) -> void:
	if not _state or not Engine.has_singleton(&'Global'):
		return

	var global: HenGlobal = Engine.get_singleton(&'Global')
	var route: HenRouteData = _state.get_route(global.SAVE_DATA) if global.SAVE_DATA else null

	if route:
		(Engine.get_singleton(&'Router') as HenRouter).change_route(route)


# a branch that goes somewhere reads as a link; one that falls through is a value
func _focus_branch(_card: HenFlowNodeCard, _pin: HenFlowGraphTypes.FlowPin) -> bool:
	var action: HenSaveAction = _card.node.action

	if not action or not Engine.has_singleton(&'Global'):
		return false

	var global: HenGlobal = Engine.get_singleton(&'Global')
	var target: HenSaveState = HenGeneratorAction.branch_target(global.SAVE_DATA, action, str(_pin.id))

	return _focus_frame(target)


# a transition card only carries the target's name, and the flow view is one
# script at a time, so a name is unique here
func _focus_state(_name: String) -> bool:
	for entry: Variant in _states.values():
		if (entry.state as HenSaveState).name == _name:
			return _focus_frame(entry.state)

	return false


func _focus_frame(_state: HenSaveState) -> bool:
	if not _state:
		return false

	var cam: HenCam = _cam()
	var entry: Variant = _states.get(String(_state.id))

	if not cam or not entry or not entry.has('frame'):
		return false

	var frame: HenFlowStateFrame = entry.frame
	var size: Vector2 = frame.frame_size()

	# a frame taller than the view is shown from its top, or the name goes offscreen
	cam.go_to_center(frame.position + Vector2(
		size.x * 0.5,
		minf(size.y, cam.get_rect().size.y) * 0.5
	))

	return true


func _editor_for(_node: HenStateViewerGraphTypes.DirectedGraphNode) -> void:
	if _editor == null:
		_editor = HenStateViewerCardEditor.new()
		_editor.changed.connect(_refresh_edited_card)

	var global: HenGlobal = Engine.get_singleton(&'Global') if Engine.has_singleton(&'Global') else null
	var state_id: StringName = StringName(str(_node.data.get('state_id', '')))

	_editor.target(global.SAVE_DATA if global else null, state_id)
	_history.begin(global.SAVE_DATA if global else null, state_id)


# a value edit usually leaves the card the same size, and then nothing around it
# moved: rebuilding the whole script would be the expensive way to do nothing
func _refresh_edited_card() -> void:
	if not is_instance_valid(_editing_card):
		rebuild()
		return

	var global: HenGlobal = Engine.get_singleton(&'Global') if Engine.has_singleton(&'Global') else null

	HenFlowGraphBuilder.refresh_parts(global.SAVE_DATA if global else null, _editing_card.node)

	if _editing_card.refresh_content():
		_rebuild_anchored(_editing_card)
		return

	_rebuild_hover_cache()


# a value that changes the card's width re-lays the whole graph, and the picture
# sliding under a still cursor reads as the edit having landed somewhere else
func _rebuild_anchored(_card: HenFlowNodeCard) -> void:
	var action: HenSaveAction = _card.node.action
	var id: String = str(action.id) if action else ''
	var before: Vector2 = _world_of(_card)

	rebuild()

	var after: Variant = _cards_by_action.get(id)

	if not after or before == Vector2.INF:
		return

	var delta: Vector2 = _world_of(after) - before
	var cam: HenCam = _cam()

	if delta == Vector2.ZERO or not cam:
		return

	# both, or the lerp target pulls the graph back to where it just moved
	var shift: Vector2 = delta * cam.transform.x.x

	cam.transform.origin -= shift
	cam.pos -= shift


func _world_of(_card: HenFlowNodeCard) -> Vector2:
	for item: Dictionary in _hover_items:
		if item.get('card') == _card:
			return (item.rect as Rect2).position

	return Vector2.INF


# every text-editable chip of the card, in reading order: the tab order. the card
# is re-emitted first because a committed value resizes the line it sits on
func _chip_ring(_card: HenFlowNodeCard, _origin: Vector2) -> Array:
	var ring: Array = []

	if not is_instance_valid(_card):
		return ring

	_card.refresh_content()

	for hit: Dictionary in _card.get_hits():
		if hit.kind != &'chip' or not bool((hit.part as Dictionary).get('editable', false)):
			continue

		ring.append({
			part = hit.part,
			index = hit.index,
			rect = screen_rect(Rect2(_origin + (hit.rect as Rect2).position, (hit.rect as Rect2).size))
		})

	return ring


func hit_under_mouse() -> Dictionary:
	if not is_instance_valid(nodes_container):
		return {}

	return hit_at(nodes_container.get_local_mouse_position())


# the cards are drawn, not controls, so the cam cannot tell a press on one from a
# press on the empty canvas by hit-testing the control tree
func blocks_pan() -> bool:
	return not hit_under_mouse().is_empty()


# a hit rect lives in the container's space; popups position in viewport space
func screen_rect(_local: Rect2) -> Rect2:
	var xform: Transform2D = nodes_container.get_global_transform()

	return Rect2(xform * _local.position, _local.size * xform.get_scale())


# a transition wears the colour of the state it leaves, which is what makes a run
# of them readable; the action's own colour said nothing about where the line goes
func _paint_edges(_node: HenStateViewerGraphTypes.DirectedGraphNode) -> void:
	for edge: HenStateViewerGraphTypes.DirectedGraphEdge in _node.edges:
		var entry: Variant = _states.get(String(edge.source.data.get('state_id', '')))

		if entry:
			edge.meta.color = _accent_for(entry.state).to_html(false)

	for child: HenStateViewerGraphTypes.DirectedGraphNode in _node.children:
		_paint_edges(child)
