@tool
class_name TestHenFlowStateHeader extends HenTestSuite

# the buttons a state frame carries in its header: they answer the mouse the same
# way a node card's own parts do, and the band around them does not


var state: HenSaveState


func before_test() -> void:
	super ()
	state = save_data.add_state(false)
	state.name = 'Play'


func _viewer() -> HenFlowViewer:
	var viewer: HenFlowViewer = auto_free(
		(load('res://addons/hengo/scenes/flow_viewer.tscn') as PackedScene).instantiate()
	)

	add_child(viewer)
	viewer.rebuild()

	return viewer


func _frame(_viewer: HenFlowViewer) -> HenFlowStateFrame:
	for entry: Variant in _viewer._states.values():
		if entry.has('frame'):
			return entry.frame

	return null


func _frame_of(_viewer: HenFlowViewer, _state: HenSaveState) -> HenFlowStateFrame:
	for entry: Variant in _viewer._states.values():
		if entry.state == _state:
			return entry.frame

	return null


# the hit rects are frame local, so the world point is the frame origin plus them
func _hit_at(_viewer: HenFlowViewer, _frame: HenFlowStateFrame, _kind: StringName) -> Dictionary:
	for hit: Dictionary in _frame.get_hits():
		if hit.kind != _kind:
			continue

		return _viewer.hit_at(_frame.position + (hit.rect as Rect2).get_center())

	return {}


func test_the_header_carries_the_move_delete_and_menu_buttons() -> void:
	var plain: HenSaveState = save_data.add_state(false)
	var frame: HenFlowStateFrame = _frame_of(_viewer(), plain)
	var kinds: Array = frame.get_hits().map(func(h: Dictionary) -> StringName: return h.kind)

	assert_array(kinds).contains([&'state_move', &'state_delete', &'state_menu'])


func test_the_base_state_offers_neither_move_nor_delete() -> void:
	var frame: HenFlowStateFrame = _frame_of(_viewer(), state)
	var kinds: Array = frame.get_hits().map(func(h: Dictionary) -> StringName: return h.kind)

	assert_bool(state.is_base).is_true()
	assert_array(kinds).not_contains([&'state_move'])
	assert_array(kinds).not_contains([&'state_delete'])
	assert_array(kinds).contains([&'state_menu'])


# the only state of a script is already the start, so the button is drawn but
# never registered: clicking it would be a no-op
func test_the_start_button_is_gone_on_a_state_that_already_starts() -> void:
	var frame: HenFlowStateFrame = _frame(_viewer())
	var kinds: Array = frame.get_hits().map(func(h: Dictionary) -> StringName: return h.kind)

	assert_bool(state.start).is_true()
	assert_array(kinds).not_contains([&'state_start'])


func test_a_state_that_does_not_start_offers_the_button() -> void:
	var second: HenSaveState = save_data.add_state(false)
	var viewer: HenFlowViewer = _viewer()
	var frame: HenFlowStateFrame = null

	for entry: Variant in viewer._states.values():
		if entry.state == second:
			frame = entry.frame

	var kinds: Array = frame.get_hits().map(func(h: Dictionary) -> StringName: return h.kind)

	assert_bool(second.start).is_false()
	assert_array(kinds).contains([&'state_start'])


func test_a_button_is_found_before_the_band_it_sits_in() -> void:
	var plain: HenSaveState = save_data.add_state(false)
	var viewer: HenFlowViewer = _viewer()
	var frame: HenFlowStateFrame = _frame_of(viewer, plain)

	assert_str(str(_hit_at(viewer, frame, &'state_menu').get('kind', ''))).is_equal('state_menu')
	assert_str(str(_hit_at(viewer, frame, &'state_delete').get('kind', ''))).is_equal('state_delete')


# the band used to reach the card branch of the dispatch, which reads a key a
# frame hit never carries
func test_the_band_around_the_buttons_carries_the_state_and_no_card() -> void:
	var viewer: HenFlowViewer = _viewer()
	var frame: HenFlowStateFrame = _frame(viewer)
	var hit: Dictionary = viewer.hit_at(frame.position + Vector2(4.0, frame.header_rect().size.y * 0.5))

	assert_str(str(hit.get('kind', ''))).is_equal('frame_header')
	assert_bool(hit.has('card')).is_false()
	assert_object(hit.get('state', null)).is_same(state)


# the header band is the state itself, so clicking it centres the view on it
func test_clicking_the_band_takes_the_view_to_the_state() -> void:
	save_data.add_state(false)

	var viewer: HenFlowViewer = _viewer()
	var frame: HenFlowStateFrame = _frame_of(viewer, state)
	var cam: HenCam = viewer.get_node('%Cam')
	var before: Vector2 = cam.pos

	var hit: Dictionary = viewer.hit_at(frame.position + Vector2(4.0, frame.header_rect().size.y * 0.5))

	assert_bool(viewer._dispatch_hit(hit)).is_true()
	assert_vector(cam.pos).is_not_equal(before)


func test_hovering_a_button_lights_only_that_frame() -> void:
	save_data.add_state(false)

	var viewer: HenFlowViewer = _viewer()
	var frame: HenFlowStateFrame = _frame(viewer)
	var menu: Rect2 = Rect2()

	for hit: Dictionary in frame.get_hits():
		if hit.kind == &'state_menu':
			menu = hit.rect

	viewer._update_hover(frame.position + menu.get_center())

	assert_object(viewer._hovered_frame).is_same(frame)

	viewer._update_hover(frame.position + Vector2(4.0, frame.header_rect().size.y * 0.5))

	assert_object(viewer._hovered_frame).is_null()


