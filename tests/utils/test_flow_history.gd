@tool
class_name TestHenFlowHistory extends HenTestSuite


const FIX_MATH: String = 'res://addons/hengo/actions/math/math_operator.gd'

var state: HenSaveState
var history: HenFlowHistory


func before_test() -> void:
	super ()
	state = save_data.add_state(false)
	state.name = 'Play'
	history = HenFlowHistory.new()


func _macro() -> HenSaveMacro:
	var instance: HenScriptMacroBase = (load(FIX_MATH) as GDScript).new()
	var macro: HenSaveMacro = HenSaveMacro.new()

	macro.id = instance.get_id()
	macro.name = 'math_operator'
	macro.is_script_macro = true
	macro.script_path = FIX_MATH

	for input: Dictionary in instance.get_inputs():
		macro.inputs.append(HenSaveParam.create(input))

	for output: Dictionary in instance.get_outputs():
		macro.outputs.append(HenSaveParam.create(output))

	(Engine.get_singleton(&'Global') as HenGlobal).action_macros.append(macro)

	return macro


func _add(_count: int = 1) -> Array:
	var macro: HenSaveMacro = _macro()
	var out: Array = []

	for i: int in range(_count):
		var action: HenSaveAction = HenSaveAction.create(macro)

		action.phase = &'update'
		save_data.add_state_action(state.id, action)
		out.append(action)

	return out


func _first() -> HenSaveAction:
	return save_data.get_state_actions(state.id)[0]


func test_a_changed_list_is_pushed() -> void:
	var actions: Array = _add()

	history.begin(save_data, state.id)
	(actions[0] as HenSaveAction).inputs[0].default_value = 9.0

	assert_bool(history.commit(save_data, 'Edit')).is_true()
	assert_bool(history.can_undo()).is_true()


# a popup opened and closed with no edit would otherwise cost a ctrl+z that does nothing
func test_an_untouched_list_is_not_pushed() -> void:
	_add()

	history.begin(save_data, state.id)

	assert_bool(history.commit(save_data, 'Edit')).is_false()
	assert_bool(history.can_undo()).is_false()


func test_undo_restores_the_previous_value() -> void:
	var actions: Array = _add()

	(actions[0] as HenSaveAction).inputs[0].default_value = 1.0

	history.begin(save_data, state.id)
	(actions[0] as HenSaveAction).inputs[0].default_value = 2.0
	history.commit(save_data, 'Edit')

	assert_bool(history.undo(save_data)).is_true()
	assert_that(_first().inputs[0].default_value).is_equal(1.0)


func test_redo_puts_the_edit_back() -> void:
	var actions: Array = _add()

	(actions[0] as HenSaveAction).inputs[0].default_value = 1.0

	history.begin(save_data, state.id)
	(actions[0] as HenSaveAction).inputs[0].default_value = 2.0
	history.commit(save_data, 'Edit')
	history.undo(save_data)

	assert_bool(history.redo(save_data)).is_true()
	assert_that(_first().inputs[0].default_value).is_equal(2.0)


# the stack keeps the canonical copy: handing the live tree the stored objects
# would let the next edit rewrite the entry it came from
func test_undoing_twice_is_not_poisoned_by_the_first() -> void:
	var actions: Array = _add()

	(actions[0] as HenSaveAction).inputs[0].default_value = 1.0

	history.begin(save_data, state.id)
	(actions[0] as HenSaveAction).inputs[0].default_value = 2.0
	history.commit(save_data, 'Edit')

	history.undo(save_data)
	_first().inputs[0].default_value = 77.0
	history.redo(save_data)
	history.undo(save_data)

	assert_that(_first().inputs[0].default_value).is_equal(1.0)


func test_a_new_edit_drops_the_redo() -> void:
	var actions: Array = _add()

	history.begin(save_data, state.id)
	(actions[0] as HenSaveAction).inputs[0].default_value = 2.0
	history.commit(save_data, 'Edit')
	history.undo(save_data)

	assert_bool(history.can_redo()).is_true()

	history.begin(save_data, state.id)
	_first().inputs[0].default_value = 5.0
	history.commit(save_data, 'Edit')

	assert_bool(history.can_redo()).is_false()


func test_an_aborted_edit_leaves_no_entry() -> void:
	var actions: Array = _add()

	history.begin(save_data, state.id)
	(actions[0] as HenSaveAction).inputs[0].default_value = 3.0
	history.abort()

	assert_bool(history.commit(save_data, 'Edit')).is_false()
	assert_bool(history.can_undo()).is_false()


