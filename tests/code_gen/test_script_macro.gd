@tool
extends HenTestSuite

const TEMP_MACRO_PATH: String = 'res://hengo/macros/temp_test_macro_gen.gd'


# tests script macro generation from file
func test_generate_script_macro_from_file() -> void:
	var script_source: String = """
@tool
extends HenScriptMacroBase

func get_id() -> StringName:
	return 'test_macro_gen'

func get_inputs() -> Array:
	return []

func get_outputs() -> Array:
	return []

func get_flow_inputs() -> Array:
	return [{ name = 'Exec', id = '0' }]

func get_flow_outputs() -> Array:
	return [{ name = 'A', id = 'out_a' }, { name = 'B', id = 'out_b' }]

func get_flow_0(out_a, out_b) -> void:
	if true:
		out_a
		print('Going A')
	else:
		out_b
		print('Going B')

func get_function_overrides() -> Array[Dictionary]:
	return [
		{
			name = '_ready',
			params = [],
			body = "print('Manual Macro Ready')"
		}
	]
"""
	var dir: DirAccess = DirAccess.open('res://')
	if not dir.dir_exists('hengo/macros'):
		dir.make_dir_recursive('hengo/macros')

	var file: FileAccess = FileAccess.open(TEMP_MACRO_PATH, FileAccess.WRITE)
	file.store_string(script_source)
	file.close()

	HenScriptMacroLoader.load_script_macros()

	var macro_res: HenSaveMacro = null
	var global: HenGlobal = Engine.get_singleton('Global')
	for m: HenSaveMacro in global.script_macros:
		if m.script_path == TEMP_MACRO_PATH:
			macro_res = m
			break

	assert_object(macro_res).is_not_null()
	assert_array(macro_res.flow_inputs).has_size(1)
	assert_array(macro_res.flow_outputs).has_size(2)
	assert_str(macro_res.flow_inputs[0].name).is_equal('Exec')

	var base_route: HenRouteData = save_data.get_base_route()
	var macro_vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'MacroNode',
		type = HenVirtualCNode.Type.MACRO,
		sub_type = HenVirtualCNode.SubType.SCRIPT_MACRO,
		route = base_route,
		res = macro_res
	})

	var out_a_node: HenVirtualCNode = HenTest.get_void('func_a')
	var out_b_node: HenVirtualCNode = HenTest.get_void('func_b')

	var flow_outputs: Array = macro_vc.get_flow_outputs(save_data)
	macro_vc.add_flow_connection(flow_outputs[0].id, StringName('0'), out_a_node).add()
	macro_vc.add_flow_connection(flow_outputs[1].id, StringName('0'), out_b_node).add()

	var flow_inputs: Array = macro_vc.get_flow_inputs(save_data)
	var code: String = HenTest.get_vc_code(macro_vc, flow_inputs[0].id)

	var expected_code: String = "if true:\n\tfunc_a()\n\tprint('Going A')\nelse:\n\tfunc_b()\n\tprint('Going B')\n\n"

	assert_str(code).is_equal(expected_code)

	var full_code: String = HenTest.get_all_code()

	assert_str(full_code).contains('func _ready() -> void:')
	assert_str(full_code).contains("\tprint('Manual Macro Ready')")

	DirAccess.remove_absolute(TEMP_MACRO_PATH)


# tests macro generation utilizing self in base route
func test_macro_generation_with_base_route() -> void:
	var script_source: String = """
@tool
extends HenScriptMacroBase

var _ref: Node

func get_id() -> StringName:
	return 'test_macro_gen'

func get_inputs() -> Array:
	return []

func get_outputs() -> Array:
	return []

func get_flow_inputs() -> Array:
	return [{ name = 'Exec', id = '0' }]

func get_flow_outputs() -> Array:
	return [{ name = 'Out', id = '0' }]

func get_flow_0(out) -> void:
	_ref.call_method()
	out
"""
	var dir: DirAccess = DirAccess.open('res://')
	if not dir.dir_exists('hengo/macros'):
		dir.make_dir_recursive('hengo/macros')

	var file: FileAccess = FileAccess.open(TEMP_MACRO_PATH, FileAccess.WRITE)
	file.store_string(script_source)
	file.close()

	HenScriptMacroLoader.load_script_macros()

	var macro_res: HenSaveMacro = null
	var global: HenGlobal = Engine.get_singleton('Global')
	for m: HenSaveMacro in global.script_macros:
		if m.script_path == TEMP_MACRO_PATH:
			macro_res = m
			break

	assert_object(macro_res).is_not_null()

	var base_route: HenRouteData = save_data.get_base_route()
	var macro_vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'MacroNodeBase',
		type = HenVirtualCNode.Type.MACRO,
		sub_type = HenVirtualCNode.SubType.SCRIPT_MACRO,
		route = base_route,
		res = macro_res
	})

	var flow_inputs: Array = macro_vc.get_flow_inputs(save_data)
	var code: String = HenTest.get_vc_code(macro_vc, flow_inputs[0].id)

	assert_str(code).contains('self.call_method()')

	DirAccess.remove_absolute(TEMP_MACRO_PATH)


