@tool
class_name HenCollectionManager extends RefCounted


# creates a new collection folder + manifest and returns the resource
static func create_collection(_name: String) -> HenSaveCollection:
	var id: int = ResourceUID.create_id()
	var dir_path: String = HenEnums.HENGO_COLLECTION_PATH.path_join(str(id))

	if not DirAccess.dir_exists_absolute(dir_path):
		DirAccess.make_dir_recursive_absolute(dir_path)

	var collection: HenSaveCollection = HenSaveCollection.create(StringName(str(id)), _name)
	collection.take_over_path(dir_path.path_join(HenEnums.COLLECTION_FILE))
	ResourceSaver.save(collection)

	return collection


# persists the active collection manifest to disk
static func save_active_collection() -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	if global.ACTIVE_COLLECTION:
		ResourceSaver.save(global.ACTIVE_COLLECTION)


# returns the active collection, creating a default one when none is open
static func ensure_active_collection() -> HenSaveCollection:
	var global: HenGlobal = Engine.get_singleton(&'Global')

	if not global.ACTIVE_COLLECTION:
		global.ACTIVE_COLLECTION = create_collection('Default')
		global.OPEN_SCRIPTS = []

	return global.ACTIVE_COLLECTION


# returns the absolute folder of the active collection
static func get_active_collection_dir() -> String:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	if not global.ACTIVE_COLLECTION:
		return ''
	return HenEnums.HENGO_COLLECTION_PATH.path_join(global.ACTIVE_COLLECTION.id)


# deletes a collection folder and all its scripts
static func delete_collection(_collection_id: StringName) -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var path: String = HenEnums.HENGO_COLLECTION_PATH.path_join(_collection_id)
	var collection_path: String = path.path_join(HenEnums.COLLECTION_FILE)
	var is_active: bool = global.ACTIVE_COLLECTION != null and global.ACTIVE_COLLECTION.id == _collection_id
	var collection: HenSaveCollection = global.ACTIVE_COLLECTION if is_active else null

	if not collection and FileAccess.file_exists(collection_path):
		collection = ResourceLoader.load(collection_path)

	var script_ids: Array[StringName] = collection.script_ids.duplicate() if collection else ([] as Array[StringName])

	for script_id: StringName in script_ids:
		_trash_compiled(_identity_of(script_id))

	if is_active:
		global.ACTIVE_COLLECTION = null
		global.OPEN_SCRIPTS.clear()
		global.SAVE_DATA = null

	for script_id: StringName in script_ids:
		_release_script(script_id)

	if DirAccess.dir_exists_absolute(path):
		OS.move_to_trash(ProjectSettings.globalize_path(path))

	_after_removal(is_active)


static func delete_script(_script_id: StringName) -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var dir: String = HenUtils.get_script_dir(_script_id)
	var was_active: bool = global.SAVE_DATA != null and global.SAVE_DATA.identity.id == _script_id

	_trash_compiled(_identity_of(_script_id))

	var collection: HenSaveCollection = global.ACTIVE_COLLECTION

	if not collection or not collection.script_ids.has(_script_id):
		collection = _collection_of_dir(dir)

	if collection:
		collection.remove_script(_script_id)

		if not collection.resource_path.is_empty():
			ResourceSaver.save(collection)

	for save_data: HenSaveData in global.OPEN_SCRIPTS.duplicate():
		if save_data.identity.id == _script_id:
			global.OPEN_SCRIPTS.erase(save_data)

	if was_active:
		var next: HenSaveData = null if global.OPEN_SCRIPTS.is_empty() else global.OPEN_SCRIPTS[0]

		# switching first parks the route that the release then drops
		if next:
			(Engine.get_singleton(&'Loader') as HenLoader).set_active_script(next)
		else:
			global.SAVE_DATA = null

	_release_script(_script_id)

	if not dir.is_empty() and DirAccess.dir_exists_absolute(dir):
		OS.move_to_trash(ProjectSettings.globalize_path(dir))

	_after_removal(was_active and global.SAVE_DATA == null)


static func scripts_referencing(_script_id: StringName) -> Array[String]:
	var map_deps: HenMapDependencies = Engine.get_singleton(&'MapDependencies')
	var names: Array[String] = []

	for id: StringName in map_deps.ast_list:
		var ast: HenMapDependencies.ProjectAST = map_deps.ast_list[id]

		if id == _script_id or not ast.identity:
			continue

		for variable: HenSaveVar in ast.variables:
			if variable.script_id == _script_id:
				names.append(ast.identity.name)
				break

	return names


static func _identity_of(_script_id: StringName) -> HenSaveDataIdentity:
	var global: HenGlobal = Engine.get_singleton(&'Global')

	for save_data: HenSaveData in global.OPEN_SCRIPTS:
		if save_data.identity.id == _script_id:
			return save_data.identity

	var map_deps: HenMapDependencies = Engine.get_singleton(&'MapDependencies')
	var ast: HenMapDependencies.ProjectAST = map_deps.ast_list.get(_script_id)

	if ast and ast.identity:
		return ast.identity

	var identity_path: String = HenUtils.get_script_dir(_script_id).path_join(HenEnums.IDENTITY_FILE)

	return ResourceLoader.load(identity_path) if FileAccess.file_exists(identity_path) else null


static func _collection_of_dir(_script_dir: String) -> HenSaveCollection:
	if _script_dir.is_empty():
		return null

	var path: String = _script_dir.get_base_dir().path_join(HenEnums.COLLECTION_FILE)

	return ResourceLoader.load(path) if FileAccess.file_exists(path) else null


# a compiled script left behind keeps running in scenes with no source to edit
static func _trash_compiled(_identity: HenSaveDataIdentity) -> void:
	if not _identity:
		return

	var script_path: String = HenUtils.script_path_of(_identity)

	for path: String in [script_path, script_path + '.uid']:
		if FileAccess.file_exists(path):
			OS.move_to_trash(ProjectSettings.globalize_path(path))


static func _release_script(_script_id: StringName) -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var id: String = String(_script_id)

	global.ROUTE_VIEWS.erase(id)

	for key: Variant in global.CAM_VIEWS.keys():
		if str(key) == id or str(key).begins_with(id + '/'):
			global.CAM_VIEWS.erase(key)

	if global.ROUTE_OWNER == id:
		global.ROUTE_OWNER = ''
		HenRoute.set_stack([])

	(Engine.get_singleton(&'MapDependencies') as HenMapDependencies).ast_list.erase(_script_id)


static func _after_removal(_cleared_active: bool) -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var signal_bus: HenSignalBus = Engine.get_singleton(&'SignalBus')

	HenUtils.rebuild_script_index()
	HenActionPool.invalidate()

	if global.HENGO_ROOT:
		if _cleared_active:
			global.HENGO_ROOT.refresh_script_state()

		global.HENGO_ROOT.schedule_check_errors()

	signal_bus.request_list_update.emit()
	signal_bus.request_structural_update.emit()

	if Engine.is_editor_hint() and not global.IS_HEADLESS:
		EditorInterface.get_resource_filesystem().scan()
