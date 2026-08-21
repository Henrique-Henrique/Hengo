@tool
class_name TestHenFlowSelection extends HenTestSuite


const FIX_MATH: String = 'res://addons/hengo/actions/math/math_operator.gd'

var state: HenSaveState


func before_test() -> void:
	super ()
	state = save_data.add_state(false)
	state.name = 'Play'


func _register(_path: String) -> HenSaveMacro:
	var instance: HenScriptMacroBase = (load(_path) as GDScript).new()
	var macro: HenSaveMacro = HenSaveMacro.new()

	macro.id = instance.get_id()
	macro.name = _path.get_file().get_basename()
	macro.is_script_macro = true
	macro.script_path = _path

	for input: Dictionary in instance.get_inputs():
		macro.inputs.append(HenSaveParam.create(input))

	for output: Dictionary in instance.get_outputs():
		macro.outputs.append(HenSaveParam.create(output))

	(Engine.get_singleton(&'Global') as HenGlobal).action_macros.append(macro)

	return macro


func _viewer(_count: int = 2) -> HenFlowViewer:
	var macro: HenSaveMacro = _register(FIX_MATH)

	for i: int in range(_count):
		var action: HenSaveAction = HenSaveAction.create(macro)

		action.phase = &'update'
		save_data.add_state_action(state.id, action)

	var viewer: HenFlowViewer = auto_free(
		(load('res://addons/hengo/scenes/flow_viewer.tscn') as PackedScene).instantiate()
	)

	add_child(viewer)
	viewer.rebuild()

	return viewer


func _action_cards(_viewer: HenFlowViewer) -> Array:
	var out: Array = []

	for entry: Variant in _viewer._states.values():
		for card: HenFlowNodeCard in entry.cards:
			if card.node.action:
				out.append(card)

	return out


func _entry_card(_viewer: HenFlowViewer) -> HenFlowNodeCard:
	for entry: Variant in _viewer._states.values():
		for card: HenFlowNodeCard in entry.cards:
			if card.node.kind == &'state_entry':
				return card

	return null


func test_a_card_gets_selected() -> void:
	var viewer: HenFlowViewer = _viewer()
	var cards: Array = _action_cards(viewer)

	assert_bool(cards.is_empty()).is_false()
	assert_bool((cards[0] as HenFlowNodeCard).is_selected()).is_false()

	viewer._select_card(cards[0])

	assert_bool((cards[0] as HenFlowNodeCard).is_selected()).is_true()


func test_only_one_card_is_selected_at_a_time() -> void:
	var viewer: HenFlowViewer = _viewer()
	var cards: Array = _action_cards(viewer)

	assert_int(cards.size()).is_greater_equal(2)

	viewer._select_card(cards[0])
	viewer._select_card(cards[1])

	assert_bool((cards[0] as HenFlowNodeCard).is_selected()).is_false()
	assert_bool((cards[1] as HenFlowNodeCard).is_selected()).is_true()


# a card with no action is the state entry, which is not something to act on
func test_a_card_without_an_action_clears_the_selection() -> void:
	var viewer: HenFlowViewer = _viewer()
	var cards: Array = _action_cards(viewer)
	var entry: HenFlowNodeCard = _entry_card(viewer)

	assert_object(entry).is_not_null()

	viewer._select_card(cards[0])
	viewer._select_card(entry)

	assert_bool((cards[0] as HenFlowNodeCard).is_selected()).is_false()
	assert_array(viewer._selected_actions).is_empty()


func test_clearing_deselects_the_card() -> void:
	var viewer: HenFlowViewer = _viewer()
	var cards: Array = _action_cards(viewer)

	viewer._select_card(cards[0])
	viewer._clear_selection()

	assert_bool((cards[0] as HenFlowNodeCard).is_selected()).is_false()


# a rebuild frees every card, so a selection kept on the card object would die
# with it, the same way the debug flash would
func test_the_selection_survives_a_rebuild() -> void:
	var viewer: HenFlowViewer = _viewer()
	var id: String = str((_action_cards(viewer)[0] as HenFlowNodeCard).node.action.id)

	viewer._select_card(_action_cards(viewer)[0])
	viewer.rebuild()

	var selected: Array = _action_cards(viewer).filter(func(c): return c.is_selected())

	assert_int(selected.size()).is_equal(1)
	assert_str(str((selected[0] as HenFlowNodeCard).node.action.id)).is_equal(id)


func test_an_action_that_is_gone_drops_the_selection() -> void:
	var viewer: HenFlowViewer = _viewer()
	var card: HenFlowNodeCard = _action_cards(viewer)[0]

	viewer._select_card(card)
	save_data.remove_state_action(state.id, card.node.action)
	viewer.rebuild()

	assert_array(viewer._selected_actions).is_empty()
	assert_int(_action_cards(viewer).filter(func(c): return c.is_selected()).size()).is_equal(0)


func test_selected_action_returns_the_resource() -> void:
	var viewer: HenFlowViewer = _viewer()
	var card: HenFlowNodeCard = _action_cards(viewer)[0]

	assert_object(viewer.selected_action()).is_null()

	viewer._select_card(card)

	assert_object(viewer.selected_action()).is_same(card.node.action)