# tests macro generation utilizing ref in state route
func test_macro_generation_with_state_route() -> void:
	var script_source: String = """
@tool
extends HenScriptMacroBase

var _ref: Node

func get_id() -> StringName:
	return 'test_macro_gen'

func get_inputs() -> Array:
	return []

func get_outputs() -> Array:
	return []

func get_flow_inputs() -> Array:
	return [{ name = 'Exec', id = '0' }]

func get_flow_outputs() -> Array:
	return [{ name = 'Out', id = '0' }]

func get_flow_0(out) -> void:
	_ref.call_method()
	out
"""

	var file: FileAccess = FileAccess.open(TEMP_MACRO_PATH, FileAccess.WRITE)
	file.store_string(script_source)
	file.close()

	HenScriptMacroLoader.load_script_macros()

	var macro_res: HenSaveMacro = null
	var global: HenGlobal = Engine.get_singleton('Global')
	for m: HenSaveMacro in global.script_macros:
		if m.script_path == TEMP_MACRO_PATH:
			macro_res = m
			break

	assert_object(macro_res).is_not_null()

	var state: HenSaveState = HenSaveState.create()
	var macro_vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'MacroNodeState',
		type = HenVirtualCNode.Type.MACRO,
		sub_type = HenVirtualCNode.SubType.SCRIPT_MACRO,
		route = state.get_route(save_data),
		res = macro_res
	})

	var flow_inputs: Array = macro_vc.get_flow_inputs(save_data)
	var code: String = HenTest.get_vc_code(macro_vc, flow_inputs[0].id)

	assert_str(code).contains('_ref.call_method()')

	DirAccess.remove_absolute(TEMP_MACRO_PATH)


# tests macro override ref replacement when using callables
func test_macro_override_ref_replacement_with_callable() -> void:
	const TEMP_MACRO_CALLABLE_PATH: String = 'res://hengo/macros/temp_test_macro_callable_ref.gd'
	var script_source: String = """
@tool
extends HenScriptMacroBase

var _ref: Node

func get_id() -> StringName:
	return 'test_macro_gen'

func get_inputs() -> Array:
	return []

func get_outputs() -> Array:
	return []

func get_flow_inputs() -> Array:
	return []

func get_flow_outputs() -> Array:
	return []

func _my_logic() -> void:
	_ref.call_method()

func get_function_overrides() -> Array[Dictionary]:
	return [
		{
			name = '_process',
			params = [{ name = 'delta', type = 'float' }],
			body = _my_logic
		}
	]
"""
	var dir: DirAccess = DirAccess.open('res://')
	if not dir.dir_exists('hengo/macros'):
		dir.make_dir_recursive('hengo/macros')

	var file: FileAccess = FileAccess.open(TEMP_MACRO_CALLABLE_PATH, FileAccess.WRITE)
	file.store_string(script_source)
	file.close()

	HenScriptMacroLoader.load_script_macros()

	var macro_res: HenSaveMacro = null
	var global: HenGlobal = Engine.get_singleton('Global')

	HenScriptMacroLoader.load_script_macros()

	for m: HenSaveMacro in global.script_macros:
		if m.script_path == TEMP_MACRO_CALLABLE_PATH:
			macro_res = m
			break

	assert_object(macro_res).is_not_null()

	var base_route: HenRouteData = save_data.get_base_route()
	var macro_vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'MacroNodeCallableRef',
		type = HenVirtualCNode.Type.MACRO,
		sub_type = HenVirtualCNode.SubType.SCRIPT_MACRO,
		route = base_route,
		res = macro_res
	})

	var full_code: String = HenTest.get_all_code()

	assert_str(full_code).contains('func _process(delta: float) -> void:')
	assert_str(full_code).contains('self.call_method()')
	assert_str(full_code).not_contains('_ref.call_method()')

	DirAccess.remove_absolute(TEMP_MACRO_CALLABLE_PATH)


