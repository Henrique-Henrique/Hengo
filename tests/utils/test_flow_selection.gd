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
			if not card.node.action:
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
	assert_str(viewer._selected_action).is_empty()


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

	assert_str(viewer._selected_action).is_empty()
	assert_int(_action_cards(viewer).filter(func(c): return c.is_selected()).size()).is_equal(0)


func test_selected_action_returns_the_resource() -> void:
	var viewer: HenFlowViewer = _viewer()
	var card: HenFlowNodeCard = _action_cards(viewer)[0]

	assert_object(viewer.selected_action()).is_null()

	viewer._select_card(card)

	assert_object(viewer.selected_action()).is_same(card.node.action)