func _key(_code: Key, _ctrl: bool = false) -> InputEventKey:
	var event: InputEventKey = InputEventKey.new()

	event.keycode = _code
	event.pressed = true
	event.ctrl_pressed = _ctrl

	return event


# alt+up is the editor's own move-line shortcut, and the editor is bound above
# the unhandled layer, so it won every other time
func test_the_move_keys_are_w_and_s() -> void:
	var viewer: HenFlowViewer = _viewer()

	assert_bool(viewer._handle_shortcut(_key(KEY_UP))).is_false()
	assert_bool(viewer._handle_shortcut(_key(KEY_DOWN))).is_false()


# ctrl+s is save, and swallowing it here would cost the user the file
func test_a_modifier_gives_the_key_back() -> void:
	var viewer: HenFlowViewer = _viewer()

	assert_bool(viewer._handle_shortcut(_key(KEY_S, true))).is_false()
	assert_bool(viewer._handle_shortcut(_key(KEY_W, true))).is_false()


func test_a_move_key_does_nothing_with_no_selection() -> void:
	var viewer: HenFlowViewer = _viewer()

	assert_bool(viewer._handle_shortcut(_key(KEY_S))).is_false()
	assert_bool(viewer._handle_shortcut(_key(KEY_W))).is_false()


# the help popup and the handler read the same list, so a binding cannot be in
# one and missing from the other
func test_every_flow_key_in_the_registry_is_handled() -> void:
	var viewer: HenFlowViewer = _viewer()
	var cards: Array = _action_cards(viewer)

	viewer._select_card(cards[0])

	for entry: Dictionary in HenShortcuts.of_group(HenShortcuts.FLOW):
		if not entry.has('method'):
			continue

		assert_bool(viewer.has_method(str(entry.method))).override_failure_message(
			'no method for ' + str(entry.title)
		).is_true()


func test_the_registry_declares_the_move_keys() -> void:
	var found: Array = []

	for entry: Dictionary in HenShortcuts.of_group(HenShortcuts.FLOW):
		found.append(''.join(entry.combo))

	assert_array(found).contains(['W', 'S', 'Delete'])


func test_every_entry_is_readable() -> void:
	for entry: Dictionary in HenShortcuts.LIST:
		assert_bool((entry.combo as Array).is_empty()).is_false()
		assert_str(str(entry.title)).is_not_empty()
		assert_str(str(entry.description)).is_not_empty()
		assert_str(HenShortcuts.group_name(entry.group)).is_not_empty()


const FIX_IF: String = 'res://addons/hengo/actions/flow/if_condition.gd'


func _register_flow(_path: String) -> HenSaveMacro:
	var instance: HenScriptMacroBase = (load(_path) as GDScript).new()
	var macro: HenSaveMacro = _register(_path)

	for flow_output: Dictionary in instance.get_flow_outputs():
		macro.flow_outputs.append(HenSaveFlowParam.create(flow_output))

	return macro


# clicking a branch cell that already had a target panned the camera to it, so a
# branch could be set once and never changed again. the transition card the
# builder draws beside it is what takes the reader to the target
func test_a_branch_cell_opens_the_editor_even_when_it_has_a_target() -> void:
	var target: HenSaveState = save_data.add_state(false)
	target.name = 'Hit'

	var action: HenSaveAction = HenSaveAction.create(_register_flow(FIX_IF))

	action.phase = &'update'
	save_data.add_state_action(state.id, action)
	action.branches['true'] = {state_id = target.id, label = ''}

	var viewer: HenFlowViewer = auto_free(
		(load('res://addons/hengo/scenes/flow_viewer.tscn') as PackedScene).instantiate()
	)

	add_child(viewer)
	viewer.rebuild()

	viewer._rebuild_hover_cache()

	var card: HenFlowNodeCard = null

	for entry: Variant in viewer._states.values():
		for candidate: HenFlowNodeCard in entry.cards:
			if candidate.node.action == action:
				card = candidate

	assert_object(card).is_not_null()

	var origin: Vector2 = Vector2.INF

	for item: Dictionary in viewer._hover_items:
		if item.get('card') == card:
			origin = (item.rect as Rect2).position

	assert_bool(origin.is_finite()).is_true()

	var cell: Dictionary = {}

	for hit: Dictionary in card.get_hits():
		if hit.kind == &'exec_out':
			cell = hit
			break

	assert_bool(cell.is_empty()).is_false()

	# the real path: the point under the cursor resolves to the cell, and the cell
	# decides between the editor and the camera
	var resolved: Dictionary = viewer.hit_at(origin + (cell.rect as Rect2).get_center())

	assert_str(str(resolved.get('kind', ''))).is_equal('exec_out')
	assert_bool(viewer._dispatch_hit(resolved)).is_true()
	assert_bool(viewer._editor.is_editing).is_true()

	await _drop_inspector()


