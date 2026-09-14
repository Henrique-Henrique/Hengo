@tool
class_name HenScriptBaseType extends RefCounted


# the generated script runs _ready and _process, so only a node can be its base
static func is_valid_base(_class: StringName) -> bool:
	return ClassDB.class_exists(_class) and ClassDB.is_parent_class(_class, &'Node')


static func preview(_save_data: HenSaveData, _class: StringName) -> Array[Dictionary]:
	var current: StringName = _save_data.identity.type
	var before: Dictionary = {}

	for err: Dictionary in HenGeneratorAction.collect_errors(_save_data):
		before[_error_key(err)] = true

	_save_data.identity.type = _class

	var after: Array[Dictionary] = HenGeneratorAction.collect_errors(_save_data)

	_save_data.identity.type = current

	return after.filter(func(err: Dictionary) -> bool: return not before.has(_error_key(err)))


static func apply(_save_data: HenSaveData, _class: StringName) -> void:
	var identity: HenSaveDataIdentity = _save_data.identity

	identity.type = _class

	var dir: String = HenUtils.get_script_dir(identity.id)

	if not dir.is_empty():
		ResourceSaver.save(identity, dir.path_join(HenEnums.IDENTITY_FILE))

	_retype_references(identity.id, _class)
	HenActionPool.invalidate()

	if Engine.has_singleton(&'MapDependencies'):
		(Engine.get_singleton(&'MapDependencies') as HenMapDependencies).update_project_data_from_save(identity.id, _save_data)


# a variable holding another script stores a copy of that script's base class
static func _retype_references(_script_id: StringName, _class: StringName) -> void:
	if not Engine.has_singleton(&'MapDependencies'):
		return

	var map_deps: HenMapDependencies = Engine.get_singleton(&'MapDependencies')

	for id: StringName in map_deps.ast_list:
		if id == _script_id:
			continue

		for variable: HenSaveVar in map_deps.ast_list[id].variables:
			if variable.script_id != _script_id or variable.type == _class:
				continue

			variable.type = _class

			if not variable.resource_path.is_empty():
				ResourceSaver.save(variable)


static func _error_key(_err: Dictionary) -> String:
	return '%s/%s/%s/%s' % [_err.get('script_id', ''), _err.get('state_id', ''), _err.get('action_id', ''), _err.get('reason', '')]
