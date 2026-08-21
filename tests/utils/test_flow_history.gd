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

	history.begin(save_data, [state.id])
	(actions[0] as HenSaveAction).inputs[0].default_value = 9.0

	assert_bool(history.commit(save_data, 'Edit')).is_true()
	assert_bool(history.can_undo()).is_true()


# a popup opened and closed with no edit would otherwise cost a ctrl+z that does nothing
func test_an_untouched_list_is_not_pushed() -> void:
	_add()

	history.begin(save_data, [state.id])

	assert_bool(history.commit(save_data, 'Edit')).is_false()
	assert_bool(history.can_undo()).is_false()


func test_undo_restores_the_previous_value() -> void:
	var actions: Array = _add()

	(actions[0] as HenSaveAction).inputs[0].default_value = 1.0

	history.begin(save_data, [state.id])
	(actions[0] as HenSaveAction).inputs[0].default_value = 2.0
	history.commit(save_data, 'Edit')

	assert_bool(history.undo(save_data)).is_true()
	assert_that(_first().inputs[0].default_value).is_equal(1.0)


func test_redo_puts_the_edit_back() -> void:
	var actions: Array = _add()

	(actions[0] as HenSaveAction).inputs[0].default_value = 1.0

	history.begin(save_data, [state.id])
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

	history.begin(save_data, [state.id])
	(actions[0] as HenSaveAction).inputs[0].default_value = 2.0
	history.commit(save_data, 'Edit')

	history.undo(save_data)
	_first().inputs[0].default_value = 77.0
	history.redo(save_data)
	history.undo(save_data)

	assert_that(_first().inputs[0].default_value).is_equal(1.0)


func test_a_new_edit_drops_the_redo() -> void:
	var actions: Array = _add()

	history.begin(save_data, [state.id])
	(actions[0] as HenSaveAction).inputs[0].default_value = 2.0
	history.commit(save_data, 'Edit')
	history.undo(save_data)

	assert_bool(history.can_redo()).is_true()

	history.begin(save_data, [state.id])
	_first().inputs[0].default_value = 5.0
	history.commit(save_data, 'Edit')

	assert_bool(history.can_redo()).is_false()


func test_an_aborted_edit_leaves_no_entry() -> void:
	var actions: Array = _add()

	history.begin(save_data, [state.id])
	(actions[0] as HenSaveAction).inputs[0].default_value = 3.0
	history.abort()

	assert_bool(history.commit(save_data, 'Edit')).is_false()
	assert_bool(history.can_undo()).is_false()


# an entry restores a list into the script it came from, so another script must
# not swallow it
func test_an_entry_from_another_script_is_refused() -> void:
	var actions: Array = _add()

	history.begin(save_data, [state.id])
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

	history.begin(save_data, [state.id])
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
	assert_array(viewer._selected_actions).is_empty()

	assert_bool(viewer._undo()).is_true()
	assert_int(save_data.get_state_actions(state.id).size()).is_equal(2)


func test_the_viewer_refuses_to_delete_with_nothing_selected() -> void:
	_add()

	var viewer: HenFlowViewer = _viewer()

	assert_bool(viewer._delete_selected()).is_false()
	assert_bool(viewer._undo()).is_false()


func test_deleting_the_last_action_and_undoing_it() -> void:
	var actions: Array = _add()

	history.begin(save_data, [state.id])
	save_data.remove_action_anywhere(state.id, actions[0])
	history.commit(save_data, 'Delete Action')

	assert_bool(save_data.state_actions.has(state.id)).is_false()

	history.undo(save_data)

	assert_int(save_data.get_state_actions(state.id).size()).is_equal(1)


# duplicate(true) keeps every id, and the action id is what the card index, the
# debug flash and the selection address a node by
func test_a_duplicated_action_gets_a_new_id() -> void:
	var actions: Array = _add()
	var copy: HenSaveAction = HenActionsPanel.duplicate_action(actions[0])

	assert_str(str(copy.id)).is_not_equal(str((actions[0] as HenSaveAction).id))


