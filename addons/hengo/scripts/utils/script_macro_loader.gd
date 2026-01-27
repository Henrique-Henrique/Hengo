@tool
class_name HenScriptMacroLoader extends RefCounted

const MACRO_PATH: String = 'res://hengo/macros'

static func load_script_macros() -> void:
	# loads script macros from the designated directory
	var global: HenGlobal = Engine.get_singleton(&'Global')
	
	if not global.SAVE_DATA:
		return
	
	if not DirAccess.dir_exists_absolute(MACRO_PATH):
		DirAccess.make_dir_absolute(MACRO_PATH)
		return
	
	_clear_existing_script_macros(global)
	
	var dir: DirAccess = DirAccess.open(MACRO_PATH)
	if dir:
		dir.list_dir_begin()
		var file_name: String = dir.get_next()
		while file_name != '':
			if not dir.current_is_dir() and file_name.ends_with('.gd'):
				_load_macro_script(MACRO_PATH + '/' + file_name, global)
			file_name = dir.get_next()


static func _clear_existing_script_macros(global: HenGlobal) -> void:
	# resets the global script macro list
	global.script_macros.clear()


static func _load_macro_script(path: String, global: HenGlobal) -> void:
	# instantiates the macro script to parse its metadata into a hensavemacro
	var script: GDScript = load(path)
	if not script:
		return

	var instance: HenScriptMacroBase = script.new() as HenScriptMacroBase
	if not instance:
		return

	var macro: HenSaveMacro = HenSaveMacro.create()
	macro.name = path.get_file().get_basename()
	macro.is_script_macro = true
	macro.script_path = path
	
	for input: Dictionary in instance.get_inputs():
		var param: HenSaveParam = HenSaveParam.create(input)
		macro.inputs.append(param)

	for output: Dictionary in instance.get_outputs():
		var param: HenSaveParam = HenSaveParam.create(output)
		macro.outputs.append(param)

	for flow_input: Dictionary in instance.get_flow_inputs():
		var param: HenSaveParam = HenSaveParam.create(flow_input)
		macro.flow_inputs.append(param)

	for flow_output: Dictionary in instance.get_flow_outputs():
		var param: HenSaveParam = HenSaveParam.create(flow_output)
		macro.flow_outputs.append(param)
			
	var target_list: Array[HenSaveMacro] = global.script_macros
	target_list.append(macro)