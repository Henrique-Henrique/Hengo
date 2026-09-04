@tool
class_name HenSaveCollection extends Resource

@export var id: StringName
@export var name: String
@export var script_ids: Array[StringName] = []
@export var last_active_id: StringName = &''


static func create(_id: StringName, _name: String) -> HenSaveCollection:
	var collection: HenSaveCollection = HenSaveCollection.new()
	collection.id = _id
	collection.name = _name
	return collection


func add_script(_script_id: StringName) -> void:
	if not script_ids.has(_script_id):
		script_ids.append(_script_id)


func remove_script(_script_id: StringName) -> void:
	script_ids.erase(_script_id)
	if last_active_id == _script_id:
		last_active_id = script_ids[0] if not script_ids.is_empty() else &''
