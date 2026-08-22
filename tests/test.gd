class_name HenTest extends RefCounted


static func get_all_code() -> String:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var code_generation: HenCodeGeneration = Engine.get_singleton(&'CodeGeneration')
	var save_data: HenSaveData = global.SAVE_DATA

	# this is a hack to make the tests errors accurate only for code generation
	global.SAVE_DATA = null
	ProjectSettings.set_setting(HenSettings.DEBUG_COMPILATION_PATH, false)
	var code: String = code_generation.get_code(save_data)
	global.SAVE_DATA = save_data
	return code

