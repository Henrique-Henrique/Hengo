@tool
class_name TestHenMacroCache extends HenTestSuite

# the recipes are read back from disk instead of loading every action script, so
# what matters is that the pool comes out identical either way


func _reset(_drop_file: bool) -> void:
	HenScriptMacroLoader._cache.clear()
	HenScriptMacroLoader._disk_loaded = false
	HenScriptMacroLoader._disk_dirty = false

	if _drop_file and FileAccess.file_exists(HenScriptMacroLoader.DISK_CACHE):
		DirAccess.remove_absolute(HenScriptMacroLoader.DISK_CACHE)


func _digest() -> String:
	var parts: Array = []

	for macro: HenSaveMacro in (Engine.get_singleton(&'Global') as HenGlobal).action_macros:
		parts.append([
			macro.name,
			str(macro.id),
			macro.category,
			macro.icon,
			macro.color,
			str(macro.default_phase),
			macro.target_classes,
			_params(macro.inputs),
			_params(macro.outputs),
			_flow(macro.flow_inputs),
			_flow(macro.flow_outputs)
		])

	return var_to_str(parts)


func _params(_list: Array) -> Array:
	var out: Array = []

	for param: HenSaveParam in _list:
		out.append([str(param.id), str(param.type), param.name, var_to_str(param.default_value), param.options, param.lvalue, param.bind_only, param.optional, param.raw, param.doc])

	return out


func _flow(_list: Array) -> Array:
	var out: Array = []

	for param: HenSaveFlowParam in _list:
		out.append([str(param.id), param.name])

	return out


func test_the_disk_cache_rebuilds_the_same_pool() -> void:
	_reset(true)
	HenScriptMacroLoader.load_native_actions()

	var from_scripts: String = _digest()
	var count: int = (Engine.get_singleton(&'Global') as HenGlobal).action_macros.size()

	assert_int(count).is_greater(100)
	assert_bool(FileAccess.file_exists(HenScriptMacroLoader.DISK_CACHE)).is_true()

	# only the in-memory side is dropped: the next load has to come off the file
	HenScriptMacroLoader._cache.clear()
	HenScriptMacroLoader._disk_loaded = false

	HenScriptMacroLoader.load_native_actions()

	assert_int((Engine.get_singleton(&'Global') as HenGlobal).action_macros.size()).is_equal(count)
	assert_str(_digest()).is_equal(from_scripts)


# a recipe is keyed by the file's modified time, so an edited action is read
# from the script again instead of from the cache
func test_a_touched_file_drops_its_recipe() -> void:
	_reset(true)
	HenScriptMacroLoader.load_native_actions()

	var path: String = HenScriptMacroLoader._cache.keys()[0]

	(HenScriptMacroLoader._cache[path] as Dictionary).mtime = 1

	HenScriptMacroLoader._disk_dirty = true
	HenScriptMacroLoader._save_disk_cache()
	HenScriptMacroLoader._cache.clear()
	HenScriptMacroLoader._disk_loaded = false
	HenScriptMacroLoader._load_disk_cache()

	assert_bool(HenScriptMacroLoader._cache.has(path)).is_false()


func test_a_version_bump_throws_the_file_away() -> void:
	_reset(true)
	HenScriptMacroLoader.load_native_actions()

	var file: FileAccess = FileAccess.open(HenScriptMacroLoader.DISK_CACHE, FileAccess.WRITE)

	file.store_string(var_to_str({version = HenScriptMacroLoader.DISK_CACHE_VERSION - 1, recipes = {}}))
	file.close()

	HenScriptMacroLoader._cache.clear()
	HenScriptMacroLoader._disk_loaded = false
	HenScriptMacroLoader._load_disk_cache()

	assert_bool(HenScriptMacroLoader._cache.is_empty()).is_true()


func test_a_corrupt_file_is_ignored() -> void:
	_reset(true)

	var file: FileAccess = FileAccess.open(HenScriptMacroLoader.DISK_CACHE, FileAccess.WRITE)

	file.store_string('not a variant at all {{{')
	file.close()

	HenScriptMacroLoader._load_disk_cache()
	HenScriptMacroLoader.load_native_actions()

	assert_int((Engine.get_singleton(&'Global') as HenGlobal).action_macros.size()).is_greater(100)
