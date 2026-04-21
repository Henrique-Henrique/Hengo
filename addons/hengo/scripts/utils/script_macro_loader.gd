@tool
class_name HenScriptMacroLoader extends RefCounted

const MACRO_PATH: String = 'res://hengo/macros'

# path -> { mtime: int, id: StringName, inputs: Array, outputs: Array, flow_inputs: Array, flow_outputs: Array }
static var _cache: Dictionary = {}


static func load_script_macros() -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')

	if not global.SAVE_DATA:
		return

	if not DirAccess.dir_exists_absolute(MACRO_PATH):
		DirAccess.make_dir_absolute(MACRO_PATH)
		return

	global.script_macros.clear()

	var dir: DirAccess = DirAccess.open(MACRO_PATH)
	if not dir:
		return

	var seen_paths: Array[String] = []
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != '':
		if not dir.current_is_dir() and file_name.ends_with('.gd'):
			var path: String = MACRO_PATH + '/' + file_name
			seen_paths.append(path)
			_load_macro_script(path, global)
		file_name = dir.get_next()

	# evict cache entries for deleted files
	for cached_path: String in _cache.keys():
		if not seen_paths.has(cached_path):
			_cache.erase(cached_path)


static func _load_macro_script(path: String, global: HenGlobal) -> void:
	var mtime: int = FileAccess.get_modified_time(path)
	var cached: Variant = _cache.get(path)

	var recipe: Dictionary
	if cached and (cached as Dictionary).get('mtime') == mtime:
		recipe = cached as Dictionary
	else:
		var script: GDScript = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REUSE)
		if not script:
			return
		var instance: HenScriptMacroBase = script.new() as HenScriptMacroBase
		if not instance:
			return
		recipe = {
			mtime = mtime,
			id = instance.get_id(),
			inputs = instance.get_inputs(),
			outputs = instance.get_outputs(),
			flow_inputs = instance.get_flow_inputs(),
			flow_outputs = instance.get_flow_outputs(),
		}
		_cache[path] = recipe

	var macro: HenSaveMacro = HenSaveMacro.create()
	macro.name = path.get_file().get_basename()
	macro.is_script_macro = true
	macro.script_path = path
	macro.id = recipe.id

	for input: Dictionary in recipe.inputs:
		macro.inputs.append(HenSaveParam.create(input))

	for output: Dictionary in recipe.outputs:
		macro.outputs.append(HenSaveParam.create(output))

	for flow_input: Dictionary in recipe.flow_inputs:
		macro.flow_inputs.append(HenSaveParam.create(flow_input))

	for flow_output: Dictionary in recipe.flow_outputs:
		macro.flow_outputs.append(HenSaveParam.create(flow_output))

	global.script_macros.append(macro)
