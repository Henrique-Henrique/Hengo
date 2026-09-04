@tool
class_name HenSlotPickers extends RefCounted

const INPUT_ACTION: StringName = &'input_action'
const AUDIO_BUS: StringName = &'audio_bus'
const SCENE_PATH: StringName = &'scene_path'
const GROUP: StringName = &'group'

const SCAN_LIMIT: int = 400
const CACHE_SECONDS: int = 10

# picker -> { at: unix seconds, list: Array[String] }
static var _cache: Dictionary = {}


static func has(_picker: StringName) -> bool:
	return _picker in [INPUT_ACTION, AUDIO_BUS, SCENE_PATH, GROUP]


static func entries(_picker: StringName) -> Array[String]:
	var cached: Dictionary = _cache.get(_picker, {})

	if not cached.is_empty() and Time.get_unix_time_from_system() - float(cached.at) < CACHE_SECONDS:
		return cached.list

	var list: Array[String] = []

	match _picker:
		INPUT_ACTION:
			list = _input_actions()
		AUDIO_BUS:
			list = _audio_buses()
		SCENE_PATH:
			list = _scenes()
		GROUP:
			list = _groups()

	_cache[_picker] = {at = Time.get_unix_time_from_system(), list = list}

	return list


static func invalidate() -> void:
	_cache.clear()


# InputMap in the editor holds the editor's own actions too, so the project
# settings are the only list that matches what the game will see
static func _input_actions() -> Array[String]:
	var list: Array[String] = []

	for property: Dictionary in ProjectSettings.get_property_list():
		var name: String = str(property.name)

		if name.begins_with('input/'):
			list.append(name.substr(name.find('/') + 1))

	list.sort()

	return list


static func _audio_buses() -> Array[String]:
	var list: Array[String] = []

	for i: int in range(AudioServer.bus_count):
		list.append(AudioServer.get_bus_name(i))

	return list


static func _scenes() -> Array[String]:
	var list: Array[String] = []
	_walk('res://', list, func(_path: String) -> String: return _path if _path.ends_with('.tscn') else '')
	list.sort()

	return list


static func _groups() -> Array[String]:
	var scenes: Array[String] = _scenes()
	var seen: Dictionary = {}

	for path: String in scenes:
		var file: FileAccess = FileAccess.open(path, FileAccess.READ)

		if not file:
			continue

		while not file.eof_reached():
			var line: String = file.get_line()

			if not line.begins_with('groups = ['):
				continue

			for chunk: String in line.trim_prefix('groups = [').trim_suffix(']').split(','):
				var name: String = chunk.strip_edges().trim_prefix('"').trim_suffix('"')

				if not name.is_empty():
					seen[name] = true

		file.close()

	var list: Array[String] = []

	for name: String in seen:
		list.append(name)

	list.sort()

	return list


static func _walk(_dir_path: String, _out: Array[String], _keep: Callable) -> void:
	if _out.size() >= SCAN_LIMIT:
		return

	var dir: DirAccess = DirAccess.open(_dir_path)

	if not dir:
		return

	dir.list_dir_begin()
	var entry: String = dir.get_next()

	while not entry.is_empty():
		var path: String = _dir_path.path_join(entry)

		if dir.current_is_dir():
			if not entry.begins_with('.') and entry != 'addons':
				_walk(path, _out, _keep)
		else:
			var kept: String = str(_keep.call(path))

			if not kept.is_empty() and _out.size() < SCAN_LIMIT:
				_out.append(kept)

		entry = dir.get_next()

	dir.list_dir_end()