# an entry restores a list into the script it came from, so another script must
# not swallow it
func test_an_entry_from_another_script_is_refused() -> void:
	var actions: Array = _add()

	history.begin(save_data, state.id)
	(actions[0] as HenSaveAction).inputs[0].default_value = 2.0
	history.commit(save_data, 'Edit')

	var other: HenSaveData = HenSaveData.new()

	other.identity = HenSaveDataIdentity.create('other-id', 'Node', 'Other')

	assert_bool(history.undo(other)).is_false()
	assert_bool(history.can_undo()).is_true()


func test_removing_a_top_level_action() -> void:
	var actions: Array = _add(2)

	assert_bool(save_data.remove_action_anywhere(state.id, actions[0])).is_true()
	assert_int(save_data.get_state_actions(state.id).size()).is_equal(1)


func test_removing_an_action_from_a_loop_body() -> void:
	var actions: Array = _add()
	var inner: HenSaveAction = HenSaveAction.create(_macro())

	(actions[0] as HenSaveAction).body_actions.append(inner)

	assert_bool(save_data.remove_action_anywhere(state.id, inner)).is_true()
	assert_int((actions[0] as HenSaveAction).body_actions.size()).is_equal(0)
	assert_int(save_data.get_state_actions(state.id).size()).is_equal(1)


# a producer is bound to an input, so it is not in the state list at all
func test_removing_an_inline_producer() -> void:
	var actions: Array = _add()
	var owner: HenSaveAction = actions[0]
	var producer: HenSaveAction = HenSaveAction.create(_macro())
	var key: String = str(owner.inputs[0].id)

	owner.input_actions[key] = {action = producer, output = &'result'}

	assert_bool(save_data.remove_action_anywhere(state.id, producer)).is_true()
	assert_bool(owner.input_actions.has(key)).is_false()


func test_removing_a_producer_nested_in_another_producer() -> void:
	var actions: Array = _add()
	var owner: HenSaveAction = actions[0]
	var outer: HenSaveAction = HenSaveAction.create(_macro())
	var inner: HenSaveAction = HenSaveAction.create(_macro())

	owner.input_actions[str(owner.inputs[0].id)] = {action = outer, output = &'result'}
	outer.input_actions[str(outer.inputs[0].id)] = {action = inner, output = &'result'}

	assert_bool(save_data.remove_action_anywhere(state.id, inner)).is_true()
	assert_bool(outer.input_actions.is_empty()).is_true()
	assert_bool(owner.input_actions.is_empty()).is_false()


func test_removing_an_action_that_is_not_there() -> void:
	_add()

	assert_bool(save_data.remove_action_anywhere(state.id, HenSaveAction.create(_macro()))).is_false()


func test_delete_then_undo_brings_the_action_back() -> void:
	var actions: Array = _add(2)
	var target: HenSaveAction = actions[1]

	history.begin(save_data, state.id)
	save_data.remove_action_anywhere(state.id, target)
	history.commit(save_data, 'Delete Action')

	assert_int(save_data.get_state_actions(state.id).size()).is_equal(1)

	history.undo(save_data)

	assert_int(save_data.get_state_actions(state.id).size()).is_equal(2)
	assert_str(str(save_data.get_state_actions(state.id)[1].id)).is_equal(str(target.id))


func _viewer() -> HenFlowViewer:
	var viewer: HenFlowViewer = auto_free(
		(load('res://addons/hengo/scenes/flow_viewer.tscn') as PackedScene).instantiate()
	)

	add_child(viewer)
	viewer.rebuild()

	return viewer


func test_the_viewer_deletes_the_selected_action_and_undoes_it() -> void:
	var actions: Array = _add(2)
	var viewer: HenFlowViewer = _viewer()
	var card: Variant = viewer._cards_by_action.get(str((actions[1] as HenSaveAction).id))

	assert_object(card).is_not_null()

	viewer._select_card(card)

	assert_bool(viewer._delete_selected()).is_true()
	assert_int(save_data.get_state_actions(state.id).size()).is_equal(1)
	assert_str(viewer._selected_action).is_empty()

	assert_bool(viewer._undo()).is_true()
	assert_int(save_data.get_state_actions(state.id).size()).is_equal(2)


func test_the_viewer_refuses_to_delete_with_nothing_selected() -> void:
	_add()

	var viewer: HenFlowViewer = _viewer()

	assert_bool(viewer._delete_selected()).is_false()
	assert_bool(viewer._undo()).is_false()


func test_deleting_the_last_action_and_undoing_it() -> void:
	var actions: Array = _add()

	history.begin(save_data, state.id)
	save_data.remove_action_anywhere(state.id, actions[0])
	history.commit(save_data, 'Delete Action')

	assert_bool(save_data.state_actions.has(state.id)).is_false()

	history.undo(save_data)

	assert_int(save_data.get_state_actions(state.id).size()).is_equal(1)
