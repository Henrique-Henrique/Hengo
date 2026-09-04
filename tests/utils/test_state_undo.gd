@tool
class_name TestHenStateUndo extends HenTestSuite

# undo/redo of the machine itself, driven through the very methods the ctrl+z
# shortcut routes to. nothing here sets a history up: a test that builds the
# mechanism that makes it pass is not testing the feature


var state: HenSaveState


func before_test() -> void:
	super ()
	(Engine.get_singleton(&'Global') as HenGlobal).flow_history = HenFlowHistory.new()
	state = save_data.add_state(false)
	state.name = 'Play'


func _viewer() -> HenFlowViewer:
	var viewer: HenFlowViewer = auto_free(
		(load('res://addons/hengo/scenes/flow_viewer.tscn') as PackedScene).instantiate()
	)

	add_child(viewer)
	viewer.rebuild()

	return viewer


func _frame_of(_viewer: HenFlowViewer, _state: HenSaveState) -> HenFlowStateFrame:
	for entry: Variant in _viewer._states.values():
		if entry.state == _state:
			return entry.frame

	return null


func _press(_viewer: HenFlowViewer, _state: HenSaveState, _kind: StringName) -> void:
	var frame: HenFlowStateFrame = _frame_of(_viewer, _state)

	for hit: Dictionary in frame.get_hits():
		if hit.kind != _kind:
			continue

		_viewer._dispatch_hit(_viewer.hit_at(frame.position + (hit.rect as Rect2).get_center()))
		return


func test_the_sub_state_button_is_undone_by_the_shortcut() -> void:
	var viewer: HenFlowViewer = _viewer()

	_press(viewer, state, &'state_add_sub')

	assert_int(state.get_sub_states(save_data).size()).is_equal(1)

	assert_bool(viewer._undo()).is_true()
	assert_int(state.get_sub_states(save_data).size()).is_equal(0)

	assert_bool(viewer._redo()).is_true()
	assert_int(state.get_sub_states(save_data).size()).is_equal(1)


# the same instance has to come back: a redo that built a new state would hand
# out a new id and orphan every branch pointing at the first
func test_redo_brings_back_the_same_state() -> void:
	var viewer: HenFlowViewer = _viewer()

	_press(viewer, state, &'state_add_sub')

	var created_id: String = str((state.get_sub_states(save_data)[0] as HenSaveState).id)

	viewer._undo()
	viewer._redo()

	assert_str(str((state.get_sub_states(save_data)[0] as HenSaveState).id)).is_equal(created_id)


func test_the_start_button_is_undone_by_the_shortcut() -> void:
	var second: HenSaveState = save_data.add_state(false)
	var viewer: HenFlowViewer = _viewer()

	_press(viewer, second, &'state_start')

	assert_bool(second.start).is_true()
	assert_bool(state.start).is_false()

	assert_bool(viewer._undo()).is_true()

	assert_bool(state.start).is_true()
	assert_bool(second.start).is_false()


func test_moving_a_state_is_undone_by_the_shortcut() -> void:
	var host: HenSaveState = save_data.add_state(false)
	var moved: HenSaveState = save_data.add_state(false)
	var viewer: HenFlowViewer = _viewer()

	HenStateOps.request_move(save_data, moved, host, false)

	assert_array(host.get_sub_states(save_data)).contains([moved])

	assert_bool(viewer._undo()).is_true()
	assert_array(save_data.states).contains([moved])

	assert_bool(viewer._redo()).is_true()
	assert_array(host.get_sub_states(save_data)).contains([moved])


# deleting takes the state and every action list under it, so the undo has to
# bring the body back too, not just the empty state
func test_deleting_a_state_is_undone_with_its_actions() -> void:
	var doomed: HenSaveState = save_data.add_state(false)
	doomed.name = 'Doomed'

	var macro := HenSaveMacro.new()
	macro.id = &'noop'
	macro.name = 'noop'
	(Engine.get_singleton(&'Global') as HenGlobal).action_macros.append(macro)
	save_data.add_state_action(doomed.id, HenSaveAction.create(macro))

	var side_bar: HenSideBar = auto_free(
		(load('res://addons/hengo/scenes/side_bar.tscn') as PackedScene).instantiate()
	)
	add_child(side_bar)

	var viewer: HenFlowViewer = _viewer()

	side_bar._request_delete_resource(doomed)

	assert_array(save_data.states).not_contains([doomed])
	assert_int(save_data.get_state_actions(doomed.id).size()).is_equal(0)

	assert_bool(viewer._undo()).is_true()

	assert_array(save_data.states).contains([doomed])
	assert_int(save_data.get_state_actions(doomed.id).size()).is_equal(1)

	assert_bool(viewer._redo()).is_true()
	assert_array(save_data.states).not_contains([doomed])


# an edit that changes nothing must not cost a ctrl+z that does nothing
func test_a_rejected_move_records_no_entry() -> void:
	var viewer: HenFlowViewer = _viewer()

	HenStateOps.request_move(save_data, state, state, false)

	assert_bool(viewer._undo()).is_false()


# variables share the machine's stack now: the write-only UndoRedo that used to
# take their edits is gone
func test_adding_a_variable_is_undone_by_the_shortcut() -> void:
	var viewer: HenFlowViewer = _viewer()
	var created: HenSaveVar = HenStateOps.request_add_var(save_data, false)

	assert_array(save_data.variables).contains([created])

	assert_bool(viewer._undo()).is_true()
	assert_array(save_data.variables).not_contains([created])

	assert_bool(viewer._redo()).is_true()
	assert_array(save_data.variables).contains([created])
	assert_str(str(save_data.variables[-1].id)).is_equal(str(created.id))
