@tool
class_name TestHenCardEditor extends HenTestSuite

# the index the add-above and add-below entries hand to open_add: it is a
# position inside the phase bucket, not inside the whole action list


const FIX_PHASES: String = 'res://tests/fixtures/action_phases.gd'
const FIX_LOOP: String = 'res://addons/hengo/actions/flow/repeat.gd'

var state: HenSaveState
var editor: HenStateViewerCardEditor


func before_test() -> void:
	super ()
	state = save_data.add_state(false)
	state.name = 'Play'
	editor = HenStateViewerCardEditor.new()
	editor.target(save_data, StringName(str(state.id)))


func _register(_path: String) -> HenSaveMacro:
	var instance: HenScriptMacroBase = (load(_path) as GDScript).new()
	var macro: HenSaveMacro = HenSaveMacro.new()

	macro.id = instance.get_id()
	macro.name = _path.get_file().get_basename()
	macro.is_script_macro = true
	macro.script_path = _path
	macro.has_body = instance.get_has_body()

	for input: Dictionary in instance.get_inputs():
		macro.inputs.append(HenSaveParam.create(input))

	# supported_phases reads these, so a macro registered without them only ever
	# offers update
	for flow_input: Dictionary in instance.get_flow_inputs():
		macro.flow_inputs.append(HenSaveFlowParam.create(flow_input))

	(Engine.get_singleton(&'Global') as HenGlobal).action_macros.append(macro)

	return macro


func _add(_macro: HenSaveMacro, _phase: StringName) -> HenSaveAction:
	var action: HenSaveAction = HenSaveAction.create(_macro)

	action.phase = _phase
	save_data.add_state_action(state.id, action)

	return action


func test_the_index_counts_inside_the_phase_and_not_the_list() -> void:
	var macro: HenSaveMacro = _register(FIX_PHASES)

	_add(macro, &'enter')
	_add(macro, &'update')

	var second: HenSaveAction = _add(macro, &'update')

	assert_int(editor.index_around(second, false)).is_equal(1)
	assert_int(editor.index_around(second, true)).is_equal(2)


func test_the_index_of_a_nested_step_counts_inside_the_body() -> void:
	var macro: HenSaveMacro = _register(FIX_PHASES)
	var loop_macro: HenSaveMacro = _register(FIX_LOOP)
	var loop: HenSaveAction = _add(loop_macro, &'update')
	var first: HenSaveAction = HenSaveAction.create(macro)
	var second: HenSaveAction = HenSaveAction.create(macro)

	loop.body_actions.append(first)
	loop.body_actions.append(second)

	assert_int(editor.index_around(second, false)).is_equal(1)
	assert_int(editor.index_around(second, true)).is_equal(2)


func test_an_action_outside_the_state_has_no_index() -> void:
	var macro: HenSaveMacro = _register(FIX_PHASES)

	assert_int(editor.index_around(HenSaveAction.create(macro), false)).is_equal(-1)


# the tail of an empty phase is the whole point of showing one per phase: what it
# adds has to land there and not on the macro default
func test_the_tail_of_a_phase_adds_to_that_phase() -> void:
	var macro: HenSaveMacro = _register(FIX_PHASES)

	editor._do_insert(macro, save_data, StringName(str(state.id)), null, &'exit', -1)

	var actions: Array = save_data.get_state_actions(state.id)

	assert_int(actions.size()).is_equal(1)
	assert_str(str((actions[0] as HenSaveAction).phase)).is_equal('exit')


func test_a_phase_the_macro_cannot_run_falls_back_to_its_default() -> void:
	var macro: HenSaveMacro = _register(FIX_PHASES)

	editor._do_insert(macro, save_data, StringName(str(state.id)), null, &'physics', -1)

	var actions: Array = save_data.get_state_actions(state.id)

	assert_str(str((actions[0] as HenSaveAction).phase)).is_equal('update')
