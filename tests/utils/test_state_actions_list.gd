@tool
class_name TestHenStateActionsList extends HenTestSuite


const LIST_SCENE = preload('res://addons/hengo/scenes/state_actions_list.tscn')
const FIX_PHASES: String = 'res://tests/fixtures/action_phases.gd'
const FIX_MATH: String = 'res://addons/hengo/actions/math/math_operator.gd'

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


# the chip list is the tab order, so it has to follow the rows top to bottom
func test_editable_chips_follow_the_row_order() -> void:
	var first: HenSaveAction = _add_action(&'enter')
	var second: HenSaveAction = _add_action(&'update')

	first.inputs[0].default_value = 'one'
	second.inputs[0].default_value = 'two'

	var actions_list: HenStateActionsList = _build_list()

	assert_int(actions_list._chips.size()).is_equal(2)
	assert_str(actions_list._chips[0].part.value).is_equal("'one'")
	assert_str(actions_list._chips[1].part.value).is_equal("'two'")


# a slot fed by another action renders as a capsule, and the chips inside it are
# editable like any other
func test_inline_action_renders_a_capsule_with_its_own_chips() -> void:
	var action: HenSaveAction = _add_action(&'update')
	action.input_actions['value'] = {action = _math_child(), output = &'result'}

	var actions_list: HenStateActionsList = _build_list()
	var row: HenActionRow = actions_list._rows_by_id[str(action.id)]
	var capsules: Array = _capsules_of(row)

	assert_int(capsules.size()).is_equal(1)
	# a + b, with op picked from a fixed option set
	assert_int(actions_list._chips.size()).is_equal(2)


func test_tab_wraps_around_the_chip_list() -> void:
	_add_action(&'update')
	_add_action(&'update')

	var actions_list: HenStateActionsList = _build_list()
	var first: HenActionValue = actions_list._chips[0]
	var last: HenActionValue = actions_list._chips[1]

	assert_object(actions_list._next_chip(first)).is_same(last)
	assert_object(actions_list._next_chip(last)).is_same(first)


func _math_child() -> HenSaveAction:
	var child: HenSaveAction = HenSaveAction.create(_register(FIX_MATH))

	for param: HenSaveParam in child.inputs:
		match str(param.id):
			'a': param.default_value = 1.0
			'op': param.default_value = '+'
			'b': param.default_value = 2.0

	return child


func _capsules_of(_row: HenActionRow) -> Array:
	var found: Array = []

	for child: Node in _row.get_node('Margin/Line').get_children():
		if child is HenActionCapsule:
			found.append(child)

	return found


func test_delete_removes_the_action_and_its_row() -> void:
	var keep: HenSaveAction = _add_action(&'update')
	var drop: HenSaveAction = _add_action(&'update')
	var actions_list: HenStateActionsList = _build_list()

	actions_list._delete_action(drop)

	var left: Array = save_data.get_state_actions(state.id)

	assert_int(left.size()).is_equal(1)
	assert_bool(left.has(keep)).is_true()
	assert_int(_count_of(actions_list, HenActionRow)).is_equal(1)