# tests macro id replacement
func test_macro_id_replacement() -> void:
	const TEMP_MACRO_ID_PATH: String = 'res://hengo/macros/temp_test_macro_id.gd'
	var script_source: String = """
@tool
extends HenScriptMacroBase

var _ref: Node

func get_id() -> StringName:
	return 'test_macro_gen'

func get_inputs() -> Array:
	return []

func get_outputs() -> Array:
	return []

func get_flow_inputs() -> Array:
	return [{ name = 'Exec', id = '0' }]

func get_flow_outputs() -> Array:
	return [{ name = 'Out', id = '0' }]

func get_flow_0(out) -> void:
	_ref.set_meta('%test_prop%', 10)
	var val = _ref.get_meta('%test_prop%')
	out
"""
	var dir: DirAccess = DirAccess.open('res://')
	if not dir.dir_exists('hengo/macros'):
		dir.make_dir_recursive('hengo/macros')

	var file: FileAccess = FileAccess.open(TEMP_MACRO_ID_PATH, FileAccess.WRITE)
	file.store_string(script_source)
	file.close()

	HenScriptMacroLoader.load_script_macros()

	var macro_res: HenSaveMacro = null
	var global: HenGlobal = Engine.get_singleton('Global')

	HenScriptMacroLoader.load_script_macros()

	for m: HenSaveMacro in global.script_macros:
		if m.script_path == TEMP_MACRO_ID_PATH:
			macro_res = m
			break

	assert_object(macro_res).is_not_null()

	var base_route: HenRouteData = save_data.get_base_route()
	var macro_vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'MacroNodeID',
		type = HenVirtualCNode.Type.MACRO,
		sub_type = HenVirtualCNode.SubType.SCRIPT_MACRO,
		route = base_route,
		res = macro_res
	})

	var flow_inputs: Array = macro_vc.get_flow_inputs(save_data)
	var code: String = HenTest.get_vc_code(macro_vc, flow_inputs[0].id)

	assert_str(code).contains("self.set_meta('test_prop_" + str(macro_vc.id) + "', 10)")
	assert_str(code).contains("var val = self.get_meta('test_prop_" + str(macro_vc.id) + "')")

	DirAccess.remove_absolute(TEMP_MACRO_ID_PATH)


# tests macro id replacement with negative id
func test_macro_id_replacement_negative() -> void:
	const TEMP_MACRO_NEG_ID_PATH: String = 'res://hengo/macros/temp_test_macro_neg_id.gd'
	var script_source: String = """
@tool
extends HenScriptMacroBase

var _ref: Node

func get_id() -> StringName:
	return 'test_macro_gen'

func get_inputs() -> Array:
	return []

func get_outputs() -> Array:
	return []

func get_flow_inputs() -> Array:
	return [{ name = 'Exec', id = '0' }]

func get_flow_outputs() -> Array:
	return [{ name = 'Out', id = '0' }]

func get_flow_0(out) -> void:
	_ref.set_meta('%neg_prop%', 20)
	var val = _ref.get_meta('%neg_prop%')
	out
"""
	var file: FileAccess = FileAccess.open(TEMP_MACRO_NEG_ID_PATH, FileAccess.WRITE)
	file.store_string(script_source)
	file.close()

	HenScriptMacroLoader.load_script_macros()

	var macro_res: HenSaveMacro = null
	var global: HenGlobal = Engine.get_singleton('Global')

	HenScriptMacroLoader.load_script_macros()

	for m: HenSaveMacro in global.script_macros:
		if m.script_path == TEMP_MACRO_NEG_ID_PATH:
			macro_res = m
			break

	assert_object(macro_res).is_not_null()

	var base_route: HenRouteData = save_data.get_base_route()
	var macro_vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'MacroNodeNegID',
		type = HenVirtualCNode.Type.MACRO,
		sub_type = HenVirtualCNode.SubType.SCRIPT_MACRO,
		route = base_route,
		res = macro_res
	})

	var flow_inputs: Array = macro_vc.get_flow_inputs(save_data)
	var code: String = HenTest.get_vc_code(macro_vc, flow_inputs[0].id)

	assert_str(code).contains("self.set_meta('neg_prop_" + str(macro_vc.id) + "', 20)")
	assert_str(code).contains("var val = self.get_meta('neg_prop_" + str(macro_vc.id) + "')")

	DirAccess.remove_absolute(TEMP_MACRO_NEG_ID_PATH)


