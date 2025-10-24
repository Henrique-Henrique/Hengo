@tool
class_name HenMapDependencies extends Node

const SAVE_PATH: String = "res://hengo/save/"
var dependencies: Dictionary = {}


func start_map() -> void:
	# ensure a clean state for each run
	dependencies.clear()

	var script_files: Array = _get_script_files_from_dir(SAVE_PATH)
	if script_files.is_empty():
		push_warning("no '.hengo' files found in the specified path: " + SAVE_PATH)
		return

	for file_path: String in script_files:
		_process_script_file(file_path)
	

func _get_script_files_from_dir(path: String) -> Array:
	var files: Array = []
	var dir: DirAccess = DirAccess.open(path)

	if not dir:
		(Engine.get_singleton(&'SignalBus') as HenSignalBus).set_terminal_text.emit.call_deferred(HenUtils.get_error_text("failed to open directory: " + path))
		return files

	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		# skip directories and hidden files
		if not dir.current_is_dir() and file_name.get_extension() == "hengo":
			files.append(path.path_join(file_name))
		file_name = dir.get_next()
	
	dir.list_dir_end()
	return files


func _process_script_file(file_path: String) -> void:
	var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_warning("could not open file: " + file_path)
		return

	var text_content: String = file.get_as_text()
	file.close()

	var parse_result: Variant = JSON.parse_string(text_content)
	if parse_result == null:
		push_warning("json parsing failed for file: " + file_path.get_file())
		return

	if typeof(parse_result) != TYPE_DICTIONARY:
		push_warning("parsed json is not a dictionary in file: " + file_path.get_file())
		return

	var data: Dictionary = parse_result
	if data.is_empty():
		push_warning("json data is empty in file: " + file_path.get_file())
		return

	# assuming hengo script data is always valid after json parsing
	var script_data: HenScriptData = HenScriptData.load(data)
	var dependent_id: StringName = file_path.get_file().get_basename()

	for dependency_id: StringName in script_data.deps:
		_register_dependency(dependency_id, dependent_id)
	
	var map_objects: HenMapObjects = Engine.get_singleton(&'MapObjects')
	map_objects.map_script_data(dependent_id, script_data)


func _register_dependency(dependency_id: StringName, dependent_id: StringName) -> void:
	if not dependencies.has(dependency_id):
		dependencies[dependency_id] = []

	# prevent duplicate entries
	var dependents: Array = dependencies[dependency_id]

	if not dependents.has(dependent_id):
		dependents.append(dependent_id)


# get all dependencies for a given script
func get_dependencies(_script_id: StringName) -> Array:
	return dependencies.get(_script_id, [])
