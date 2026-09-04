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
# the doc is read on purpose, and a card is crossed on the way to another one
const DOC_DWELL: float = 0.75
const CULL_MARGIN: float = 256.0
const DOUBLE_CLICK_MS: int = 400
# HengoDebugger throttles a trace to one per 120ms per action, on purpose: an
# update action fires every frame. a shorter fade would strobe instead of glow
const RUN_TIME_MS: int = 200
# the header buttons of a state frame, the only part of the band that reacts
const FRAME_BUTTONS: Array[StringName] = [&'state_start', &'state_add_sub', &'state_move', &'state_delete', &'state_menu', &'state_enter']
const STATE_POPUP_SIZE: Vector2 = Vector2(360, 400)
# a button hint is glanced at, not read like a doc, so it waits far less
const BUTTON_DWELL: float = 0.3
const FRAME_BUTTON_HINTS: Dictionary = {
	state_start = 'Make this the state the machine starts on',
	state_add_sub = 'New sub-state inside this one',
	state_enter = 'Open the macro this state runs',
	state_move = 'Move this state into another state',
	state_delete = 'Delete this state',
	state_menu = 'State settings'
}

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
var _hovered_frame: HenFlowStateFrame = null
var _hover_kind: StringName = &''
var _last_hover_pos: Vector2 = Vector2.INF
var _tooltip_key: String = ''
var _editor: HenStateViewerCardEditor = null
var _editing_card: HenFlowNodeCard = null
var _click_press_pos: Vector2 = Vector2.ZERO
var _context_press_pos: Vector2 = Vector2.ZERO
# action id, not the card: a rebuild frees every card, and the selection has to
# come back on the node the user picked
var _selected_actions: Array[String] = []
# where a shift click measures the range from
var _selection_anchor: String = ''
# an action the graph is asked to centre on before it holds the card
var _pending_focus: String = ''
# same for a state picked while another scope was open
var _pending_state: String = ''
# the card the press landed on, and the drop it is currently pointing at
var _press_card: HenFlowNodeCard = null
var _dragging: bool = false
# the output a wire is being pulled from, and the rubber band that follows the
# cursor until it lands
var _wire_card: HenFlowNodeCard = null
var _wire_pin: HenFlowGraphTypes.FlowPin = null
var _wire_start: Vector2 = Vector2.ZERO
var _wire_line: Line2D = null
# while the badge is hovered: one line per reader, and the reference cards lit
var _wire_focus_lines: Array[Line2D] = []
var _wire_focus_cards: Array[HenFlowNodeCard] = []
var _drop_card: HenFlowNodeCard = null
var _drop_before: bool = true
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
# swapped in _ready for the one on Global, so the sidebar and the state ops record
# into the same stack. the local one covers the paths that return before that
var _history: HenFlowHistory = HenFlowHistory.new()
var _history_scope: String = ''
# the scope the cam is currently framing, so its view can be kept on the way out
var _cam_scope: String = ''