# the param ids are the macro's own names, and the bindings are keyed by them
func test_a_duplicated_action_keeps_its_param_ids() -> void:
	var actions: Array = _add()
	var source: HenSaveAction = actions[0]

	source.input_bindings[str(source.inputs[0].id)] = 'some_var'

	var copy: HenSaveAction = HenActionsPanel.duplicate_action(source)

	assert_str(str(copy.inputs[0].id)).is_equal(str(source.inputs[0].id))
	assert_bool(copy.input_bindings.has(str(copy.inputs[0].id))).is_true()


func test_a_duplicated_producer_and_body_get_new_ids_too() -> void:
	var actions: Array = _add()
	var source: HenSaveAction = actions[0]
	var producer: HenSaveAction = HenSaveAction.create(_macro())
	var inner: HenSaveAction = HenSaveAction.create(_macro())

	source.input_actions[str(source.inputs[0].id)] = {action = producer, output = &'result'}
	source.body_actions.append(inner)

	var copy: HenSaveAction = HenActionsPanel.duplicate_action(source)

	assert_str(str(copy.input_actions[str(copy.inputs[0].id)].action.id)).is_not_equal(str(producer.id))
	assert_str(str(copy.body_actions[0].id)).is_not_equal(str(inner.id))


# the phase change used to write a method pair into global.history as well
func test_changing_the_phase_is_undone_by_the_flow_stack() -> void:
	var actions: Array = _add()
	var action: HenSaveAction = actions[0]
	var editor: HenStateViewerCardEditor = HenStateViewerCardEditor.new()

	editor.target(save_data, state.id)
	action.phase = &'update'

	history.begin(save_data, [state.id])
	editor.move_action(action, &'enter', -1)
	history.commit(save_data, 'Move Action')

	assert_str(str(save_data.get_state_actions(state.id)[0].phase)).is_equal('enter')

	history.undo(save_data)

	assert_str(str(save_data.get_state_actions(state.id)[0].phase)).is_equal('update')


func _editor() -> HenStateViewerCardEditor:
	var editor: HenStateViewerCardEditor = HenStateViewerCardEditor.new()

	editor.target(save_data, state.id)

	return editor


func test_moving_a_step_down_its_chain() -> void:
	var actions: Array = _add(3)
	var editor: HenStateViewerCardEditor = _editor()

	assert_bool(editor.move_in_chain(actions[0], 1)).is_true()
	assert_str(str(save_data.get_state_actions(state.id)[1].id)).is_equal(str((actions[0] as HenSaveAction).id))


func test_the_ends_of_the_chain_do_not_move() -> void:
	var actions: Array = _add(2)
	var editor: HenStateViewerCardEditor = _editor()

	assert_bool(editor.move_in_chain(actions[0], -1)).is_false()
	assert_bool(editor.move_in_chain(actions[1], 1)).is_false()


# the chain is per phase: a step never jumps over one that runs somewhere else
func test_a_step_only_moves_inside_its_own_phase() -> void:
	var actions: Array = _add(2)
	var editor: HenStateViewerCardEditor = _editor()

	(actions[0] as HenSaveAction).phase = &'enter'

	assert_bool(editor.move_in_chain(actions[0], 1)).is_false()
	assert_bool(editor.move_in_chain(actions[1], -1)).is_false()


# a loop body is its own list, and its order is not grouped by phase
func test_moving_a_step_inside_a_loop_body() -> void:
	var actions: Array = _add()
	var parent: HenSaveAction = actions[0]
	var first: HenSaveAction = HenSaveAction.create(_macro())
	var second: HenSaveAction = HenSaveAction.create(_macro())

	parent.body_actions.append(first)
	parent.body_actions.append(second)

	assert_bool(_editor().move_in_chain(first, 1)).is_true()
	assert_str(str(parent.body_actions[0].id)).is_equal(str(second.id))


