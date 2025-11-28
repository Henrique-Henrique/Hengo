@tool
class_name HenSaveDataIdentity extends Resource

@export var id: StringName
@export var type: StringName
@export var name: String

static func create(_id: StringName, _type: StringName, _name: String) -> HenSaveDataIdentity:
    var identity: HenSaveDataIdentity = HenSaveDataIdentity.new()
    identity.id = _id
    identity.type = _type
    identity.name = _name
    return identity