# tests macro input collision with string literal
func test_macro_input_collision_with_string_literal() -> void:
	const TEMP_MACRO_COLLISION_PATH: String = 'res://hengo/macros/temp_test_macro_collision.gd'
	var script_source: String = """
@tool
extends HenScriptMacroBase

var _ref: Node

func get_id() -> StringName:
	return 'test_macro_gen'

func get_inputs() -> Array:
	return [ {name = 'duration', id = 'duration', type = 'float'}]

func get_outputs() -> Array:
	return []

func get_flow_inputs() -> Array:
	return [ {name = 'Exec', id = '0'}]

func get_flow_outputs() -> Array:
	return [ {name = 'Out', id = '0'}]

func get_flow_0(duration, out) -> void:
	_ref.set_meta('%duration%', duration)
	out
"""
	var dir: DirAccess = DirAccess.open('res://')
	if not dir.dir_exists('hengo/macros'):
		dir.make_dir_recursive('hengo/macros')

	var file: FileAccess = FileAccess.open(TEMP_MACRO_COLLISION_PATH, FileAccess.WRITE)
	file.store_string(script_source)
	file.close()

	HenScriptMacroLoader.load_script_macros()

	var macro_res: HenSaveMacro = null
	var global: HenGlobal = Engine.get_singleton('Global')

	HenScriptMacroLoader.load_script_macros()

	for m: HenSaveMacro in global.script_macros:
		if m.script_path == TEMP_MACRO_COLLISION_PATH:
			macro_res = m
			break

	assert_object(macro_res).is_not_null()

	var base_route: HenRouteData = save_data.get_base_route()
	var macro_vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'MacroNodeCollision',
		type = HenVirtualCNode.Type.MACRO,
		sub_type = HenVirtualCNode.SubType.SCRIPT_MACRO,
		route = base_route,
		res = macro_res
	})

	macro_vc.get_inputs(save_data)[0].code_value = '5.0'
	macro_vc.get_inputs(save_data)[0].category = 'class_props'

	var flow_inputs: Array = macro_vc.get_flow_inputs(save_data)
	var code: String = HenTest.get_vc_code(macro_vc, flow_inputs[0].id)

	DirAccess.remove_absolute(TEMP_MACRO_COLLISION_PATH)

	var expected_prop_name: String = 'duration_' + str(macro_vc.id)

	assert_str(code).contains("self.set_meta('" + expected_prop_name + "', 5.0)")
	assert_str(code).not_contains('%5.0%')


# tests generation of script macro output
func test_script_macro_output_generation() -> void:
	const TEMP_MACRO_OUTPUT_PATH: String = 'res://hengo/macros/temp_test_macro_output.gd'
	var script_source: String = """
@tool
extends HenScriptMacroBase

func get_id() -> StringName:
	return 'test_macro_output'

func get_inputs() -> Array:
	return [{name = 'val', id = 'val', type = 'int'}]

func get_outputs() -> Array:
	return [{name = 'result', id = 0, type = 'int'}]

func get_flow_inputs() -> Array:
	return []

func get_flow_outputs() -> Array:
	return []

func get_output_0(val):
	return val * 2
"""
	var dir: DirAccess = DirAccess.open('res://')
	if not dir.dir_exists('hengo/macros'):
		dir.make_dir_recursive('hengo/macros')

	var file: FileAccess = FileAccess.open(TEMP_MACRO_OUTPUT_PATH, FileAccess.WRITE)
	file.store_string(script_source)
	file.close()

	HenScriptMacroLoader.load_script_macros()

	var macro_res: HenSaveMacro = null
	var global: HenGlobal = Engine.get_singleton('Global')
	for m: HenSaveMacro in global.script_macros:
		if m.script_path == TEMP_MACRO_OUTPUT_PATH:
			macro_res = m
			break

	assert_object(macro_res).is_not_null()

	var base_route: HenRouteData = save_data.get_base_route()
	var macro_vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'MacroNodeOutput',
		type = HenVirtualCNode.Type.MACRO,
		sub_type = HenVirtualCNode.SubType.SCRIPT_MACRO,
		route = base_route,
		res = macro_res
	})

	# set input value
	macro_vc.get_inputs(save_data)[0].code_value = '5'
	macro_vc.get_inputs(save_data)[0].category = 'value'

	var consumer_vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'Consumer',
		type = HenVirtualCNode.Type.DEFAULT,
		sub_type = HenVirtualCNode.SubType.VOID,
		route = base_route
	})

	# create a dummy input for the consumer
	var consumer_input: HenVCInOutData = HenVCInOutData.new()
	consumer_input.name = 'in_val'
	consumer_input.type = 'int'
	consumer_input.id = '0'
	consumer_vc.inputs.append(consumer_input)

	# connect macro output -> consumer input
	var output_id: StringName = macro_vc.get_outputs(save_data)[0].id
	consumer_vc.get_new_input_connection_command('0', output_id, macro_vc).add()

	var token: Dictionary = HenVirtualCNodeCode.get_input_token(save_data, consumer_vc, '0')

	var generated_code: String = HenGeneratorByToken.get_code_by_token(save_data, token)

	# clean up
	DirAccess.remove_absolute(TEMP_MACRO_OUTPUT_PATH)

	assert_str(generated_code).contains('5 * 2')


