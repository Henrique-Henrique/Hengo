extends HenTestSuite

const EXAMPLES_DIR: String = 'res://tools/examples'
# codegen marks an action it could not emit with this prefix
const UNRESOLVED: String = '# hengo: action '


func before_test() -> void:
	super ()
	HenScriptMacroLoader.load_native_actions()


func _example_paths() -> Array[String]:
	var paths: Array[String] = []

	for file_name: String in DirAccess.get_files_at(EXAMPLES_DIR):
		if file_name.get_extension() == 'json':
			paths.append(EXAMPLES_DIR.path_join(file_name))

	paths.sort()

	return paths


func _script_specs(_json: Dictionary) -> Array:
	var specs: Array = _json.get('scripts', [])

	return specs if not specs.is_empty() else [_json]


func _new_save_data(_spec: Dictionary) -> HenSaveData:
	var data: HenSaveData = HenSaveData.new()

	data.identity = HenSaveDataIdentity.create(str(ResourceUID.create_id()), StringName(str(_spec.get('extends', 'Node'))), str(_spec.get('name', '')).to_snake_case())
	data.counter = 1

	return data


# mirrors the passes of _generate in tools/hengo_cli.gd, so a cross-script branch
# finds the other script whatever order the json lists them
func _build_example(_path: String) -> Dictionary:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var map_deps: HenMapDependencies = Engine.get_singleton(&'MapDependencies')
	var json: Variant = JSON.parse_string(FileAccess.get_file_as_string(_path))

	if not json is Dictionary:
		return {error = 'invalid json'}

	var specs: Array = _script_specs(json as Dictionary)
	var all_scripts: Dictionary = {}
	var built: Array[HenSaveData] = []

	for spec: Dictionary in specs:
		var data: HenSaveData = _new_save_data(spec)

		all_scripts[str(data.identity.name)] = data
		built.append(data)

	for index: int in built.size():
		global.SAVE_DATA = built[index]
		var err: String = HenHengoActions.declare(built[index], specs[index])

		if not err.is_empty():
			return {error = str(built[index].identity.name) + ': ' + err}

	for index: int in built.size():
		global.SAVE_DATA = built[index]
		map_deps.ast_list.set(built[index].identity.id, HenUtils.get_current_ast_list())
		var err: String = HenHengoActions.build_actions(built[index], specs[index], all_scripts)

		if not err.is_empty():
			return {error = str(built[index].identity.name) + ': ' + err}

	for data: HenSaveData in built:
		global.SAVE_DATA = data
		map_deps.ast_list.set(data.identity.id, HenUtils.get_current_ast_list())

	return {error = '', scripts = built}


func test_there_are_at_least_four_examples() -> void:
	assert_int(_example_paths().size()).is_greater_equal(4)


func test_every_example_builds_without_errors() -> void:
	for path: String in _example_paths():
		var result: Dictionary = _build_example(path)

		assert_str(str(result.error)).override_failure_message(path + ': ' + str(result.error)).is_empty()


func test_every_example_emits_every_action() -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')

	for path: String in _example_paths():
		var result: Dictionary = _build_example(path)

		if not str(result.error).is_empty():
			continue

		for data: HenSaveData in result.scripts:
			global.SAVE_DATA = data
			var code: String = HenTest.get_all_code()

			assert_str(code).override_failure_message(path + ' (' + str(data.identity.name) + ') has an unresolved action').not_contains(UNRESOLVED)