func _ready() -> void:
	if HenUtils.disable_scene_with_owner(self):
		return

	# EditorInterface only exists in the editor, and this scene also runs headless
	if Engine.is_editor_hint() and EditorInterface.get_edited_scene_root() is HenHengoRoot:
		return

	var signal_bus: HenSignalBus = Engine.get_singleton(&'SignalBus')

	if signal_bus:
		for signal_name: StringName in [&'request_list_update', &'request_structural_update', &'scripts_generation_finished', &'route_changed']:
			if not signal_bus.get(signal_name).is_connected(_on_changed):
				signal_bus.get(signal_name).connect(_on_changed)

		for pair: Array in [
			[&'request_focus_state', focus_state],
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

	var global: HenGlobal = Engine.get_singleton(&'Global') if Engine.has_singleton(&'Global') else null

	if global and global.flow_history:
		_history = global.flow_history

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
	set_process_shortcut_input(showing)

	if not showing:
		_release_hover()
		_clear_flashes()


func _release_hover() -> void:
	_last_hover_pos = Vector2.INF
	_hover_kind = &''

	if is_instance_valid(_hovered_card):
		_hovered_card.set_hover(&'', null)
		_hovered_card = null

	if is_instance_valid(_hovered_frame):
		_hovered_frame.set_hover(&'')
		_hovered_frame = null

	_close_tooltip()

	if _hovered_edge != null:
		_hovered_edge = null

		for node: HenStateViewerGraphTypes.DirectedGraphNode in _frames:
			(_frames[node] as HenFlowStateFrame).modulate.a = 1.0


func _cam() -> HenCam:
	if not is_instance_valid(_cam_node):
		_cam_node = get_node_or_null('%Cam') as HenCam

	return _cam_node


# one cam frames one script at a time, so the outgoing view is kept until its tab
# comes back
func _store_cam_view(_global: HenGlobal) -> void:
	if not _global or _cam_scope.is_empty():
		return

	var cam: HenCam = _cam()

	if cam:
		_global.CAM_VIEWS[_cam_scope] = cam.capture_view()


func _restore_cam_view(_global: HenGlobal, _scope_key: String) -> void:
	var cam: HenCam = _cam()

	if not _global or not cam:
		return

	cam.apply_view(_global.CAM_VIEWS.get(_scope_key, {}))


func _process(_delta: float) -> void:
	var cam: HenCam = _cam()

	if not cam:
		return

	var mouse: Vector2 = nodes_container.get_local_mouse_position()

	if mouse != _last_hover_pos or edges_overlay.get_hovered_edge() != _hovered_edge:
		_last_hover_pos = mouse
		_update_hover(mouse)

	if _press_card != null:
		_update_drag(mouse)

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
	_apply_frame_hover(hit)
	_apply_wire_focus(hit)
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


# only the header buttons light up: the band itself is not a target
func _apply_frame_hover(_hit: Dictionary) -> void:
	var kind: StringName = StringName(str(_hit.get('kind', &'')))
	var frame: HenFlowStateFrame = _hit.get('frame', null) if kind in FRAME_BUTTONS else null

	if is_instance_valid(_hovered_frame) and _hovered_frame != frame:
		_hovered_frame.set_hover(&'')

	_hovered_frame = frame

	if frame:
		frame.set_hover(kind)


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
	var kind: String = str(_hit.get('kind', ''))

	# the frame buttons are drawn and not controls, so the hint they would carry as
	# tooltip_text is served from here instead
	if FRAME_BUTTON_HINTS.has(kind):
		_show_tooltip(kind, str(FRAME_BUTTON_HINTS[kind]), BUTTON_DWELL)
		return

	var card: HenFlowNodeCard = _hit.get('card', null)
	var action: HenSaveAction = card.node.action if card else null

	if not action:
		_close_tooltip()
		return

	var global: HenGlobal = Engine.get_singleton(&'Global') if Engine.has_singleton(&'Global') else null

	if not global or not global.TOOLTIP:
		_tooltip_key = str(action.id)
		return

	var doc: String = HenActionDoc.bbcode(HenActionsPanel.find_macro(action.macro_id))
	var values: String = HenActionsPanel.value_preview(action, global.SAVE_DATA)
	var content: String = doc

	if not values.is_empty():
		content += ('\n\n' if not doc.is_empty() else '') + '[color=#5f6a7a]Current: ' + values + '[/color]'

	# first: the reason this step is dropped is what the hover is being asked for
	if not card.node.error.is_empty():
		var reason: String = '[color=#ef4444]This step is skipped: ' + card.node.error + '[/color]'

		content = reason + ('\n\n' + content if not content.is_empty() else '')

	_show_tooltip(str(action.id), content, DOC_DWELL)


# the key is what the hint is about, so crossing back onto the same target does
# not restart the dwell
func _show_tooltip(_key: String, _content: String, _dwell: float) -> void:
	if _tooltip_key == _key:
		return

	_tooltip_key = _key

	if _content.is_empty():
		return

	var global: HenGlobal = Engine.get_singleton(&'Global') if Engine.has_singleton(&'Global') else null

	if global and global.TOOLTIP:
		global.TOOLTIP.go_to(get_global_mouse_position(), _content, Vector2.ZERO, _dwell)


func _close_tooltip() -> void:
	if _tooltip_key.is_empty():
		return

	_tooltip_key = ''

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
		_store_cam_view(global)
		_cam_scope = ''
		_clear()
		return

	var save_data: HenSaveData = global.SAVE_DATA

	HenRoute.validate(save_data)

	var script_id: String = String(save_data.identity.id) if save_data.identity else ''
	var scope_key: String = HenRoute.key(script_id)

	# an entry restores a list into the scope it was taken from, so it means
	# nothing once another one is on screen
	if scope_key != _history_scope:
		_history_scope = scope_key
		_history.clear()

	if scope_key != _cam_scope:
		_store_cam_view(global)
		_cam_scope = scope_key
		_restore_cam_view(global, scope_key)

		# a definition edited in another scope may have grown an input, and the steps
		# that use it cloned the shape it had when they were created
		HenSaveAction.sync_macro_inputs(save_data)

	_clear()

	var scope: HenSaveResType = HenRoute.current_scope(save_data)

	_build_states(save_data, scope)
	_build_outer(save_data, scope)

	# the cards come back blank, and the sweep that marks the broken ones is the
	# root's: a manual refresh has nothing else to schedule it
	if global.HENGO_ROOT:
		global.HENGO_ROOT.schedule_check_errors()

	if not _pending_state.is_empty():
		var wanted_state: String = _pending_state

		_pending_state = ''

		focus_state(HenGeneratorAction.find_state(save_data, StringName(wanted_state)))

	if not _pending_focus.is_empty():
		var wanted: String = _pending_focus

		_pending_focus = ''

		focus_action(wanted, false)


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
func _build_states(_save_data: HenSaveData, _scope: HenSaveResType = null) -> void:
	var is_function: bool = _scope is HenSaveFunc

	for state: HenSaveState in _scope_states(_save_data, _scope):
		var graph: HenFlowGraphTypes.FlowGraph = _graph_of(_save_data, state, is_function)
		var cards: Array[HenFlowNodeCard] = []

		for node: HenFlowGraphTypes.FlowNode in graph.nodes:
			var card: HenFlowNodeCard = HenFlowNodeCard.new()

			nodes_container.add_child(card)
			card.setup(self, node)
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


func _graph_of(_save_data: HenSaveData, _state: HenSaveState, _is_function: bool) -> HenFlowGraphTypes.FlowGraph:
	if _state.is_macro_use():
		return HenFlowGraphBuilder.build_macro_use(_save_data, _state)

	if _is_function:
		return HenFlowGraphBuilder.build_function(_save_data, _state)

	return HenFlowGraphBuilder.build(_save_data, _state)


# the states the open scope draws: the whole machine of the script, or the single
# body of the function being edited
func _scope_states(_save_data: HenSaveData, _scope: HenSaveResType) -> Array[HenSaveState]:
	if _scope is HenSaveFunc:
		return [(_scope as HenSaveFunc).scope_state()] as Array[HenSaveState]

	if _scope is HenSaveStateMacro:
		var states: Array[HenSaveState] = []

		for state: HenSaveState in (_scope as HenSaveStateMacro).get_states(_save_data):
			_collect_tree(_save_data, state, states)

		return states

	return _all_states(_save_data)


# a sub state is a state with its own actions, and it lives in its own dictionary
# instead of carrying the flag: skipping it left its parent framing nothing at all
func _all_states(_save_data: HenSaveData) -> Array[HenSaveState]:
	var out: Array[HenSaveState] = []

	for state: HenSaveState in _save_data.states:
		_collect_tree(_save_data, state, out)

	return out


# the states of a macro are drawn inside the macro, never in the scope that uses
# it: a use is a closed box here
func _collect_tree(_save_data: HenSaveData, _state: HenSaveState, _out: Array[HenSaveState]) -> void:
	if _out.has(_state):
		return

	_out.append(_state)

	if _state.is_macro_use():
		return

	for sub: HenSaveState in _state.get_sub_states(_save_data):
		_collect_tree(_save_data, sub, _out)


# pass two: the frames on the state grid, which is the state viewer's own engine
func _build_outer(_save_data: HenSaveData, _scope: HenSaveResType = null) -> void:
	var dict: Dictionary = {
		id = 'collection',
		states = {_save_data.identity.name: HenStateGraphSource.scope_dict(_save_data, _scope)}
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

	var macro: HenSaveStateMacro = state.get_macro(_save_data()) if state.is_macro_use() else null
	var meta: String = ('runs the macro ' + macro.name) if macro else state.description

	nodes_container.add_child(frame)
	frame.setup(self, state.name, meta, (entry.graph as HenFlowGraphTypes.FlowGraph).nodes.size(), _accent_for(state), state.start, state.is_base, state.can_reenter)

	if state.is_function_scope:
		frame.hide_chrome()

	if state.is_macro_use():
		frame.mark_macro_use()

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


# the root already collected the reasons, so the red cards and the toolbar count
# cannot disagree. a card whose action is not in the list is cleared
func apply_errors(_errors: Array) -> void:
	var reasons: Dictionary = {}

	for error: Dictionary in _errors:
		reasons[str(error.get('action_id', ''))] = str(error.get('reason', ''))

	for entry: Variant in _states.values():
		for card: HenFlowNodeCard in entry.cards:
			var node: HenFlowGraphTypes.FlowNode = card.node

			if not node.action or not node.step:
				continue

			node.error = str(reasons.get(str(node.action.id), ''))
			card.sync_error()

	var count: Dictionary = _errors_per_state(_errors)

	for key: Variant in _states:
		var entry: Variant = _states[key]

		if entry.has('frame'):
			(entry.frame as HenFlowStateFrame).set_error_count(int(count.get(str(key), 0)))


func _errors_per_state(_errors: Array) -> Dictionary:
	var count: Dictionary = {}

	for error: Dictionary in _errors:
		var key: String = str(error.get('state_id', ''))

		count[key] = int(count.get(key, 0)) + 1

	return count


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
			var reach: Rect2 = card.hover_rect()

			_hover_items.append({
				kind = &'card',
				rect = Rect2(frame.position + card.position + reach.position, reach.size),
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
			var frame: HenFlowStateFrame = item.frame
			var header_local: Vector2 = _pos - (item.rect as Rect2).position

			for hit: Dictionary in frame.get_hits():
				if (hit.rect as Rect2).has_point(header_local):
					return _enrich(item, hit)

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
	# the press holds the mouse focus, so motion is what carries the drag even after
	# it leaves the viewer rect
	if event is InputEventMouseMotion:
		if _press_card != null:
			_update_drag(nodes_container.get_local_mouse_position())

		if _wire_card:
			_update_wire_drag(nodes_container.get_local_mouse_position())

		return

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

		# the dot is a small, specific target, so it takes the whole gesture and the
		# rest of the card goes on moving the step
		if _arm_wire_drag():
			return

		_press_card = _draggable_under_mouse()
		return

	if _wire_card:
		_finish_wire_drag()
		return

	if _dragging:
		_finish_drag()
		return

	_press_card = null

	# drags never count as a click
	var is_click: bool = button.position.distance_to(_click_press_pos) <= CLICK_TOLERANCE

	if is_click and _dispatch_click(button.ctrl_pressed, button.shift_pressed):
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


# _shortcut_input and not _unhandled_key_input: the editor binds its own keys
# above the unhandled layer, so alt+up reached the script editor instead
func _shortcut_input(event: InputEvent) -> void:
	if not is_visible_in_tree() or not event is InputEventKey:
		return

	var key: InputEventKey = event

	if not key.pressed or key.echo:
		return

	var general_popup: HenGeneralPopup = Engine.get_singleton(&'GeneralPopup') if Engine.has_singleton(&'GeneralPopup') else null

	if general_popup and general_popup.has_open_popups():
		return

	# _shortcut_input runs for the whole editor, above godot's own undo binding
	var global: HenGlobal = Engine.get_singleton(&'Global') if Engine.has_singleton(&'Global') else null

	if not global or not global.HENGO_ROOT or not global.HENGO_ROOT.has_input_focus():
		return

	# a bare letter is a shortcut only while nothing is being typed into
	var focus: Control = get_viewport().gui_get_focus_owner()

	if focus is LineEdit or focus is TextEdit:
		return

	if not _handle_shortcut(key):
		return

	get_viewport().set_input_as_handled()


# dispatched from HenShortcuts so the help popup and the handler cannot drift
func _handle_shortcut(_key: InputEventKey) -> bool:
	for entry: Dictionary in HenShortcuts.of_group(HenShortcuts.FLOW):
		if HenShortcuts.matches(entry, _key):
			return call(str(entry.method))

	return false


func _move_up() -> bool:
	return _move_selected(-1)


func _move_down() -> bool:
	return _move_selected(1)


func _select_chain_shortcut() -> bool:
	if _selected_actions.is_empty():
		return false

	_select_chain_of(_selected_actions[0])

	return true


func _clear_selection_shortcut() -> bool:
	if _selected_actions.is_empty():
		return false

	_clear_selection()

	return true


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


# one step at a time on purpose: moving a batch has to preserve the relative order
# of the moved steps, which is a different operation from swapping with a neighbour
func _move_selected(_delta: int) -> bool:
	var action: HenSaveAction = selected_action()
	var state_id: StringName = _state_by_action.get(str(action.id), &'') if action else &''

	if _selected_actions.size() != 1 or not action or state_id.is_empty():
		return false

	_editor_for_state(state_id)

	return _editor.move_in_chain(action, _delta)


# the menu path targets the editor through a graph node; a shortcut has only the
# state the selected action belongs to
func _editor_for_state(_state_id: StringName) -> void:
	_ensure_editor()

	var global: HenGlobal = Engine.get_singleton(&'Global') if Engine.has_singleton(&'Global') else null

	_editor.target(global.SAVE_DATA if global else null, _state_id)


func _copy_selected() -> bool:
	return HenActionClipboard.copy(selected_actions()) > 0


# the anchor is the last selected step, so a paste lands under the bottom of the
# selection instead of scattering from the top
func _paste_actions() -> bool:
	if not HenActionClipboard.has_content() or _selected_actions.is_empty():
		return false

	var anchor: HenSaveAction = _action_by_id(_selected_actions[-1])
	var state_id: StringName = _state_by_action.get(_selected_actions[-1], &'') if anchor else &''

	if not anchor or state_id.is_empty():
		return false

	_editor_for_state(state_id)

	return _editor.paste_around(HenActionClipboard.take(), anchor)


func _duplicate_selected() -> bool:
	var states: Array = _states_of_selection()

	if states.is_empty():
		return false

	var actions: Array[HenSaveAction] = selected_actions()

	_ensure_editor()

	return _history.record(_save_data(), states, 'Duplicate Action', func() -> bool:
		for action: HenSaveAction in actions:
			var state_id: StringName = _state_by_action.get(str(action.id), &'')

			if state_id.is_empty():
				continue

			_editor.target(_save_data(), state_id)
			_editor.duplicate_action(action)

		return true
	)


func _delete_selected() -> bool:
	var states: Array = _states_of_selection()

	if states.is_empty():
		return false

	var actions: Array[HenSaveAction] = selected_actions()

	_ensure_editor()

	# one entry for the batch: record is re-entrant, so the per action calls inside
	# it do not each push one, and the whole delete costs a single ctrl+z
	var done: bool = _history.record(_save_data(), states, 'Delete Action', func() -> bool:
		var any: bool = false

		for action: HenSaveAction in actions:
			var state_id: StringName = _state_by_action.get(str(action.id), &'')

			if state_id.is_empty():
				continue

			_editor.target(_save_data(), state_id)
			_editor.delete_action(action)
			any = true

		return any
	)

	_clear_selection()

	return done


# the same signal the card editor fires, so codegen and the save flow see the edit
func _notify_structural() -> void:
	var signal_bus: HenSignalBus = Engine.get_singleton(&'SignalBus') if Engine.has_singleton(&'SignalBus') else null

	if signal_bus:
		signal_bus.request_structural_update.emit()
	else:
		rebuild()


# returns whether the click landed on something, so the caller can tell a miss
# from a hit and only count the miss toward the double click
# the store card and the producer it saves are the same step, so either one drags
# it; an inline producer belongs to an input and is not a step at all
# the badge counts the readers, so hovering it has to say which ones: every reader
# lights up and gets a line back to the value it reads
func _apply_wire_focus(_hit: Dictionary) -> void:
	if str(_hit.get('kind', '')) != 'wire_out':
		_clear_wire_focus()
		return

	if not _wire_focus_lines.is_empty():
		return

	var card: HenFlowNodeCard = _hit.get('card', null)
	var pin: Variant = _hit.get('pin')
	var frame: HenFlowStateFrame = _hit.get('frame', null)
	var entry: Variant = _states.get(String((_hit.state as HenSaveState).id)) if _hit.get('state') else null

	if not card or not pin or not frame or not entry:
		return

	var from: Vector2 = frame.position + card.position + ((pin as HenFlowGraphTypes.FlowPin).rect as Rect2).get_center()
	var lit: Dictionary = {card: true}

	for edge: HenFlowGraphTypes.FlowEdge in (entry.graph as HenFlowGraphTypes.FlowGraph).edges_of(&'wire'):
		if edge.from_node != card.node or edge.from_pin != (pin as HenFlowGraphTypes.FlowPin).id:
			continue

		var reader: HenFlowNodeCard = _card_of_node(entry.cards, edge.to_node)

		if not reader:
			continue

		var line: Line2D = Line2D.new()

		line.width = 2.0
		line.default_color = Color(card.accent(), 0.85)
		line.z_index = 1
		line.points = PackedVector2Array([
			from,
			frame.position + reader.position + Vector2(reader.node.size.x, reader.node.size.y * 0.5)
		])

		nodes_container.add_child(line)
		_wire_focus_lines.append(line)

		lit[reader] = true

		# the reference is attached to the step that reads it, so dimming one and not
		# the other would cut the pair in half
		var consumer: HenFlowNodeCard = _card_of_node(entry.cards, _consumer_of(entry.graph, edge.to_node))

		if consumer:
			lit[consumer] = true

	if lit.size() < 2:
		return

	# the same reading a hovered transition gives: what takes part stays lit and the
	# rest of the state steps back
	for other: HenFlowNodeCard in entry.cards:
		if lit.has(other):
			continue

		other.modulate.a = FRAME_DIM
		_wire_focus_cards.append(other)


# the step a reference feeds, which is the other half of the pair
func _consumer_of(_graph: HenFlowGraphTypes.FlowGraph, _reference: HenFlowGraphTypes.FlowNode) -> HenFlowGraphTypes.FlowNode:
	for edge: HenFlowGraphTypes.FlowEdge in _graph.edges_of(&'data'):
		if edge.from_node == _reference:
			return edge.to_node

	return null


func _card_of_node(_cards: Array, _node: HenFlowGraphTypes.FlowNode) -> HenFlowNodeCard:
	for card: HenFlowNodeCard in _cards:
		if card.node == _node:
			return card

	return null


func _clear_wire_focus() -> void:
	for line: Line2D in _wire_focus_lines:
		if is_instance_valid(line):
			line.queue_free()

	for card: HenFlowNodeCard in _wire_focus_cards:
		if is_instance_valid(card):
			card.modulate.a = 1.0

	_wire_focus_lines.clear()
	_wire_focus_cards.clear()


# true when the press landed on an output, which is what starts a wire
func _arm_wire_drag() -> bool:
	var hit: Dictionary = hit_under_mouse()

	if hit.is_empty() or not hit.has('card') or str(hit.get('kind', '')) != 'output':
		return false

	var card: HenFlowNodeCard = hit.card

	if not card.node.action or not card.node.step:
		return false

	_wire_card = card
	_wire_pin = hit.get('pin')
	_wire_start = (hit.origin as Vector2) + (_wire_pin.rect as Rect2).get_center()
	_wire_line = Line2D.new()
	_wire_line.width = 2.0
	_wire_line.default_color = card.accent()
	_wire_line.z_index = 1
	nodes_container.add_child(_wire_line)
	HenFlowNodeCard.wire_dropping = true

	return true


func _update_wire_drag(_mouse: Vector2) -> void:
	if not is_instance_valid(_wire_card) or not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_clear_wire_drag()
		return

	if is_instance_valid(_wire_line):
		_wire_line.points = PackedVector2Array([_wire_start, _mouse])


# an input under the cursor takes the value; anywhere else the gesture is dropped
func _finish_wire_drag() -> void:
	var hit: Dictionary = hit_under_mouse()
	var source: HenFlowNodeCard = _wire_card
	var pin: HenFlowGraphTypes.FlowPin = _wire_pin

	_clear_wire_drag()

	if not is_instance_valid(source) or not pin or hit.is_empty() or not hit.has('card'):
		return

	var target: HenFlowNodeCard = hit.card
	var into: Variant = hit.get('pin')

	var kind: String = str(hit.get('kind', ''))

	if not target.node.action or not into or (kind != 'pin' and kind != 'wired_in'):
		return

	_connect_wire(source.node.action, pin.id, target.node.action, (into as HenFlowGraphTypes.FlowPin).id)


func _clear_wire_drag() -> void:
	HenFlowNodeCard.wire_dropping = false

	if is_instance_valid(_wire_line):
		_wire_line.queue_free()

	_wire_line = null
	_wire_card = null
	_wire_pin = null


# the slot goes back to whatever the macro defaults it to, which is what an empty
# source means everywhere else
func _disconnect_wire(_consumer: HenSaveAction, _input: StringName) -> void:
	var state_id: StringName = _state_by_action.get(str(_consumer.id), &'')

	if state_id.is_empty():
		return

	var key: String = str(_input)

	_history.record(_save_data(), [state_id], 'Unwire Value', func() -> bool:
		_consumer.input_wires.erase(key)

		return true
	)

	_request_rebuild()


# the slot takes one source at a time, so wiring it drops whatever fed it before
func _connect_wire(
	_producer: HenSaveAction,
	_output: StringName,
	_consumer: HenSaveAction,
	_input: StringName
) -> void:
	var state_id: StringName = _state_by_action.get(str(_consumer.id), &'')

	if state_id.is_empty():
		return

	var key: String = str(_input)

	_history.record(_save_data(), [state_id], 'Wire Value', func() -> bool:
		_consumer.input_bindings.erase(key)
		_consumer.input_expressions.erase(key)
		_consumer.input_actions.erase(key)
		_consumer.input_wires[key] = {action_id = StringName(str(_producer.id)), output = _output}

		return true
	)

	_request_rebuild()


func _draggable_under_mouse() -> HenFlowNodeCard:
	var hit: Dictionary = hit_under_mouse()

	if hit.is_empty() or not hit.has('card'):
		return null

	var card: HenFlowNodeCard = hit.card

	return card if card.node.step and card.node.action else null


func _update_drag(_mouse: Vector2) -> void:
	if not is_instance_valid(_press_card) or not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		# a release the viewer never saw would leave the drag armed, and then the next
		# plain click would land a drop
		if _dragging:
			_finish_drag()
		else:
			_press_card = null

		return

	if not _dragging:
		if get_local_mouse_position().distance_to(_click_press_pos) <= CLICK_TOLERANCE:
			return

		_dragging = true

	var target: HenFlowNodeCard = _draggable_under_mouse()

	# by action and not by card: a stored step draws as a producer plus its store
	if target == null or target.node.action == _press_card.node.action \
			or _is_dragged_along(target) or _is_inside_drag(target):
		_set_drop(null, true)
		return

	var rect: Rect2 = _card_world_rect(target)

	_set_drop(target, _mouse.y < rect.position.y + rect.size.y * 0.5)


func _card_world_rect(_card: HenFlowNodeCard) -> Rect2:
	for item: Dictionary in _hover_items:
		if item.get('card') == _card:
			return item.rect

	return Rect2()


func _set_drop(_card: HenFlowNodeCard, _before: bool) -> void:
	if _drop_card == _card and _drop_before == _before:
		return

	if is_instance_valid(_drop_card):
		_drop_card.set_drop_edge(-1)

	_drop_card = _card
	_drop_before = _before

	if is_instance_valid(_drop_card):
		_drop_card.set_drop_edge(0 if _before else 1)


func _finish_drag() -> void:
	var dragged: HenFlowNodeCard = _press_card
	var target: HenFlowNodeCard = _drop_card
	var before: bool = _drop_before

	_dragging = false
	_press_card = null
	_set_drop(null, true)

	if not is_instance_valid(dragged) or not is_instance_valid(target):
		return

	var batch: Array[HenSaveAction] = _drag_batch(dragged)

	if batch.size() > 1:
		_apply_drop_batch(batch, target.node.action, before)
		return

	_apply_drop(batch[0], target.node.action, before)


# dragging a card of the selection carries the whole selection, dragging any
# other card leaves it alone
func _drag_batch(_card: HenFlowNodeCard) -> Array[HenSaveAction]:
	if not _selected_actions.has(str(_card.node.action.id)):
		return [_card.node.action] as Array[HenSaveAction]

	return _roots_only(selected_actions())


# a step nested in another step of the batch already travels inside it, and moving
# it on its own would pull it out of the parent it was selected with
func _roots_only(_actions: Array[HenSaveAction]) -> Array[HenSaveAction]:
	var out: Array[HenSaveAction] = []

	for action: HenSaveAction in _actions:
		var nested: bool = false

		for other: HenSaveAction in _actions:
			if other != action and HenActionsPanel.contains_action(other, action):
				nested = true
				break

		if not nested:
			out.append(action)

	return out


func _is_dragged_along(_card: HenFlowNodeCard) -> bool:
	if not is_instance_valid(_press_card) or not _selected_actions.has(str(_press_card.node.action.id)):
		return false

	return _selected_actions.has(str(_card.node.action.id))


# a loop dropped into its own body would take the target with it
func _is_inside_drag(_card: HenFlowNodeCard) -> bool:
	for action: HenSaveAction in _drag_batch(_press_card):
		if HenActionsPanel.contains_action(action, _card.node.action):
			return true

	return false


# every action lands on the same anchor, so a drop below the target runs
# backwards to keep the order the selection had on screen
func _apply_drop_batch(_actions: Array[HenSaveAction], _target: HenSaveAction, _before: bool) -> bool:
	var states: Array = _states_of_selection()
	var to_id: StringName = _state_by_action.get(str(_target.id), &'')

	if not to_id.is_empty() and not states.has(to_id):
		states.append(to_id)

	if states.is_empty():
		return false

	var ordered: Array = _actions.duplicate()

	if not _before:
		ordered.reverse()

	_ensure_editor()

	return _history.record(_save_data(), states, 'Move Action', func() -> bool:
		var any: bool = false

		for action: HenSaveAction in ordered:
			if action == _target:
				continue

			if _apply_drop(action, _target, _before):
				any = true

		return any
	)


func _apply_drop(_dragged: HenSaveAction, _target: HenSaveAction, _before: bool) -> bool:
	var from_id: StringName = _state_by_action.get(str(_dragged.id), &'')
	var to_id: StringName = _state_by_action.get(str(_target.id), &'')

	if from_id.is_empty() or to_id.is_empty():
		return false

	_ensure_editor()

	return _editor.drop_step(_dragged, _target, _before, from_id, to_id)


func _dispatch_click(_ctrl: bool = false, _shift: bool = false) -> bool:
	return _dispatch_hit(hit_under_mouse(), _ctrl, _shift)


func _dispatch_hit(hit: Dictionary, _ctrl: bool = false, _shift: bool = false) -> bool:
	if hit.is_empty():
		return false

	var rect: Rect2 = screen_rect(Rect2((hit.origin as Vector2) + (hit.rect as Rect2).position, (hit.rect as Rect2).size))

	# a frame hit carries no card, so it is answered before anything reads one
	if FRAME_BUTTONS.has(hit.kind):
		return _dispatch_state_button(StringName(str(hit.kind)), hit.state, rect)

	# the header band is the state itself, so picking it takes the view there, the
	# same way a transition card does
	if hit.kind == &'frame_header':
		return focus_state(hit.state)

	var card: HenFlowNodeCard = hit.get('card', null)

	# the band around the buttons behaves like the canvas behind it
	if not card:
		return false

	# before the action guard below too: a reference stands for a value made
	# elsewhere, so it carries no action of its own
	if hit.kind == &'unwire' and card.node.wire_owner:
		_disconnect_wire(card.node.wire_owner, card.node.wire_input)
		return true

	if card.node.kind == &'wire_ref' and card.node.wire_source:
		return focus_action(str(card.node.wire_source.id))

	# a step that stands for a definition takes the canvas into it
	if hit.kind == &'enter_scope' and not card.node.enter_scope.is_empty():
		HenRoute.enter(StringName(str(card.node.enter_scope.kind)), StringName(str(card.node.enter_scope.id)), true)
		return true

	# before the action guard below: an add tail has no action of its own
	if hit.kind == &'add_tail':
		_editing_card = card
		_editor_for(hit.node)
		_editor.open_add(card.node.phase, card.node.body_parent, -1, rect, null, card.node.body_branch)
		return true

	# a phase cell of the entry is where its chain is started, the same way a branch
	# cell is where a branch is set
	if hit.kind == &'exec_out' and card.node.kind == &'state_entry':
		var pin_id: String = str((hit.pin as HenFlowGraphTypes.FlowPin).id)

		# a way out of a macro leads to a state, so its cell picks one
		if pin_id.begins_with(HenFlowGraphTypes.WAY_OUT_PIN):
			return _open_way_out_picker(card, pin_id.substr(HenFlowGraphTypes.WAY_OUT_PIN.length()))

		_editing_card = card
		_editor_for(hit.node)
		_editor.open_add(StringName(pin_id), null, -1, rect)
		return true

	if (hit.kind == &'add_above' or hit.kind == &'add_below') and card.node.action:
		_editing_card = card
		_editor_for(hit.node)
		_editor.add_around(card.node.action, rect, hit.kind == &'add_below')
		return true

	# a transition card names where the flow goes, so it takes the reader there
	if card.node.kind == &'transition' and _focus_state_by_name(card.node.title):
		return true

	# always the editor, never the camera: a branch that already went somewhere could
	# not be changed, because the click that would change it panned away instead. the
	# transition card below is what takes the reader to the target
	if hit.kind == &'exec_out' and card.node.action:
		_editing_card = card
		_editor_for(hit.node)
		_editor.open_branch(
			card.node.action,
			str((hit.pin as HenFlowGraphTypes.FlowPin).id),
			(hit.pin as HenFlowGraphTypes.FlowPin).label,
			screen_rect(Rect2((hit.origin as Vector2) + (hit.rect as Rect2).position, (hit.rect as Rect2).size))
		)

		return true

	
	if hit.kind == &'chip':
		_editing_card = card
		_editor_for(hit.node)

		if not _editor.chip_pressed(hit.part, rect):
			var global: HenGlobal = Engine.get_singleton(&'Global') if Engine.has_singleton(&'Global') else null

			_history.commit(global.SAVE_DATA if global else null, 'Edit Action')

		return true

	var action: HenSaveAction = card.node.action

	if not action:
		return true

	if hit.kind == &'menu' and card.node.action:
		_select_card(card)
		_open_card_menu(hit, card, card.node.action)
		return true

	# an inline producer is stored on the action holding the slot, so a use of a
	# macro has nowhere to park one
	if hit.kind == &'pin':
		_editing_card = card
		_editor_for(hit.node)
		_editor.open_producer((hit.part as Dictionary).get('slot', {}), rect)
		return true

	_click_select(card, _ctrl, _shift)

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
	_open_card_menu(hit, card, action)

	return true


# the ways out of a macro are wired per use, so the cell asks which state this one
# hands control to
func _open_way_out_picker(_card: HenFlowNodeCard, _exit_id: String) -> bool:
	var use: HenSaveState = _state_of_entry(_card)

	if not use or not use.is_macro_use():
		return false

	HenStateOps.open_way_out_menu(use, _exit_id)

	return true


# the state whose graph holds this entry card, which a card with no action of its
# own cannot be found by
func _state_of_entry(_card: HenFlowNodeCard) -> HenSaveState:
	for entry: Variant in _states.values():
		if (entry.graph as HenFlowGraphTypes.FlowGraph).entry == _card.node:
			return entry.state

	return null


# the state chrome mirrors the sidebar: the same menu, the same confirm and the
# same undo entry, reached from the graph instead of from the list
func _dispatch_state_button(_kind: StringName, _state: HenSaveState, _rect: Rect2) -> bool:
	var side_bar: HenSideBar = (Engine.get_singleton(&'Global') as HenGlobal).SIDE_BAR

	match _kind:
		&'state_enter':
			HenRoute.enter(HenRoute.KIND_MACRO, _state.macro_id, true)
		&'state_start':
			HenStateOps.request_set_start(HenStateOps.owner_of(_state), _state)
		&'state_add_sub':
			HenStateOps.request_add_state(HenStateOps.owner_of(_state), _state)
		&'state_move':
			HenStateOps.open_move_menu(_state)
		&'state_delete':
			if side_bar:
				side_bar.confirm_delete_resource(_state)
		&'state_menu':
			if side_bar:
				HenInspector.edit_resource(
					_state,
					side_bar.get_inspect_title(_state),
					side_bar.get_inspect_actions(_state),
					_state_popup_opts(_rect)
				)

	return true


# the inspector body is a scroll with no minimum of its own, so a height that is
# only asked of the content opens the panel closed
func _state_popup_opts(_rect: Rect2) -> Dictionary:
	return {
		layout = HenGeneralPopup.Layout.ANCHORED,
		anchor_rect = _rect,
		side = SIDE_BOTTOM,
		blur = false,
		min_size = STATE_POPUP_SIZE
	}


# a producer is not in the state's action list, so replace and delete would look
# there and miss it
func _open_card_menu(_hit: Dictionary, _card: HenFlowNodeCard, _action: HenSaveAction) -> void:
	var origin: Vector2 = _hit.origin
	var rect: Rect2 = screen_rect(Rect2(origin + (_hit.rect as Rect2).position, (_hit.rect as Rect2).size))

	_editing_card = _card
	_editor_for(_hit.node)
	_editor.open_action_menu(_action, rect, _card.node.kind == &'producer')


func _save_data() -> HenSaveData:
	var global: HenGlobal = Engine.get_singleton(&'Global') if Engine.has_singleton(&'Global') else null

	return global.SAVE_DATA if global else null


# every state the selection touches, so one entry covers the whole batch
func _states_of_selection() -> Array:
	var states: Array = []

	for id: String in _selected_actions:
		var state_id: StringName = _state_by_action.get(id, &'')

		if not state_id.is_empty() and not states.has(state_id):
			states.append(state_id)

	return states


# --- selection ---

# ctrl grows the selection, shift takes the range, a plain click replaces it
func _click_select(_card: HenFlowNodeCard, _ctrl: bool, _shift: bool) -> void:
	if _ctrl:
		_toggle_card(_card)
	elif _shift:
		_select_range_to(_card)
	else:
		_select_card(_card)


# ids and not cards: a rebuild frees every card, and the selection has to come
# back on the nodes the user picked
func _select_card(_card: HenFlowNodeCard) -> void:
	var action: HenSaveAction = _card.node.action

	if not action:
		_clear_selection()
		return

	_selected_actions = [str(action.id)]
	_selection_anchor = str(action.id)
	_apply_selection()


func _toggle_card(_card: HenFlowNodeCard) -> void:
	var action: HenSaveAction = _card.node.action

	if not action:
		return

	var id: String = str(action.id)

	if _selected_actions.has(id):
		_selected_actions.erase(id)
	else:
		_selected_actions.append(id)
		_selection_anchor = id

	_apply_selection()


# the range is measured along the chain the anchor belongs to: the flat list mixes
# phases, and two steps of different phases are never neighbours in the graph
func _select_range_to(_card: HenFlowNodeCard) -> void:
	var action: HenSaveAction = _card.node.action

	if not action:
		return

	var anchor: HenSaveAction = _action_by_id(_selection_anchor)

	if not anchor or str(anchor.phase) != str(action.phase):
		_select_card(_card)
		return

	var state_id: StringName = _state_by_action.get(str(action.id), &'')

	if state_id.is_empty() or state_id != _state_by_action.get(_selection_anchor, &''):
		_select_card(_card)
		return

	var global: HenGlobal = Engine.get_singleton(&'Global') if Engine.has_singleton(&'Global') else null

	if not global or not global.SAVE_DATA:
		return

	var bucket: Array = HenActionsPanel.group_by_phase(global.SAVE_DATA.get_state_actions(state_id)).get(str(action.phase), [])
	var from: int = bucket.find(anchor)
	var to: int = bucket.find(action)

	if from < 0 or to < 0:
		_select_card(_card)
		return

	_selected_actions.clear()

	for i: int in range(mini(from, to), maxi(from, to) + 1):
		_selected_actions.append(str((bucket[i] as HenSaveAction).id))

	_apply_selection()


func _select_chain_of(_id: String) -> void:
	var action: HenSaveAction = _action_by_id(_id)
	var state_id: StringName = _state_by_action.get(_id, &'')
	var global: HenGlobal = Engine.get_singleton(&'Global') if Engine.has_singleton(&'Global') else null

	if not action or state_id.is_empty() or not global or not global.SAVE_DATA:
		return

	var bucket: Array = HenActionsPanel.group_by_phase(global.SAVE_DATA.get_state_actions(state_id)).get(str(action.phase), [])

	_selected_actions.clear()

	for step: HenSaveAction in bucket:
		_selected_actions.append(str(step.id))

	_apply_selection()


func _clear_selection() -> void:
	if _selected_actions.is_empty():
		return

	_selected_actions.clear()
	_selection_anchor = ''
	_apply_selection()


func _apply_selection() -> void:
	# an action deleted elsewhere leaves an id pointing at nothing
	for i: int in range(_selected_actions.size() - 1, -1, -1):
		if not _cards_by_action.has(_selected_actions[i]):
			_selected_actions.remove_at(i)

	for id: String in _cards_by_action:
		(_cards_by_action[id] as HenFlowNodeCard).set_selected(_selected_actions.has(id))


func _action_by_id(_id: String) -> HenSaveAction:
	var card: Variant = _cards_by_action.get(_id)

	return card.node.action if card else null


func _state_of_card(_card: HenFlowNodeCard) -> HenSaveState:
	if not is_instance_valid(_card) or not _card.node.action:
		return null

	var entry: Variant = _states.get(str(_state_by_action.get(str(_card.node.action.id), '')))

	return entry.state if entry else null


# the first of the selection, for the operations that still take one
func selected_action() -> HenSaveAction:
	return _action_by_id(_selected_actions[0]) if not _selected_actions.is_empty() else null


# in chain order, so a batch keeps the shape it had on screen
func selected_actions() -> Array[HenSaveAction]:
	var out: Array[HenSaveAction] = []

	for id: String in _selected_actions:
		var action: HenSaveAction = _action_by_id(id)

		if action:
			out.append(action)

	return out


# --- navigation ---

# a transition card only carries the target's name, and the flow view is one
# script at a time, so a name is unique here
func _focus_state_by_name(_name: String) -> bool:
	for entry: Variant in _states.values():
		if (entry.state as HenSaveState).name == _name:
			return focus_state(entry.state)

	return false


# swaps the open scope for the one holding this state, when it is not the one on
# screen. false when it already is
func _open_scope_of(_state: HenSaveState) -> bool:
	var global: HenGlobal = Engine.get_singleton(&'Global') if Engine.has_singleton(&'Global') else null
	var save_data: HenSaveData = global.SAVE_DATA if global else null

	if not save_data:
		return false

	var wanted: Array = HenRoute.stack_for(save_data, StringName(str(_state.id)))

	if wanted == HenRoute.stack():
		return false

	HenRoute.set_stack(wanted)

	return true


# centers on one step and selects it, which is how the error list lands on a card.
# switching scripts rebuilds the graph, so a request that arrives first waits
func focus_action(_action_id: String, _keep: bool = true) -> bool:
	var card: Variant = _cards_by_action.get(_action_id)
	var cam: HenCam = _cam()
	var origin: Vector2 = _world_of(card) if card else Vector2.INF

	if not card or not cam or origin == Vector2.INF:
		if _keep:
			_pending_focus = _action_id

		return false

	cam.go_to_center(origin + (card as HenFlowNodeCard).node.size * 0.5)
	_select_card(card)

	return true


func focus_state(_state: HenSaveState) -> bool:
	if not _state:
		return false

	var cam: HenCam = _cam()
	var entry: Variant = _states.get(String(_state.id))

	# the state lives in another scope: open it and centre once it is drawn. the
	# request is written first because opening redraws right here, and a request
	# left over would drag the next scope back to this state
	if not entry:
		_pending_state = String(_state.id)

		if _open_scope_of(_state):
			return true

		_pending_state = ''

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


# the menu runs its callbacks deferred, after the popup boundary already closed,
# so the editor records straight into the stack instead of relying on it
func _ensure_editor() -> void:
	if _editor != null:
		return

	_editor = HenStateViewerCardEditor.new()
	_editor.changed.connect(_refresh_edited_card)
	_editor.record_hook = func(_states: Array, _label: String, _mutation: Callable) -> bool:
		var global: HenGlobal = Engine.get_singleton(&'Global') if Engine.has_singleton(&'Global') else null

		if not global:
			return _mutation.call()

		return _history.record(global.SAVE_DATA, _states, _label, _mutation)


func _editor_for(_node: HenStateViewerGraphTypes.DirectedGraphNode) -> void:
	_ensure_editor()

	var global: HenGlobal = Engine.get_singleton(&'Global') if Engine.has_singleton(&'Global') else null
	var state_id: StringName = StringName(str(_node.data.get('state_id', '')))

	_editor.target(global.SAVE_DATA if global else null, state_id)
	_history.begin(global.SAVE_DATA if global else null, [state_id])


# a value edit usually leaves the card the same size, and then nothing around it
# moved: rebuilding the whole script would be the expensive way to do nothing
func _refresh_edited_card() -> void:
	if not is_instance_valid(_editing_card):
		rebuild()
		return

	var global: HenGlobal = Engine.get_singleton(&'Global') if Engine.has_singleton(&'Global') else null

	HenFlowGraphBuilder.refresh_parts(global.SAVE_DATA if global else null, _editing_card.node)
	HenFlowGraphBuilder.refresh_error(
		global.SAVE_DATA if global else null,
		_state_of_card(_editing_card),
		_editing_card.node
	)
	_editing_card.sync_error()

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


func hit_under_mouse() -> Dictionary:
	if not is_instance_valid(nodes_container):
		return {}

	return hit_at(nodes_container.get_local_mouse_position())


# the cards are drawn, not controls, so the cam cannot tell a press on one from a
# press on the empty canvas by hit-testing the control tree
func blocks_pan() -> bool:
	return _dragging or not hit_under_mouse().is_empty()


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