func test_the_viewer_moves_the_selected_step_and_undoes_it() -> void:
	var actions: Array = _add(2)
	var viewer: HenFlowViewer = _viewer()
	var first: HenSaveAction = actions[0]

	viewer._select_card(viewer._cards_by_action.get(str(first.id)))

	assert_bool(viewer._move_selected(1)).is_true()
	assert_str(str(save_data.get_state_actions(state.id)[1].id)).is_equal(str(first.id))

	assert_bool(viewer._undo()).is_true()
	assert_str(str(save_data.get_state_actions(state.id)[0].id)).is_equal(str(first.id))


# dropping on a card and not on a wire: the halves say before or after, and
# HenActionsPanel.drop_index was already there from the old sidebar drag
func test_dropping_below_a_card_moves_the_step_after_it() -> void:
	var actions: Array = _add(3)
	var viewer: HenFlowViewer = _viewer()

	assert_bool(viewer._apply_drop(actions[0], actions[2], false)).is_true()
	assert_str(str(save_data.get_state_actions(state.id)[2].id)).is_equal(str((actions[0] as HenSaveAction).id))


func test_dropping_above_a_card_moves_the_step_before_it() -> void:
	var actions: Array = _add(3)
	var viewer: HenFlowViewer = _viewer()

	assert_bool(viewer._apply_drop(actions[2], actions[0], true)).is_true()
	assert_str(str(save_data.get_state_actions(state.id)[0].id)).is_equal(str((actions[2] as HenSaveAction).id))


# dropping on another phase is a phase change, which the drop index already knows
func test_dropping_onto_another_phase_moves_the_step_there() -> void:
	var actions: Array = _add(2)

	(actions[1] as HenSaveAction).phase = &'enter'

	var viewer: HenFlowViewer = _viewer()

	assert_bool(viewer._apply_drop(actions[0], actions[1], true)).is_true()
	assert_str(str((actions[0] as HenSaveAction).phase)).is_equal('enter')


func test_a_drop_is_undone_in_one_step() -> void:
	var actions: Array = _add(3)
	var viewer: HenFlowViewer = _viewer()

	viewer._apply_drop(actions[0], actions[2], false)

	assert_bool(viewer._undo()).is_true()
	assert_str(str(save_data.get_state_actions(state.id)[0].id)).is_equal(str((actions[0] as HenSaveAction).id))


func _second_state() -> HenSaveState:
	var other: HenSaveState = save_data.add_state(false)

	other.name = 'Idle'

	return other


# the indicator showed on a card of another state but the drop was refused
func test_dropping_onto_another_state_moves_the_step_there() -> void:
	var actions: Array = _add(2)
	var other: HenSaveState = _second_state()
	var landing: HenSaveAction = HenSaveAction.create(_macro())

	landing.phase = &'update'
	save_data.add_state_action(other.id, landing)

	var viewer: HenFlowViewer = _viewer()

	assert_bool(viewer._apply_drop(actions[0], landing, true)).is_true()
	assert_int(save_data.get_state_actions(state.id).size()).is_equal(1)
	assert_int(save_data.get_state_actions(other.id).size()).is_equal(2)
	assert_str(str(save_data.get_state_actions(other.id)[0].id)).is_equal(str((actions[0] as HenSaveAction).id))


# two lists change, and an entry that restores one of them leaves a copy behind
func test_a_cross_state_drop_is_undone_on_both_sides() -> void:
	var actions: Array = _add(2)
	var other: HenSaveState = _second_state()
	var landing: HenSaveAction = HenSaveAction.create(_macro())

	landing.phase = &'update'
	save_data.add_state_action(other.id, landing)

	var viewer: HenFlowViewer = _viewer()

	viewer._apply_drop(actions[0], landing, true)

	assert_bool(viewer._undo()).is_true()
	assert_int(save_data.get_state_actions(state.id).size()).is_equal(2)
	assert_int(save_data.get_state_actions(other.id).size()).is_equal(1)


