@tool
class_name HenScriptMacroLoader extends RefCounted

const MACRO_PATH: String = 'res://hengo/macros'
const NATIVE_ACTION_PATH: String = 'res://addons/hengo/actions'

# path -> { mtime: int, id: StringName, inputs: Array, outputs: Array, flow_inputs: Array, flow_outputs: Array, inlinable: bool }
static var _cache: Dictionary = {}
# the recipes survive an editor restart here: cold, reading them back costs a file
# read against loading and instantiating every action script
const DISK_CACHE: String = 'user://hengo_macro_cache.txt'
# bump to throw every recipe away when the shape above changes
const DISK_CACHE_VERSION: int = 2
static var _disk_loaded: bool = false
static var _disk_dirty: bool = false


# a recipe is only reused while the file it came from is untouched, so a stale
# entry cannot outlive an edit
static func _load_disk_cache() -> void:
	if _disk_loaded:
		return

	_disk_loaded = true

	var file: FileAccess = FileAccess.open(DISK_CACHE, FileAccess.READ)

	if not file:
		return

	var stored: Variant = str_to_var(file.get_as_text())

	file.close()

	if not stored is Dictionary or int((stored as Dictionary).get('version', -1)) != DISK_CACHE_VERSION:
		return

	for path: Variant in (stored as Dictionary).get('recipes', {}):
		var recipe: Variant = (stored.recipes as Dictionary)[path]

		if recipe is Dictionary and FileAccess.file_exists(str(path)) 			and FileAccess.get_modified_time(str(path)) == int((recipe as Dictionary).get('mtime', -1)):
			_cache[str(path)] = recipe


static func _save_disk_cache() -> void:
	if not _disk_dirty:
		return

	_disk_dirty = false

	var file: FileAccess = FileAccess.open(DISK_CACHE, FileAccess.WRITE)

	if not file:
		return

	file.store_string(var_to_str({version = DISK_CACHE_VERSION, recipes = _cache}))
	file.close()


static func load_script_macros() -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')

	if not global.SAVE_DATA:
		return

	_load_disk_cache()

	global.script_macros.clear()
	HenActionsPanel.invalidate_macro_index()
	_scan_dir(MACRO_PATH, global, global.script_macros, true)
	_save_disk_cache()


# scans the plugin-native action definitions into a separate pool
static func load_native_actions() -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')

	if not global.SAVE_DATA:
		return

	_load_disk_cache()

	global.action_macros.clear()
	HenActionsPanel.invalidate_macro_index()
	_scan_dir(NATIVE_ACTION_PATH, global, global.action_macros, false)
	_save_disk_cache()


static func _scan_dir(base_path: String, global: HenGlobal, target: Array[HenSaveMacro], create_if_missing: bool) -> void:
	if not DirAccess.dir_exists_absolute(base_path):
		if create_if_missing:
			DirAccess.make_dir_absolute(base_path)
		return

	var seen_paths: Array[String] = []
	_scan_recursive(base_path, '', global, target, seen_paths)

	# evict cache entries for deleted files under this directory only
	for cached_path: String in _cache.keys():
		if cached_path.begins_with(base_path) and not seen_paths.has(cached_path):
			_cache.erase(cached_path)
			_disk_dirty = true


# walks a macro directory; a sub-directory name becomes the category of the
# scripts inside it, root files stay uncategorized
static func _scan_recursive(dir_path: String, category: String, global: HenGlobal, target: Array[HenSaveMacro], seen_paths: Array[String]) -> void:
	var dir: DirAccess = DirAccess.open(dir_path)
	if not dir:
		return

	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != '':
		var path: String = dir_path + '/' + file_name

		if dir.current_is_dir():
			if not file_name.begins_with('.'):
				_scan_recursive(path, category if not category.is_empty() else file_name, global, target, seen_paths)
		elif file_name.ends_with('.gd'):
			seen_paths.append(path)
			_load_macro_script(path, global, target, category)

		file_name = dir.get_next()


static func _load_macro_script(path: String, global: HenGlobal, target: Array[HenSaveMacro], category: String = '') -> void:
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
			display_name = instance.get_display_name(),
			description = instance.get_description(),
			icon = instance.get_icon(),
			color = instance.get_color(),
			inputs = instance.get_inputs(),
			outputs = instance.get_outputs(),
			flow_inputs = instance.get_flow_inputs(),
			flow_outputs = instance.get_flow_outputs(),
			target_classes = instance.get_target_classes(),
			default_phase = instance.get_default_phase(),
			has_body = instance.get_has_body(),
			inlinable = HenGeneratorAction.is_inlinable(instance),
		}
		_cache[path] = recipe
		_disk_dirty = true

	var macro: HenSaveMacro = HenSaveMacro.create()
	# human name: the macro's own, else the file name capitalized (set_value -> "Set Value")
	var display_name: String = str(recipe.get('display_name', ''))
	macro.name = display_name if not display_name.is_empty() else path.get_file().get_basename().capitalize()
	macro.description = str(recipe.get('description', ''))
	macro.is_script_macro = true
	macro.script_path = path
	macro.id = recipe.id
	macro.category = category
	macro.default_phase = StringName(str(recipe.get('default_phase', '')))
	macro.has_body = bool(recipe.get('has_body', false))
	macro.is_inlinable = bool(recipe.get('inlinable', false))
	# category supplies the presentation defaults; the macro's own declaration wins
	var category_data: Dictionary = HenActionCategories.get_data(category)
	macro.icon = str(recipe.get('icon', '')) if not str(recipe.get('icon', '')).is_empty() else str(category_data.icon)
	macro.color = str(recipe.get('color', '')) if not str(recipe.get('color', '')).is_empty() else str(category_data.color)

	for target_class: StringName in recipe.get('target_classes', [] as Array[StringName]):
		macro.target_classes.append(target_class)

	for input: Dictionary in recipe.inputs:
		macro.inputs.append(HenSaveParam.create(input))

	for output: Dictionary in recipe.outputs:
		macro.outputs.append(HenSaveParam.create(output))

	for flow_input: Dictionary in recipe.flow_inputs:
		macro.flow_inputs.append(HenSaveFlowParam.create(flow_input))

	for flow_output: Dictionary in recipe.flow_outputs:
		macro.flow_outputs.append(HenSaveFlowParam.create(flow_output))

	target.append(macro)