# with no UI base the popup singleton refuses to host, so edit_branch instantiates
# an inspector that is never parented and the runner counts every node of it
func _drop_inspector() -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')

	if is_instance_valid(global.CURRENT_INSPECTOR):
		global.CURRENT_INSPECTOR.free()
		global.CURRENT_INSPECTOR = null

	# make_flat queue_frees the scroll it unparents, which lands a frame later
	await await_idle_frame()


func _cards_of(_viewer: HenFlowViewer, _actions: Array) -> Array:
	var out: Array = []

	for action: Variant in _actions:
		out.append(_viewer._cards_by_action.get(str(action.node.action.id if action is HenFlowNodeCard else action.id)))

	return out


func test_ctrl_click_grows_and_shrinks_the_selection() -> void:
	var viewer: HenFlowViewer = _viewer()
	var cards: Array = _action_cards(viewer)

	viewer._select_card(cards[0])
	viewer._toggle_card(cards[1])

	assert_int(viewer._selected_actions.size()).is_equal(2)
	assert_bool((cards[1] as HenFlowNodeCard).is_selected()).is_true()

	viewer._toggle_card(cards[1])

	assert_int(viewer._selected_actions.size()).is_equal(1)
	assert_bool((cards[1] as HenFlowNodeCard).is_selected()).is_false()


# the range runs along the chain, not the flat list: two steps of different
# phases are never neighbours in the graph
func test_shift_click_takes_the_range_of_the_chain() -> void:
	var viewer: HenFlowViewer = _viewer(3)
	var cards: Array = _action_cards(viewer)

	viewer._select_card(cards[0])
	viewer._select_range_to(cards[2])

	assert_int(viewer._selected_actions.size()).is_equal(3)


func test_a_range_across_phases_falls_back_to_a_single_pick() -> void:
	var viewer: HenFlowViewer = _viewer(2)
	var cards: Array = _action_cards(viewer)

	(cards[1] as HenFlowNodeCard).node.action.phase = &'enter'

	viewer._select_card(cards[0])
	viewer._select_range_to(cards[1])

	assert_int(viewer._selected_actions.size()).is_equal(1)


func test_the_whole_selection_survives_a_rebuild() -> void:
	var viewer: HenFlowViewer = _viewer(3)
	var cards: Array = _action_cards(viewer)

	viewer._select_card(cards[0])
	viewer._toggle_card(cards[2])
	viewer.rebuild()

	assert_int(_action_cards(viewer).filter(func(c): return c.is_selected()).size()).is_equal(2)


# one entry for the batch: record is re-entrant, so a delete of N steps costs one
# ctrl+z and not N
func test_deleting_a_batch_is_one_undo() -> void:
	var viewer: HenFlowViewer = _viewer(3)
	var cards: Array = _action_cards(viewer)

	viewer._select_card(cards[0])
	viewer._toggle_card(cards[1])

	assert_bool(viewer._delete_selected()).is_true()
	assert_int(save_data.get_state_actions(state.id).size()).is_equal(1)

	assert_bool(viewer._undo()).is_true()
	assert_int(save_data.get_state_actions(state.id).size()).is_equal(3)
	assert_bool(viewer._undo()).is_false()


func test_duplicating_a_batch_is_one_undo() -> void:
	var viewer: HenFlowViewer = _viewer(2)
	var cards: Array = _action_cards(viewer)

	viewer._select_card(cards[0])
	viewer._toggle_card(cards[1])

	assert_bool(viewer._duplicate_selected()).is_true()
	assert_int(save_data.get_state_actions(state.id).size()).is_equal(4)

	assert_bool(viewer._undo()).is_true()
	assert_int(save_data.get_state_actions(state.id).size()).is_equal(2)
	assert_bool(viewer._undo()).is_false()


# moving a batch has to preserve the relative order of the moved steps, which is
# a different operation from swapping with a neighbour
func test_moving_refuses_a_batch() -> void:
	var viewer: HenFlowViewer = _viewer(3)
	var cards: Array = _action_cards(viewer)

	viewer._select_card(cards[0])
	viewer._toggle_card(cards[1])

	assert_bool(viewer._move_selected(1)).is_false()


func test_ctrl_a_takes_the_chain() -> void:
	var viewer: HenFlowViewer = _viewer(3)

	viewer._select_card(_action_cards(viewer)[1])

	assert_bool(viewer._select_chain_shortcut()).is_true()
	assert_int(viewer._selected_actions.size()).is_equal(3)


# the modifier comes from the event and not from the global Input state, so the
# dispatch branch is reachable in a test at all
func test_the_click_dispatch_honours_the_modifiers() -> void:
	var viewer: HenFlowViewer = _viewer(3)
	var cards: Array = _action_cards(viewer)

	viewer._click_select(cards[0], false, false)
	viewer._click_select(cards[1], true, false)

	assert_int(viewer._selected_actions.size()).is_equal(2)

	viewer._click_select(cards[2], false, true)

	assert_int(viewer._selected_actions.size()).is_equal(2)

	viewer._click_select(cards[0], false, false)

	assert_int(viewer._selected_actions.size()).is_equal(1)