# tests multi-line lambda output indentation
func test_script_macro_multiline_lambda_indentation() -> void:
	const TEMP_MACRO_LAMBDA_PATH: String = 'res://hengo/macros/temp_test_macro_lambda.gd'
	var script_source: String = """
@tool
extends HenScriptMacroBase

func get_id() -> StringName:
	return 'test_macro_lambda'

func get_inputs() -> Array:
	return []

func get_outputs() -> Array:
	return [{name = 'result', id = '0', type = 'Variant'}]

func get_flow_inputs() -> Array:
	return []

func get_flow_outputs() -> Array:
	return []

func get_output_0() -> String:
	return (func() -> float:
		if true:
			return 1.0
		return 0.0
	).call()
"""
	var dir: DirAccess = DirAccess.open('res://')
	if not dir.dir_exists('hengo/macros'):
		dir.make_dir_recursive('hengo/macros')

	var file: FileAccess = FileAccess.open(TEMP_MACRO_LAMBDA_PATH, FileAccess.WRITE)
	file.store_string(script_source)
	file.close()

	HenScriptMacroLoader.load_script_macros()

	var macro_res: HenSaveMacro = null
	var global: HenGlobal = Engine.get_singleton('Global')
	for m: HenSaveMacro in global.script_macros:
		if m.script_path == TEMP_MACRO_LAMBDA_PATH:
			macro_res = m
			break

	assert_object(macro_res).is_not_null()

	var base_route: HenRouteData = save_data.get_base_route()
	var macro_vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'MacroNodeLambda',
		type = HenVirtualCNode.Type.MACRO,
		sub_type = HenVirtualCNode.SubType.SCRIPT_MACRO,
		route = base_route,
		res = macro_res
	})

	var consumer_vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'Consumer',
		type = HenVirtualCNode.Type.DEFAULT,
		sub_type = HenVirtualCNode.SubType.VOID,
		name_to_code = 'print',
		route = base_route
	})

	var consumer_input: HenVCInOutData = HenVCInOutData.new()
	consumer_input.name = 'val'
	consumer_input.type = 'Variant'
	consumer_input.id = '0'
	consumer_vc.inputs.append(consumer_input)

	var output_id: StringName = macro_vc.get_outputs(save_data)[0].id
	consumer_vc.get_new_input_connection_command('0', output_id, macro_vc).add()

	var consumer_token: Dictionary = HenVirtualCNodeCode.get_token(save_data, consumer_vc)

	# generate code for this token at indentation level 1
	var code: String = HenGeneratorByToken.get_code_by_token(save_data, consumer_token, 1)

	DirAccess.remove_absolute(TEMP_MACRO_LAMBDA_PATH)

	# check for "       if true:" (2 tabs)
	assert_str(code).contains('\t\tif true:')
	assert_str(code).contains('\t\t\treturn 1.0')