# the frame is measured wide enough for the strip, so the buttons never land on
# the name or on the node count
func test_the_frame_reserves_room_for_the_button_strip() -> void:
	state.name = 'a_state_with_a_fairly_long_name_to_push_the_header'

	var viewer: HenFlowViewer = _viewer()
	var frame: HenFlowStateFrame = _frame(viewer)
	var left: float = frame.frame_size().x

	for hit: Dictionary in frame.get_hits():
		left = minf(left, (hit.rect as Rect2).position.x)

	assert_float(frame.frame_size().x).is_greater_equal(frame._header_width() + HenFlowStateFrame.HEADER_PAD_H * 2.0)
	assert_float(left).is_greater(frame._text_end())


# the sidebar row is the other way into a state, and it reaches the graph through
# the bus: the panel is not in the tree while the tests run
func test_a_sidebar_row_takes_the_view_to_the_state() -> void:
	var far: HenSaveState = save_data.add_state(false)
	var viewer: HenFlowViewer = _viewer()
	var cam: HenCam = viewer.get_node('%Cam')
	var before: Vector2 = cam.pos

	_sidebar()._on_row_pressed(far, MOUSE_BUTTON_LEFT)

	assert_vector(cam.pos).is_not_equal(before)


# a sub-state row is drawn by the same sidebar path, and its frame is its own
func test_a_sub_state_row_takes_the_view_to_the_state() -> void:
	state.add_sub_state(save_data)

	var sub: HenSaveState = state.get_sub_states(save_data)[0]
	var viewer: HenFlowViewer = _viewer()
	var cam: HenCam = viewer.get_node('%Cam')
	var before: Vector2 = cam.pos

	_sidebar()._on_row_pressed(sub, MOUSE_BUTTON_LEFT)

	assert_vector(cam.pos).is_not_equal(before)


# a row that is not a state has nothing to centre on
func test_a_variable_row_leaves_the_view_alone() -> void:
	var viewer: HenFlowViewer = _viewer()
	var cam: HenCam = viewer.get_node('%Cam')
	var before: Vector2 = cam.pos

	_sidebar()._on_row_pressed(HenSaveVar.new(), MOUSE_BUTTON_LEFT)

	assert_vector(cam.pos).is_equal(before)


# the button is not just drawn: it reaches the op that flips the flag
func test_the_start_button_makes_the_state_start() -> void:
	var second: HenSaveState = save_data.add_state(false)
	var viewer: HenFlowViewer = _viewer()
	var frame: HenFlowStateFrame = null

	for entry: Variant in viewer._states.values():
		if entry.state == second:
			frame = entry.frame

	assert_bool(viewer._dispatch_hit(_hit_at(viewer, frame, &'state_start'))).is_true()

	assert_bool(second.start).is_true()
	assert_bool(state.start).is_false()


# blocking re-entry is the default, so the states that opt out say so in the graph
func test_a_reenterable_state_wears_a_badge() -> void:
	var viewer: HenFlowViewer = _viewer()
	var before: float = _frame_of(viewer, state)._text_end()

	state.can_reenter = true
	viewer.rebuild()

	assert_float(_frame_of(viewer, state)._text_end()).is_greater(before)


func test_the_header_offers_a_new_sub_state_button() -> void:
	var viewer: HenFlowViewer = _viewer()
	var frame: HenFlowStateFrame = _frame(viewer)
	var kinds: Array = frame.get_hits().map(func(h: Dictionary) -> StringName: return h.kind)

	assert_array(kinds).contains([&'state_add_sub'])

	assert_bool(viewer._dispatch_hit(_hit_at(viewer, frame, &'state_add_sub'))).is_true()
	assert_int(state.get_sub_states(save_data).size()).is_equal(1)


# a drawn button carries no tooltip_text, so the hint table is what it has: a
# button added without one would be silent on hover
func test_every_header_button_has_a_hint() -> void:
	var frame: HenFlowStateFrame = _frame(_viewer())

	for kind: StringName in HenFlowViewer.FRAME_BUTTONS:
		assert_bool(HenFlowViewer.FRAME_BUTTON_HINTS.has(str(kind))).is_true()

	for hit: Dictionary in frame.get_hits():
		assert_bool(HenFlowViewer.FRAME_BUTTON_HINTS.has(str(hit.kind))).is_true()


func _sidebar() -> HenSideBar:
	var side_bar: HenSideBar = auto_free(
		(load('res://addons/hengo/scenes/side_bar.tscn') as PackedScene).instantiate()
	)

	add_child(side_bar)

	return side_bar


# deleting only refreshed the sidebar, so the graph kept drawing the frame of a
# state that was already gone
func test_deleting_a_state_rebuilds_the_graph() -> void:
	var doomed: HenSaveState = save_data.add_state(false)
	doomed.name = 'Doomed'

	var side_bar: HenSideBar = _sidebar()
	var viewer: HenFlowViewer = _viewer()

	assert_int(viewer._states.size()).is_equal(2)

	var cmd := HenSideBar.DeleteResourceCommand.new(side_bar, doomed)

	assert_bool(cmd.can_remove()).is_true()
	cmd.remove()

	assert_int(viewer._states.size()).is_equal(1)
	assert_bool(viewer._states.has(str(doomed.id))).is_false()

	cmd.add()

	assert_int(viewer._states.size()).is_equal(2)


# the base state is the one the script always keeps, so the command refuses it
func test_the_base_state_cannot_be_deleted() -> void:
	var cmd := HenSideBar.DeleteResourceCommand.new(_sidebar(), state)

	assert_bool(state.is_base).is_true()
	assert_bool(cmd.can_remove()).is_false()
