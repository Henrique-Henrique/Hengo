@tool
class_name HenSaveDataIdentity extends Resource

@export var id: StringName
@export var type: StringName
@export var name: String
@export var script_path: String
@export var deps: Array[StringName]
@export var detailed_deps: Dictionary


static func create(_id: StringName, _type: StringName, _name: String) -> HenSaveDataIdentity:
	var identity: HenSaveDataIdentity = HenSaveDataIdentity.new()
	identity.id = _id
	identity.type = _type
	identity.name = _name
	return identity
