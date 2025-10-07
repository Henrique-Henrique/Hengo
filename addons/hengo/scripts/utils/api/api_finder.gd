@tool
class_name HenApiFinder extends RefCounted

const EXTENSION_API_PATH = 'res://.godot/hengo/extension_api.json'
const HENGO_CACHE_PATH = 'res://.godot/hengo/'

static func map_api() -> void:
	var file: FileAccess = get_api_file()

	if not file:
		print('Not Found extension_api.json.')
		return

	var data: Dictionary = JSON.parse_string(file.get_as_text())

	check_cache_dir()

	if data.has(&'classes'):
		for value: Dictionary in data.get(&'classes'):
			save_class_api(value)


static func check_cache_dir() -> void:
	if not DirAccess.dir_exists_absolute(HENGO_CACHE_PATH):
		DirAccess.make_dir_absolute(HENGO_CACHE_PATH)

	if not DirAccess.dir_exists_absolute(HENGO_CACHE_PATH + '/api'):
		DirAccess.make_dir_absolute(HENGO_CACHE_PATH + '/api')

	if not DirAccess.dir_exists_absolute(HENGO_CACHE_PATH + '/api/classes'):
		DirAccess.make_dir_absolute(HENGO_CACHE_PATH + '/api/classes')


static func save_class_api(_obj: Dictionary) -> void:
	var file: FileAccess = FileAccess.open(HENGO_CACHE_PATH + '/api/classes/' + _obj.name, FileAccess.WRITE)
	file.store_string(JSON.stringify(_obj))
	file.close()


static func get_api_file() -> FileAccess:
	print('Generating Godot Native Api...')
	print('Dumping Godot Extension Api...')
	if FileAccess.file_exists(EXTENSION_API_PATH):
		print('Found extension_api.json')
		return FileAccess.open(EXTENSION_API_PATH, FileAccess.READ)

	var output: Array = []
	OS.execute(OS.get_executable_path(), ['-q', '--headless', '--dump-extension-api-with-docs', '--path', '.godot/hengo/'], output)

	if FileAccess.file_exists(EXTENSION_API_PATH):
		print('Found extension_api.json')
		return FileAccess.open(EXTENSION_API_PATH, FileAccess.READ)
	
	print('Not Found extension_api.json.')
	return null


static func get_class_api(_class: StringName) -> void:
	var file: FileAccess = FileAccess.open(HENGO_CACHE_PATH + '/api/classes/' + _class, FileAccess.READ)
	var data: Dictionary = JSON.parse_string(file.get_as_text())

	file.close()
