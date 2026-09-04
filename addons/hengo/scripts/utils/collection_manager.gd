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
	var path: String = HenEnums.HENGO_COLLECTION_PATH.path_join(_collection_id)
	if DirAccess.dir_exists_absolute(path):
		OS.move_to_trash(ProjectSettings.globalize_path(path))
	HenUtils.rebuild_script_index()
