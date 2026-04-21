@tool
extends HenTestSuite

const TEMP_MACRO_PATH: String = 'res://hengo/macros/temp_test_macro_gen.gd'


# tests script macro generation from file with string template
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

func get_flow_0() -> String:
	return \"\"\"
if true:
	{{out_a}}
	print('Going A')
else:
	{{out_b}}
	print('Going B')
\"\"\"

func get_function_overrides() -> Array[Dictionary]:
	return [
		{
			name = '_ready',
			params = [],
			body = \"print('Manual Macro Ready')\"
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

	assert_str(code).contains("if true:")
	assert_str(code).contains("func_a()")
	assert_str(code).contains("print('Going A')")
	assert_str(code).contains("else:")
	assert_str(code).contains("func_b()")
	assert_str(code).contains("print('Going B')")
	assert_int(code.find("func_a()")).is_less(code.find("func_b()"))

	var full_code: String = HenTest.get_all_code()

	assert_str(full_code).contains('func _ready() -> void:')
	assert_str(full_code).contains("\tprint('Manual Macro Ready')")

	DirAccess.remove_absolute(TEMP_MACRO_PATH)


# tests macro generation utilizing self in base route
func test_macro_generation_with_base_route() -> void:
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
	return [{ name = 'Out', id = '0' }]

func get_flow_0() -> String:
	return \"\"\"
_ref.call_method()
{{0}}
\"\"\"
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

func get_flow_0() -> String:
	return \"\"\"
_ref.call_method()
{{0}}
\"\"\"
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


# tests macro override with callable returning string template
func test_macro_override_ref_replacement_with_callable() -> void:
	const TEMP_MACRO_CALLABLE_PATH: String = 'res://hengo/macros/temp_test_macro_callable_ref.gd'
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
	return []

func get_flow_outputs() -> Array:
	return []

func _my_logic() -> String:
	return \"\"\"
_ref.call_method()
\"\"\"

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


# tests {{VCNODE_ID}} replacement in flow body
func test_macro_id_replacement() -> void:
	const TEMP_MACRO_ID_PATH: String = 'res://hengo/macros/temp_test_macro_id.gd'
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
	return [{ name = 'Out', id = '0' }]

func get_flow_0() -> String:
	return \"\"\"
self.set_meta('test_prop_{{VCNODE_ID}}', 10)
var val = self.get_meta('test_prop_{{VCNODE_ID}}')
{{0}}
\"\"\"
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


# tests {{VCNODE_ID}} replacement with negative id
func test_macro_id_replacement_negative() -> void:
	const TEMP_MACRO_NEG_ID_PATH: String = 'res://hengo/macros/temp_test_macro_neg_id.gd'
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
	return [{ name = 'Out', id = '0' }]

func get_flow_0() -> String:
	return \"\"\"
self.set_meta('neg_prop_{{VCNODE_ID}}', 20)
var val = self.get_meta('neg_prop_{{VCNODE_ID}}')
{{0}}
\"\"\"
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


# tests {{input_id}} injection doesn't affect string literals
func test_macro_input_collision_with_string_literal() -> void:
	const TEMP_MACRO_COLLISION_PATH: String = 'res://hengo/macros/temp_test_macro_collision.gd'
	var script_source: String = """
@tool
extends HenScriptMacroBase

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

func get_flow_0() -> String:
	return \"\"\"
self.set_meta('duration_{{VCNODE_ID}}', {{duration}})
{{0}}
\"\"\"
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


# tests generation of script macro output with {{placeholder}}
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

func get_output_0() -> String:
	return '{{val}} * 2'
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

	macro_vc.get_inputs(save_data)[0].code_value = '5'
	macro_vc.get_inputs(save_data)[0].category = 'value'

	var consumer_vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'Consumer',
		type = HenVirtualCNode.Type.DEFAULT,
		sub_type = HenVirtualCNode.SubType.VOID,
		route = base_route
	})

	var consumer_input: HenVCInOutData = HenVCInOutData.new()
	consumer_input.name = 'in_val'
	consumer_input.type = 'int'
	consumer_input.id = '0'
	consumer_vc.inputs.append(consumer_input)

	var output_id: StringName = macro_vc.get_outputs(save_data)[0].id
	consumer_vc.get_new_input_connection_command('0', output_id, macro_vc).add()

	var token: Dictionary = HenVirtualCNodeCode.get_input_token(save_data, consumer_vc, '0')

	var generated_code: String = HenGeneratorByToken.get_code_by_token(save_data, token)

	DirAccess.remove_absolute(TEMP_MACRO_OUTPUT_PATH)

	assert_str(generated_code).contains('5 * 2')


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

func get_flow_0() -> String:
	return \"\"\"
if true:
	{{out_success}}
else:
	{{out_fail}}
\"\"\"
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

func get_output_0() -> String:
	return '10'
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


# --- new string template tests ---


# tests {{input_id}} is injected into flow body
func test_string_template_flow_input_injection() -> void:
	const PATH: String = 'res://hengo/macros/temp_test_flow_input_inject.gd'
	var script_source: String = """
@tool
extends HenScriptMacroBase

func get_id() -> StringName:
	return 'test_flow_input_inject'

func get_inputs() -> Array:
	return [{name = 'msg', id = 'msg', type = 'String'}]

func get_outputs() -> Array:
	return []

func get_flow_inputs() -> Array:
	return [{name = 'Exec', id = '0'}]

func get_flow_outputs() -> Array:
	return []

func get_flow_0() -> String:
	return 'print({{msg}})'
"""
	var dir: DirAccess = DirAccess.open('res://')
	if not dir.dir_exists('hengo/macros'):
		dir.make_dir_recursive('hengo/macros')

	var file: FileAccess = FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string(script_source)
	file.close()

	HenScriptMacroLoader.load_script_macros()

	var macro_res: HenSaveMacro = null
	var global: HenGlobal = Engine.get_singleton('Global')
	for m: HenSaveMacro in global.script_macros:
		if m.script_path == PATH:
			macro_res = m
			break

	assert_object(macro_res).is_not_null()

	var base_route: HenRouteData = save_data.get_base_route()
	var macro_vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'MacroFlowInputInject',
		type = HenVirtualCNode.Type.MACRO,
		sub_type = HenVirtualCNode.SubType.SCRIPT_MACRO,
		route = base_route,
		res = macro_res
	})

	macro_vc.get_inputs(save_data)[0].code_value = '"hello"'
	macro_vc.get_inputs(save_data)[0].category = 'value'

	var flow_inputs: Array = macro_vc.get_flow_inputs(save_data)
	var code: String = HenTest.get_vc_code(macro_vc, flow_inputs[0].id)

	DirAccess.remove_absolute(PATH)

	assert_str(code).contains('print("hello")')


# tests {{flow_output_id}} is replaced by connected flow code
func test_string_template_flow_output_injection() -> void:
	const PATH: String = 'res://hengo/macros/temp_test_flow_output_inject.gd'
	var script_source: String = """
@tool
extends HenScriptMacroBase

func get_id() -> StringName:
	return 'test_flow_output_inject'

func get_inputs() -> Array:
	return []

func get_outputs() -> Array:
	return []

func get_flow_inputs() -> Array:
	return [{name = 'Exec', id = '0'}]

func get_flow_outputs() -> Array:
	return [{name = 'Out', id = 'done'}]

func get_flow_0() -> String:
	return 'print("before")\n{{done}}'
"""
	var dir: DirAccess = DirAccess.open('res://')
	if not dir.dir_exists('hengo/macros'):
		dir.make_dir_recursive('hengo/macros')

	var file: FileAccess = FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string(script_source)
	file.close()

	HenScriptMacroLoader.load_script_macros()

	var macro_res: HenSaveMacro = null
	var global: HenGlobal = Engine.get_singleton('Global')
	for m: HenSaveMacro in global.script_macros:
		if m.script_path == PATH:
			macro_res = m
			break

	assert_object(macro_res).is_not_null()

	var base_route: HenRouteData = save_data.get_base_route()
	var macro_vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'MacroFlowOutputInject',
		type = HenVirtualCNode.Type.MACRO,
		sub_type = HenVirtualCNode.SubType.SCRIPT_MACRO,
		route = base_route,
		res = macro_res
	})

	var next_node: HenVirtualCNode = HenTest.get_void('after_func')
	macro_vc.add_flow_connection('done', StringName('0'), next_node).add()

	var flow_inputs: Array = macro_vc.get_flow_inputs(save_data)
	var code: String = HenTest.get_vc_code(macro_vc, flow_inputs[0].id)

	DirAccess.remove_absolute(PATH)

	assert_str(code).contains('print("before")')
	assert_str(code).contains('after_func()')
	assert_int(code.find('print("before")')).is_less(code.find('after_func()'))


# tests {{VCNODE_ID}} is replaced by the macro instance id
func test_string_template_vcnode_id_replacement() -> void:
	const PATH: String = 'res://hengo/macros/temp_test_vcnode_id.gd'
	var script_source: String = """
@tool
extends HenScriptMacroBase

func get_id() -> StringName:
	return 'test_vcnode_id'

func get_inputs() -> Array:
	return []

func get_outputs() -> Array:
	return []

func get_flow_inputs() -> Array:
	return [{name = 'Exec', id = '0'}]

func get_flow_outputs() -> Array:
	return []

func get_flow_0() -> String:
	return 'var x_{{VCNODE_ID}}: int = 0'
"""
	var dir: DirAccess = DirAccess.open('res://')
	if not dir.dir_exists('hengo/macros'):
		dir.make_dir_recursive('hengo/macros')

	var file: FileAccess = FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string(script_source)
	file.close()

	HenScriptMacroLoader.load_script_macros()

	var macro_res: HenSaveMacro = null
	var global: HenGlobal = Engine.get_singleton('Global')
	for m: HenSaveMacro in global.script_macros:
		if m.script_path == PATH:
			macro_res = m
			break

	assert_object(macro_res).is_not_null()

	var base_route: HenRouteData = save_data.get_base_route()
	var macro_vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'MacroVcnodeId',
		type = HenVirtualCNode.Type.MACRO,
		sub_type = HenVirtualCNode.SubType.SCRIPT_MACRO,
		route = base_route,
		res = macro_res
	})

	var flow_inputs: Array = macro_vc.get_flow_inputs(save_data)
	var code: String = HenTest.get_vc_code(macro_vc, flow_inputs[0].id)

	DirAccess.remove_absolute(PATH)

	assert_str(code).contains('var x_' + str(macro_vc.id) + ': int = 0')


# tests {{VCNODE_ID}} in function override body string
func test_string_template_vcnode_id_in_override() -> void:
	const PATH: String = 'res://hengo/macros/temp_test_vcnode_id_override.gd'
	var script_source: String = """
@tool
extends HenScriptMacroBase

func get_id() -> StringName:
	return 'test_vcnode_id_override'

func get_inputs() -> Array:
	return []

func get_outputs() -> Array:
	return []

func get_flow_inputs() -> Array:
	return []

func get_flow_outputs() -> Array:
	return []

func get_function_overrides() -> Array[Dictionary]:
	return [
		{
			name = '_ready',
			params = [],
			body = 'print({{VCNODE_ID}})'
		}
	]
"""
	var dir: DirAccess = DirAccess.open('res://')
	if not dir.dir_exists('hengo/macros'):
		dir.make_dir_recursive('hengo/macros')

	var file: FileAccess = FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string(script_source)
	file.close()

	HenScriptMacroLoader.load_script_macros()

	var macro_res: HenSaveMacro = null
	var global: HenGlobal = Engine.get_singleton('Global')
	for m: HenSaveMacro in global.script_macros:
		if m.script_path == PATH:
			macro_res = m
			break

	assert_object(macro_res).is_not_null()

	var base_route: HenRouteData = save_data.get_base_route()
	var macro_vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'MacroOverrideVcnodeId',
		type = HenVirtualCNode.Type.MACRO,
		sub_type = HenVirtualCNode.SubType.SCRIPT_MACRO,
		route = base_route,
		res = macro_res
	})

	var full_code: String = HenTest.get_all_code()

	DirAccess.remove_absolute(PATH)

	assert_str(full_code).contains('print(' + str(macro_vc.id) + ')')


# tests two instances of same macro generate distinct variable names
func test_string_template_multiple_instances_no_collision() -> void:
	const PATH: String = 'res://hengo/macros/temp_test_multi_instance.gd'
	var script_source: String = """
@tool
extends HenScriptMacroBase

func get_id() -> StringName:
	return 'test_multi_instance'

func get_inputs() -> Array:
	return []

func get_outputs() -> Array:
	return []

func get_flow_inputs() -> Array:
	return [{name = 'Exec', id = '0'}]

func get_flow_outputs() -> Array:
	return []

func get_flow_0() -> String:
	return 'var counter_{{VCNODE_ID}}: int = 0'
"""
	var dir: DirAccess = DirAccess.open('res://')
	if not dir.dir_exists('hengo/macros'):
		dir.make_dir_recursive('hengo/macros')

	var file: FileAccess = FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string(script_source)
	file.close()

	HenScriptMacroLoader.load_script_macros()

	var macro_res: HenSaveMacro = null
	var global: HenGlobal = Engine.get_singleton('Global')
	for m: HenSaveMacro in global.script_macros:
		if m.script_path == PATH:
			macro_res = m
			break

	assert_object(macro_res).is_not_null()

	var base_route: HenRouteData = save_data.get_base_route()
	var macro_vc_a: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'MacroInstanceA',
		type = HenVirtualCNode.Type.MACRO,
		sub_type = HenVirtualCNode.SubType.SCRIPT_MACRO,
		route = base_route,
		res = macro_res
	})

	var macro_vc_b: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'MacroInstanceB',
		type = HenVirtualCNode.Type.MACRO,
		sub_type = HenVirtualCNode.SubType.SCRIPT_MACRO,
		route = base_route,
		res = macro_res
	})

	var flow_inputs_a: Array = macro_vc_a.get_flow_inputs(save_data)
	var code_a: String = HenTest.get_vc_code(macro_vc_a, flow_inputs_a[0].id)

	var flow_inputs_b: Array = macro_vc_b.get_flow_inputs(save_data)
	var code_b: String = HenTest.get_vc_code(macro_vc_b, flow_inputs_b[0].id)

	DirAccess.remove_absolute(PATH)

	assert_str(code_a).contains('counter_' + str(macro_vc_a.id))
	assert_str(code_b).contains('counter_' + str(macro_vc_b.id))
	assert_bool(macro_vc_a.id != macro_vc_b.id).is_true()


# tests get_output_<id>() -> String with {{input_id}}
func test_string_template_output_function() -> void:
	const PATH: String = 'res://hengo/macros/temp_test_output_template.gd'
	var script_source: String = """
@tool
extends HenScriptMacroBase

func get_id() -> StringName:
	return 'test_output_template'

func get_inputs() -> Array:
	return [{name = 'val', id = 'val', type = 'int'}]

func get_outputs() -> Array:
	return [{name = 'doubled', id = 'doubled', type = 'int'}]

func get_flow_inputs() -> Array:
	return []

func get_flow_outputs() -> Array:
	return []

func get_output_doubled() -> String:
	return '{{val}} * 2'
"""
	var dir: DirAccess = DirAccess.open('res://')
	if not dir.dir_exists('hengo/macros'):
		dir.make_dir_recursive('hengo/macros')

	var file: FileAccess = FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string(script_source)
	file.close()

	HenScriptMacroLoader.load_script_macros()

	var macro_res: HenSaveMacro = null
	var global: HenGlobal = Engine.get_singleton('Global')
	for m: HenSaveMacro in global.script_macros:
		if m.script_path == PATH:
			macro_res = m
			break

	assert_object(macro_res).is_not_null()

	var base_route: HenRouteData = save_data.get_base_route()
	var macro_vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'MacroOutputTemplate',
		type = HenVirtualCNode.Type.MACRO,
		sub_type = HenVirtualCNode.SubType.SCRIPT_MACRO,
		route = base_route,
		res = macro_res
	})

	macro_vc.get_inputs(save_data)[0].code_value = '7'
	macro_vc.get_inputs(save_data)[0].category = 'value'

	var consumer_vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'Consumer',
		type = HenVirtualCNode.Type.DEFAULT,
		sub_type = HenVirtualCNode.SubType.VOID,
		route = base_route
	})

	var consumer_input: HenVCInOutData = HenVCInOutData.new()
	consumer_input.name = 'in_val'
	consumer_input.type = 'int'
	consumer_input.id = '0'
	consumer_vc.inputs.append(consumer_input)

	var output_id: StringName = macro_vc.get_outputs(save_data)[0].id
	consumer_vc.get_new_input_connection_command('0', output_id, macro_vc).add()

	var token: Dictionary = HenVirtualCNodeCode.get_input_token(save_data, consumer_vc, '0')
	var generated_code: String = HenGeneratorByToken.get_code_by_token(save_data, token)

	DirAccess.remove_absolute(PATH)

	assert_str(generated_code).contains('7 * 2')


# tests _ref -> self replacement in base route with new template format
func test_string_template_base_route_self_replacement() -> void:
	const PATH: String = 'res://hengo/macros/temp_test_self_replace.gd'
	var script_source: String = """
@tool
extends HenScriptMacroBase

func get_id() -> StringName:
	return 'test_self_replace'

func get_inputs() -> Array:
	return []

func get_outputs() -> Array:
	return []

func get_flow_inputs() -> Array:
	return [{name = 'Exec', id = '0'}]

func get_flow_outputs() -> Array:
	return []

func get_flow_0() -> String:
	return '_ref.do_something()'
"""
	var dir: DirAccess = DirAccess.open('res://')
	if not dir.dir_exists('hengo/macros'):
		dir.make_dir_recursive('hengo/macros')

	var file: FileAccess = FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string(script_source)
	file.close()

	HenScriptMacroLoader.load_script_macros()

	var macro_res: HenSaveMacro = null
	var global: HenGlobal = Engine.get_singleton('Global')
	for m: HenSaveMacro in global.script_macros:
		if m.script_path == PATH:
			macro_res = m
			break

	assert_object(macro_res).is_not_null()

	var base_route: HenRouteData = save_data.get_base_route()
	var macro_vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'MacroSelfReplace',
		type = HenVirtualCNode.Type.MACRO,
		sub_type = HenVirtualCNode.SubType.SCRIPT_MACRO,
		route = base_route,
		res = macro_res
	})

	var flow_inputs: Array = macro_vc.get_flow_inputs(save_data)
	var code: String = HenTest.get_vc_code(macro_vc, flow_inputs[0].id)

	DirAccess.remove_absolute(PATH)

	assert_str(code).contains('self.do_something()')
	assert_str(code).not_contains('_ref.do_something()')


# tests _ref stays as _ref in state route
func test_string_template_state_route_ref_kept() -> void:
	const PATH: String = 'res://hengo/macros/temp_test_ref_kept.gd'
	var script_source: String = """
@tool
extends HenScriptMacroBase

func get_id() -> StringName:
	return 'test_ref_kept'

func get_inputs() -> Array:
	return []

func get_outputs() -> Array:
	return []

func get_flow_inputs() -> Array:
	return [{name = 'Exec', id = '0'}]

func get_flow_outputs() -> Array:
	return []

func get_flow_0() -> String:
	return '_ref.do_something()'
"""
	var dir: DirAccess = DirAccess.open('res://')
	if not dir.dir_exists('hengo/macros'):
		dir.make_dir_recursive('hengo/macros')

	var file: FileAccess = FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string(script_source)
	file.close()

	HenScriptMacroLoader.load_script_macros()

	var macro_res: HenSaveMacro = null
	var global: HenGlobal = Engine.get_singleton('Global')
	for m: HenSaveMacro in global.script_macros:
		if m.script_path == PATH:
			macro_res = m
			break

	assert_object(macro_res).is_not_null()

	var state: HenSaveState = HenSaveState.create()
	var macro_vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'MacroRefKept',
		type = HenVirtualCNode.Type.MACRO,
		sub_type = HenVirtualCNode.SubType.SCRIPT_MACRO,
		route = state.get_route(save_data),
		res = macro_res
	})

	var flow_inputs: Array = macro_vc.get_flow_inputs(save_data)
	var code: String = HenTest.get_vc_code(macro_vc, flow_inputs[0].id)

	DirAccess.remove_absolute(PATH)

	assert_str(code).contains('_ref.do_something()')


# tests get_function_overrides with body as String directly (not Callable)
func test_string_template_override_body_string_direct() -> void:
	const PATH: String = 'res://hengo/macros/temp_test_override_string.gd'
	var script_source: String = """
@tool
extends HenScriptMacroBase

func get_id() -> StringName:
	return 'test_override_string'

func get_inputs() -> Array:
	return []

func get_outputs() -> Array:
	return []

func get_flow_inputs() -> Array:
	return []

func get_flow_outputs() -> Array:
	return []

func get_function_overrides() -> Array[Dictionary]:
	return [
		{
			name = '_ready',
			params = [],
			body = 'print("from_override_{{VCNODE_ID}}")'
		}
	]
"""
	var dir: DirAccess = DirAccess.open('res://')
	if not dir.dir_exists('hengo/macros'):
		dir.make_dir_recursive('hengo/macros')

	var file: FileAccess = FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string(script_source)
	file.close()

	HenScriptMacroLoader.load_script_macros()

	var macro_res: HenSaveMacro = null
	var global: HenGlobal = Engine.get_singleton('Global')
	for m: HenSaveMacro in global.script_macros:
		if m.script_path == PATH:
			macro_res = m
			break

	assert_object(macro_res).is_not_null()

	var base_route: HenRouteData = save_data.get_base_route()
	var macro_vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'MacroOverrideString',
		type = HenVirtualCNode.Type.MACRO,
		sub_type = HenVirtualCNode.SubType.SCRIPT_MACRO,
		route = base_route,
		res = macro_res
	})

	var full_code: String = HenTest.get_all_code()

	DirAccess.remove_absolute(PATH)

	assert_str(full_code).contains('print("from_override_' + str(macro_vc.id) + '")')


# tests get_script_base() injects class-level variables with unique ids into the generated script
func test_string_template_get_script_base_injection() -> void:
	const PATH: String = 'res://hengo/macros/temp_test_script_base.gd'
	var script_source: String = """
@tool
extends HenScriptMacroBase

func get_id() -> StringName:
	return 'test_script_base'

func get_inputs() -> Array:
	return []

func get_outputs() -> Array:
	return []

func get_flow_inputs() -> Array:
	return []

func get_flow_outputs() -> Array:
	return []

func get_script_base() -> String:
	return \"\"\"
var _counter_{{VCNODE_ID}}: int = 0
var _label_{{VCNODE_ID}}: String = ''
\"\"\"

func get_function_overrides() -> Array[Dictionary]:
	return []
"""
	var dir: DirAccess = DirAccess.open('res://')
	if not dir.dir_exists('hengo/macros'):
		dir.make_dir_recursive('hengo/macros')

	var file: FileAccess = FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string(script_source)
	file.close()

	HenScriptMacroLoader.load_script_macros()

	var macro_res: HenSaveMacro = null
	var global: HenGlobal = Engine.get_singleton('Global')
	for m: HenSaveMacro in global.script_macros:
		if m.script_path == PATH:
			macro_res = m
			break

	assert_object(macro_res).is_not_null()

	var base_route: HenRouteData = save_data.get_base_route()
	var macro_vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'MacroScriptBase',
		type = HenVirtualCNode.Type.MACRO,
		sub_type = HenVirtualCNode.SubType.SCRIPT_MACRO,
		route = base_route,
		res = macro_res
	})

	var full_code: String = HenTest.get_all_code()

	DirAccess.remove_absolute(PATH)

	assert_str(full_code).contains('var _counter_' + str(macro_vc.id) + ': int = 0')
	assert_str(full_code).contains("var _label_" + str(macro_vc.id) + ": String = ''")