func test_ctrl_d_duplicates_the_selected_action() -> void:
	var actions: Array = _add(1)
	var viewer: HenFlowViewer = _viewer()

	viewer._select_card(viewer._cards_by_action.get(str((actions[0] as HenSaveAction).id)))

	assert_bool(viewer._duplicate_selected()).is_true()
	assert_int(save_data.get_state_actions(state.id).size()).is_equal(2)

	var copy: HenSaveAction = save_data.get_state_actions(state.id)[1]

	assert_str(str(copy.id)).is_not_equal(str((actions[0] as HenSaveAction).id))

	assert_bool(viewer._undo()).is_true()
	assert_int(save_data.get_state_actions(state.id).size()).is_equal(1)


func test_a_new_action_lands_on_the_chain_it_was_added_from() -> void:
	var actions: Array = _add(2)
	var editor: HenStateViewerCardEditor = _editor()

	(actions[0] as HenSaveAction).phase = &'enter'

	editor._insert_new(_macro(), state.id, null, &'update', -1)

	var list: Array = save_data.get_state_actions(state.id)
	var added: HenSaveAction = list[list.size() - 1]

	assert_str(str(added.phase)).is_equal('update')


# only actions with a body for the clicked phase are offered, so the picker can
# never relocate the new step to another chain
func test_the_phase_pool_only_offers_what_runs_there() -> void:
	for macro: HenSaveMacro in HenActionPool.for_phase(&'physics'):
		assert_bool(HenSaveAction.supported_phases(macro).has(&'physics')).is_true()


func test_a_tail_add_lands_at_the_end_of_its_chain() -> void:
	var actions: Array = _add(2)
	var editor: HenStateViewerCardEditor = _editor()

	editor._insert_new(_macro(), state.id, null, &'update', -1)

	var list: Array = save_data.get_state_actions(state.id)

	assert_str(str(list[2].id)).is_not_equal(str((actions[0] as HenSaveAction).id))
	assert_int(list.size()).is_equal(3)


# a popup that closed without committing used to leave _pending behind, and the
# next delete or move silently recorded the wrong `before`
func test_a_leftover_popup_snapshot_does_not_poison_a_delete() -> void:
	var actions: Array = _add(2)
	var viewer: HenFlowViewer = _viewer()

	# the popup path opens a snapshot and never commits it
	viewer._history.begin(save_data, [state.id])
	(actions[0] as HenSaveAction).inputs[0].default_value = 99.0

	viewer._select_card(viewer._cards_by_action.get(str((actions[1] as HenSaveAction).id)))

	assert_bool(viewer._delete_selected()).is_true()
	assert_int(save_data.get_state_actions(state.id).size()).is_equal(1)

	assert_bool(viewer._undo()).is_true()
	assert_int(save_data.get_state_actions(state.id).size()).is_equal(2)
	# the stale edit must not ride along on the delete's undo
	assert_that(save_data.get_state_actions(state.id)[0].inputs[0].default_value).is_equal(99.0)


func test_two_deletes_in_a_row_each_undo() -> void:
	var actions: Array = _add(3)
	var viewer: HenFlowViewer = _viewer()

	viewer._select_card(viewer._cards_by_action.get(str((actions[2] as HenSaveAction).id)))
	viewer._delete_selected()
	viewer._select_card(viewer._cards_by_action.get(str((actions[1] as HenSaveAction).id)))
	viewer._delete_selected()

	assert_int(save_data.get_state_actions(state.id).size()).is_equal(1)

	viewer._undo()

	assert_int(save_data.get_state_actions(state.id).size()).is_equal(2)

	viewer._undo()

	assert_int(save_data.get_state_actions(state.id).size()).is_equal(3)


