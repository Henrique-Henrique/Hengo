@tool
class_name HenNodePaths extends RefCounted

const CACHE_SECONDS: int = 10
const PATH_LIMIT: int = 300

# script path -> { at: unix seconds, list: Array[Dictionary] }
static var _cache: Dictionary = {}


# { path, type, label, partial } for every node reachable from where this script
# is attached, empty when no scene holds it
static func entries(_save_data: HenSaveData, _type: StringName = &'') -> Array[Dictionary]:
	if not _save_data:
		return []

	var script_path: String = HenUtils.script_path_of(_save_data.identity)

	if script_path.is_empty():
		return []

	var list: Array[Dictionary] = []

	for entry: Dictionary in _cached(script_path):
		if _accepts(_type, StringName(str(entry.type))):
			list.append(entry)

	return list


static func invalidate() -> void:
	_cache.clear()


static func _cached(_script_path: String) -> Array[Dictionary]:
	var cached: Dictionary = _cache.get(_script_path, {})

	if not cached.is_empty() and Time.get_unix_time_from_system() - float(cached.at) < CACHE_SECONDS:
		return cached.list

	var list: Array[Dictionary] = _collect(_script_path)
	_cache[_script_path] = {at = Time.get_unix_time_from_system(), list = list}

	return list


# a binary .scn never matches the text scan, and typing the path stays available
static func _collect(_script_path: String) -> Array[Dictionary]:
	var mounts: Array[Dictionary] = []

	for scene_path: String in HenSlotPickers.entries(HenSlotPickers.SCENE_PATH):
		if not FileAccess.get_file_as_string(scene_path).contains(_script_path):
			continue

		# CACHE_MODE_IGNORE: a cached scene outlives this cache and would miss a node
		# added since the editor opened it
		var packed: PackedScene = ResourceLoader.load(scene_path, 'PackedScene', ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
		var state: SceneState = packed.get_state() if packed else null

		if not state:
			continue

		for i: int in state.get_node_count():
			if _script_of(state, i) != _script_path:
				continue

			mounts.append({
				owner = scene_path.get_file() + ':' + str(state.get_node_path(i)).trim_prefix('./'),
				nodes = _reachable(state, i)
			})

	return _merge(mounts)


# a path that resolves from every attachment comes first: codegen emits one
# get_node() for all of them
static func _merge(_mounts: Array[Dictionary]) -> Array[Dictionary]:
	var seen: Dictionary = {}

	for mount: Dictionary in _mounts:
		var nodes: Dictionary = mount.nodes

		for path: String in nodes:
			var entry: Dictionary = seen.get(path, {type = nodes[path], owners = []})
			(entry.owners as Array).append(mount.owner)
			seen[path] = entry

	var list: Array[Dictionary] = []

	for path: String in seen:
		var entry: Dictionary = seen[path]
		var partial: bool = (entry.owners as Array).size() < _mounts.size()

		list.append({
			path = path,
			type = str(entry.type),
			partial = partial,
			label = _label(path, str(entry.type), partial, entry.owners)
		})

	list.sort_custom(_before)

	return list.slice(0, PATH_LIMIT)


static func _label(_path: String, _type: String, _partial: bool, _owners: Array) -> String:
	var label: String = _path

	if not _type.is_empty():
		label += '  (' + _type + ')'

	if _partial:
		label += '  only in ' + ', '.join(PackedStringArray(_owners))

	return label


static func _before(_a: Dictionary, _b: Dictionary) -> bool:
	if bool(_a.partial) != bool(_b.partial):
		return not _a.partial

	var a_up: bool = str(_a.path).begins_with('..')
	var b_up: bool = str(_b.path).begins_with('..')

	if a_up != b_up:
		return b_up

	return str(_a.path) < str(_b.path)


# an instanced sub-scene contributes its root only, its children are not in this state
static func _reachable(_state: SceneState, _owner: int) -> Dictionary:
	var out: Dictionary = {}
	var from: PackedStringArray = _segments(_state.get_node_path(_owner))

	for i: int in _state.get_node_count():
		if i == _owner:
			continue

		var path: String = _relative(from, _segments(_state.get_node_path(i)))

		if path.is_empty():
			continue

		var type: String = str(_state.get_node_type(i))
		out[path] = type

		if _is_unique(_state, i):
			out['%' + str(_state.get_node_name(i))] = type

	return out


# get_node_path() prefixes every path with "./", the root being "." alone
static func _segments(_path: NodePath) -> PackedStringArray:
	var text: String = str(_path).trim_prefix('./')

	if text.is_empty() or text == '.':
		return PackedStringArray()

	return text.split('/')


static func _relative(_from: PackedStringArray, _to: PackedStringArray) -> String:
	var common: int = 0

	while common < _from.size() and common < _to.size() and _from[common] == _to[common]:
		common += 1

	var parts: PackedStringArray = PackedStringArray()

	for _i: int in range(_from.size() - common):
		parts.append('..')

	for i: int in range(common, _to.size()):
		parts.append(_to[i])

	return '/'.join(parts)


static func _script_of(_state: SceneState, _idx: int) -> String:
	var value: Variant = _property(_state, _idx, 'script')

	return (value as Resource).resource_path if value is Resource else ''


static func _is_unique(_state: SceneState, _idx: int) -> bool:
	return _property(_state, _idx, 'unique_name_in_owner') == true


static func _property(_state: SceneState, _idx: int, _name: String) -> Variant:
	for p: int in _state.get_node_property_count(_idx):
		if str(_state.get_node_property_name(_idx, p)) == _name:
			return _state.get_node_property_value(_idx, p)

	return null


# get_node_type() is empty for an instanced or class_name node, and a missing row
# is worse than a wrong one
static func _accepts(_slot_type: StringName, _node_type: StringName) -> bool:
	if _slot_type.is_empty() or _slot_type == &'Variant' or _slot_type == &'Node':
		return true

	if _node_type.is_empty() or not ClassDB.class_exists(_slot_type):
		return true

	return ClassDB.is_parent_class(_node_type, _slot_type)
