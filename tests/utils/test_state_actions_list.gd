@tool
class_name TestHenStateActionsList extends HenTestSuite


const LIST_SCENE = preload('res://addons/hengo/scenes/state_actions_list.tscn')
const FIX_PHASES: String = 'res://tests/fixtures/action_phases.gd'

var state: HenSaveState
var macro: HenSaveMacro


func before_test() -> void:
	super ()
	state = save_data.add_state(false)
	state.name = 'state test'
	macro = _register(FIX_PHASES)


# mirrors HenScriptMacroLoader._load_macro_script
func _register(_path: String) -> HenSaveMacro:
	var instance: HenScriptMacroBase = (load(_path) as GDScript).new()
	var result: HenSaveMacro = HenSaveMacro.new()

	result.id = instance.get_id()
	result.name = _path.get_file().get_basename()
	result.is_script_macro = true
	result.script_path = _path

	for input: Dictionary in instance.get_inputs():
		result.inputs.append(HenSaveParam.create(input))

	for flow: Dictionary in instance.get_flow_inputs():
		result.flow_inputs.append(HenSaveFlowParam.create(flow))

	(Engine.get_singleton(&'Global') as HenGlobal).action_macros.append(result)
	return result


func _add_action(_phase: StringName) -> HenSaveAction:
	var action: HenSaveAction = HenSaveAction.create(macro)
	action.phase = _phase
	save_data.add_state_action(state.id, action)
	return action


# the rows only build once the scene is in a tree, so _ready has cached %List
func _build_list() -> HenStateActionsList:
	var actions_list: HenStateActionsList = auto_free(LIST_SCENE.instantiate())
	add_child(actions_list)
	actions_list.setup(save_data, state.id)
	return actions_list


func _count_of(_list: HenStateActionsList, _type: Variant) -> int:
	var count: int = 0

	for child: Node in _list.list.get_children():
		if is_instance_of(child, _type):
			count += 1

	return count


func test_headers_only_for_phases_with_actions() -> void:
	_add_action(&'enter')
	_add_action(&'update')
	_add_action(&'update')

	var actions_list: HenStateActionsList = _build_list()

	assert_int(_count_of(actions_list, HenActionRow)).is_equal(3)
	assert_int(_count_of(actions_list, HenActionPhaseHeader)).is_equal(2)


func test_width_is_fixed_only_once_there_are_rows() -> void:
	var actions_list: HenStateActionsList = _build_list()

	assert_float(actions_list.custom_minimum_size.x).is_equal(0.0)

	_add_action(&'update')
	actions_list.refresh()

	assert_float(actions_list.custom_minimum_size.x).is_equal(HenStateActionsList.CONTENT_WIDTH)


# the measurer reads the panel min size, so a list-only minimum would not size the card
func test_rows_grow_the_hosting_panel_min_size() -> void:
	var panel := PanelContainer.new()
	add_child(auto_free(panel))

	var actions_list: HenStateActionsList = LIST_SCENE.instantiate()
	panel.add_child(actions_list)
	actions_list.setup(save_data, state.id)

	var empty_size: Vector2 = panel.get_combined_minimum_size()

	_add_action(&'update')
	_add_action(&'enter')
	actions_list.refresh()

	var filled_size: Vector2 = panel.get_combined_minimum_size()

	assert_float(filled_size.x).is_greater(empty_size.x)
	assert_float(filled_size.y).is_greater(empty_size.y)


func test_flash_only_takes_its_own_action_id() -> void:
	var action: HenSaveAction = _add_action(&'update')
	var actions_list: HenStateActionsList = _build_list()

	assert_bool(actions_list.flash_action(action.id)).is_true()
	assert_bool(actions_list.flash_action(&'no_such_action')).is_false()


# a container recomputes its minimum size only during the layout pass
func test_unfolding_a_row_only_measures_a_pass_later() -> void:
	_add_action(&'update')

	var panel: PanelContainer = auto_free(PanelContainer.new())
	add_child(panel)

	var actions_list: HenStateActionsList = LIST_SCENE.instantiate()
	panel.add_child(actions_list)
	actions_list.setup(save_data, state.id)

	await get_tree().process_frame
	await get_tree().process_frame

	var folded: float = panel.get_combined_minimum_size().y
	var row: HenActionRow = actions_list._rows_by_id.values()[0]

	row.set_collapsed(false)

	assert_float(panel.get_combined_minimum_size().y).is_equal(folded)

	await get_tree().process_frame
	await get_tree().process_frame

	assert_float(panel.get_combined_minimum_size().y).is_greater(folded)


# the graph rebuilds every card on any structural change
func test_fold_state_survives_a_rebuilt_list() -> void:
	var action: HenSaveAction = _add_action(&'update')

	_build_list()._on_row_collapse_toggled(action, false)

	var rebuilt: HenStateActionsList = _build_list()
	var row: HenActionRow = rebuilt._rows_by_id[str(action.id)]

	assert_bool(row._collapsed).is_false()


func test_delete_removes_the_action_and_its_row() -> void:
	var keep: HenSaveAction = _add_action(&'update')
	var drop: HenSaveAction = _add_action(&'update')
	var actions_list: HenStateActionsList = _build_list()

	actions_list._delete_action(drop)

	var left: Array = save_data.get_state_actions(state.id)

	assert_int(left.size()).is_equal(1)
	assert_bool(left.has(keep)).is_true()
	assert_int(_count_of(actions_list, HenActionRow)).is_equal(1)
