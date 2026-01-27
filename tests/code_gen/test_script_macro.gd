@tool
extends HenTestSuite

const TEMP_MACRO_PATH: String = 'res://hengo/macros/temp_test_macro_gen.gd'

# tests generation of script macro from a file
func test_generate_script_macro_from_file() -> void:
	var script_source: String = """
@tool
extends 'res://addons/hengo/scripts/utils/script_macro_base.gd'

func get_script_id() -> int:
	return 0

func get_inputs() -> Array:
	return []

func get_outputs() -> Array:
	return []

func get_flow_inputs() -> Array:
	return [{ name = 'Exec', id = 0 }]

func get_flow_outputs() -> Array:
	return [{ name = 'A', id = 0 }, { name = 'B', id = 1 }]

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
	macro_vc.add_flow_connection(flow_outputs[0].id, 0, out_a_node).add()
	macro_vc.add_flow_connection(flow_outputs[1].id, 0, out_b_node).add()
	
	var flow_inputs: Array = macro_vc.get_flow_inputs(save_data)
	var code: String = HenTest.get_vc_code(macro_vc, flow_inputs[0].id)
	
	var expected_code: String = "if true:\n\tfunc_a()\n\tprint('Going A')\nelse:\n\tfunc_b()\n\tprint('Going B')\n\n"
	
	assert_str(code).is_equal(expected_code)
	
	var full_code: String = HenTest.get_all_code()

	assert_str(full_code).contains('func _ready() -> void:')
	assert_str(full_code).contains("\tprint('Manual Macro Ready')")
	
	DirAccess.remove_absolute(TEMP_MACRO_PATH)


# tests macro generation with base route utilizing self
func test_macro_generation_with_base_route() -> void:
	var script_source: String = """
@tool
extends 'res://addons/hengo/scripts/utils/script_macro_base.gd'

var _ref: Node

func get_script_id() -> int:
	return 0

func get_inputs() -> Array:
	return []

func get_outputs() -> Array:
	return []

func get_flow_inputs() -> Array:
	return [{ name = 'Exec', id = 0 }]

func get_flow_outputs() -> Array:
	return [{ name = 'Out', id = 0 }]

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


# tests macro generation with state route utilizing _ref
func test_macro_generation_with_state_route() -> void:
	var script_source: String = """
@tool
extends 'res://addons/hengo/scripts/utils/script_macro_base.gd'

var _ref: Node

func get_script_id() -> int:
	return 0

func get_inputs() -> Array:
	return []

func get_outputs() -> Array:
	return []

func get_flow_inputs() -> Array:
	return [{ name = 'Exec', id = 0 }]

func get_flow_outputs() -> Array:
	return [{ name = 'Out', id = 0 }]

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
extends 'res://addons/hengo/scripts/utils/script_macro_base.gd'

var _ref: Node

func get_script_id() -> int:
	return 0

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


# tests macro ID replacement
func test_macro_id_replacement() -> void:
	const TEMP_MACRO_ID_PATH: String = 'res://hengo/macros/temp_test_macro_id.gd'
	var script_source: String = """
@tool
extends 'res://addons/hengo/scripts/utils/script_macro_base.gd'

var _ref: Node

func get_script_id() -> int:
	return 12345

func get_inputs() -> Array:
	return []

func get_outputs() -> Array:
	return []

func get_flow_inputs() -> Array:
	return [{ name = 'Exec', id = 0 }]

func get_flow_outputs() -> Array:
	return [{ name = 'Out', id = 0 }]

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


# tests macro ID replacement with negative ID
func test_macro_id_replacement_negative() -> void:
	const TEMP_MACRO_NEG_ID_PATH: String = 'res://hengo/macros/temp_test_macro_neg_id.gd'
	var script_source: String = """
@tool
extends 'res://addons/hengo/scripts/utils/script_macro_base.gd'

var _ref: Node

func get_script_id() -> int:
	return -999

func get_inputs() -> Array:
	return []

func get_outputs() -> Array:
	return []

func get_flow_inputs() -> Array:
	return [{ name = 'Exec', id = 0 }]

func get_flow_outputs() -> Array:
	return [{ name = 'Out', id = 0 }]

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
extends 'res://addons/hengo/scripts/utils/script_macro_base.gd'

var _ref: Node

func get_inputs() -> Array:
	return [ {name = 'duration', type = 'float'}]

func get_outputs() -> Array:
	return []

func get_flow_inputs() -> Array:
	return [ {name = 'Exec', id = 0}]

func get_flow_outputs() -> Array:
	return [ {name = 'Out', id = 0}]

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

	var expected_prop_name = "duration_" + str(macro_vc.id)
	
	assert_str(code).contains("self.set_meta('" + expected_prop_name + "', 5.0)")
	assert_str(code).not_contains("%5.0%")