# tests macro flow output substitution by id
func test_script_macro_flow_output_order_by_id() -> void:
	const TEMP_MACRO_FLOW_ORDER_PATH: String = 'res://hengo/macros/temp_test_macro_flow_order.gd'
	var script_source: String = """
@tool
extends HenScriptMacroBase

func get_id() -> StringName:
	return 'test_macro_flow_order'

func get_inputs() -> Array:
	return []

func get_outputs() -> Array:
	return []

func get_flow_inputs() -> Array:
	return [{name = 'Exec', id = '0'}]

func get_flow_outputs() -> Array:
	return [
		{name = 'Success', id = 'out_success'},
		{name = 'Fail', id = 'out_fail'}
	]

func get_flow_0(out_fail, out_success) -> void:
	if true:
		out_success
	else:
		out_fail
"""
	var dir: DirAccess = DirAccess.open('res://')
	if not dir.dir_exists('hengo/macros'):
		dir.make_dir_recursive('hengo/macros')

	var file: FileAccess = FileAccess.open(TEMP_MACRO_FLOW_ORDER_PATH, FileAccess.WRITE)
	file.store_string(script_source)
	file.close()

	HenScriptMacroLoader.load_script_macros()

	var macro_res: HenSaveMacro = null
	var global: HenGlobal = Engine.get_singleton('Global')
	for m: HenSaveMacro in global.script_macros:
		if m.script_path == TEMP_MACRO_FLOW_ORDER_PATH:
			macro_res = m
			break

	assert_object(macro_res).is_not_null()

	var base_route: HenRouteData = save_data.get_base_route()
	var macro_vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'MacroNodeFlowOrder',
		type = HenVirtualCNode.Type.MACRO,
		sub_type = HenVirtualCNode.SubType.SCRIPT_MACRO,
		route = base_route,
		res = macro_res
	})

	var out_success_node: HenVirtualCNode = HenTest.get_void('func_success')
	var out_fail_node: HenVirtualCNode = HenTest.get_void('func_fail')

	macro_vc.add_flow_connection('out_success', StringName('0'), out_success_node).add()
	macro_vc.add_flow_connection('out_fail', StringName('0'), out_fail_node).add()

	var flow_inputs: Array = macro_vc.get_flow_inputs(save_data)
	var code: String = HenTest.get_vc_code(macro_vc, flow_inputs[0].id)

	assert_str(code).contains('func_success()')
	assert_str(code).contains('func_fail()')

	var idx_if: int = code.find('if true:')
	var idx_success: int = code.find('func_success()')
	var idx_else: int = code.find('else:')
	var idx_fail: int = code.find('func_fail()')

	assert_int(idx_if).is_less(idx_success)
	assert_int(idx_success).is_less(idx_else)
	assert_int(idx_else).is_less(idx_fail)

	DirAccess.remove_absolute(TEMP_MACRO_FLOW_ORDER_PATH)


# tests if the output token from a script macro has the prop_name
func test_script_macro_output_has_prop_name() -> void:
	const TEMP_MACRO_PROP_NAME_PATH: String = 'res://hengo/macros/temp_test_macro_prop_name.gd'
	var script_source: String = """
@tool
extends HenScriptMacroBase

func get_id() -> StringName:
	return 'test_macro_prop_name'

func get_inputs() -> Array:
	return []

func get_outputs() -> Array:
	return [{name = 'val', id = 0, type = 'int'}]

func get_flow_inputs() -> Array:
	return []

func get_flow_outputs() -> Array:
	return []

func get_output_0():
	return 10
"""
	var dir: DirAccess = DirAccess.open('res://')
	if not dir.dir_exists('hengo/macros'):
		dir.make_dir_recursive('hengo/macros')

	var file: FileAccess = FileAccess.open(TEMP_MACRO_PROP_NAME_PATH, FileAccess.WRITE)
	file.store_string(script_source)
	file.close()

	HenScriptMacroLoader.load_script_macros()

	var macro_res: HenSaveMacro = null
	var global: HenGlobal = Engine.get_singleton('Global')
	for m: HenSaveMacro in global.script_macros:
		if m.script_path == TEMP_MACRO_PROP_NAME_PATH:
			macro_res = m
			break

	assert_object(macro_res).is_not_null()

	var base_route: HenRouteData = save_data.get_base_route()
	var macro_vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'MacroNodePropName',
		type = HenVirtualCNode.Type.MACRO,
		sub_type = HenVirtualCNode.SubType.SCRIPT_MACRO,
		route = base_route,
		res = macro_res
	})

	var consumer_vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'Consumer',
		type = HenVirtualCNode.Type.EXPRESSION,
		sub_type = HenVirtualCNode.SubType.EXPRESSION,
		route = base_route,
		input_code_value_map = {
			0: {type = 'Variant', value = 'a'}
		},
		inputs = [
			{id = 0, name = '', type = 'Variant', sub_type = 'expression'},
			{id = 1, name = 'a', type = 'int'}
		]
	})

	var output_id: StringName = macro_vc.get_outputs(save_data)[0].id
	consumer_vc.get_new_input_connection_command('1', output_id, macro_vc).add()

	var token: Dictionary = HenVirtualCNodeCode.get_input_token(save_data, consumer_vc, '1')

	DirAccess.remove_absolute(TEMP_MACRO_PROP_NAME_PATH)

	assert_dict(token).contains_key_value('prop_name', 'a')