# the menu runs its callbacks deferred, after the popup boundary closed, so the
# delete used to mutate with no snapshot and leave the card on screen
func test_the_menu_delete_records_and_rebuilds() -> void:
	var actions: Array = _add(2)
	var viewer: HenFlowViewer = _viewer()

	viewer._ensure_editor()
	viewer._editor.target(save_data, state.id)
	viewer._editor.delete_action(actions[0])

	assert_int(save_data.get_state_actions(state.id).size()).is_equal(1)
	assert_bool(viewer._history.can_undo()).is_true()

	viewer._undo()

	assert_int(save_data.get_state_actions(state.id).size()).is_equal(2)


func test_the_menu_duplicate_and_toggle_are_recorded() -> void:
	var actions: Array = _add(1)
	var viewer: HenFlowViewer = _viewer()

	viewer._ensure_editor()
	viewer._editor.target(save_data, state.id)

	viewer._editor.duplicate_action(actions[0])

	assert_int(save_data.get_state_actions(state.id).size()).is_equal(2)

	viewer._undo()

	assert_int(save_data.get_state_actions(state.id).size()).is_equal(1)

	viewer._editor._toggle_disabled(actions[0])

	assert_bool((actions[0] as HenSaveAction).disabled).is_true()

	viewer._undo()

	assert_bool(save_data.get_state_actions(state.id)[0].disabled).is_false()


# the shortcut and the menu are one implementation now, and a record inside a
# record must not push a second entry: that would cost two ctrl+z for one edit
func test_one_edit_is_one_undo_whichever_path_ran() -> void:
	var actions: Array = _add(2)
	var viewer: HenFlowViewer = _viewer()

	viewer._select_card(viewer._cards_by_action.get(str((actions[0] as HenSaveAction).id)))

	assert_bool(viewer._duplicate_selected()).is_true()
	assert_int(save_data.get_state_actions(state.id).size()).is_equal(3)

	assert_bool(viewer._undo()).is_true()
	assert_int(save_data.get_state_actions(state.id).size()).is_equal(2)
	assert_bool(viewer._undo()).is_false()


func test_the_shortcut_move_is_one_undo_too() -> void:
	var actions: Array = _add(3)
	var viewer: HenFlowViewer = _viewer()

	viewer._select_card(viewer._cards_by_action.get(str((actions[0] as HenSaveAction).id)))

	assert_bool(viewer._move_selected(1)).is_true()
	assert_bool(viewer._undo()).is_true()
	assert_str(str(save_data.get_state_actions(state.id)[0].id)).is_equal(str((actions[0] as HenSaveAction).id))
	assert_bool(viewer._undo()).is_false()


# replace is now insert + remove in one entry, not a second copy of the insert
func test_replacing_a_step_is_one_undo() -> void:
	var actions: Array = _add(2)
	var editor: HenStateViewerCardEditor = _editor()
	var old_id: String = str((actions[0] as HenSaveAction).id)

	editor._insert_new(_macro(), state.id, null, &'update', 0, actions[0])

	var list: Array = save_data.get_state_actions(state.id)

	assert_int(list.size()).is_equal(2)
	assert_str(str(list[0].id)).is_not_equal(old_id)


# one move covers both cases, so the phase rule is not written twice
func test_move_step_handles_both_the_same_state_and_another() -> void:
	var actions: Array = _add(2)
	var other: HenSaveState = save_data.add_state(false)
	var landing: HenSaveAction = HenSaveAction.create(_macro())

	other.name = 'Idle'
	landing.phase = &'update'
	save_data.add_state_action(other.id, landing)

	var editor: HenStateViewerCardEditor = _editor()

	assert_bool(editor.move_step(actions[0], actions[1], 1, state.id, state.id)).is_true()
	assert_str(str(save_data.get_state_actions(state.id)[1].id)).is_equal(str((actions[0] as HenSaveAction).id))

	assert_bool(editor.move_step(actions[0], landing, 0, state.id, other.id)).is_true()
	assert_int(save_data.get_state_actions(state.id).size()).is_equal(1)
	assert_int(save_data.get_state_actions(other.id).size()).is_equal(2)
