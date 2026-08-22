@tool
class_name HenSaveSignalCallback extends HenSaveResTypeWithRoute

@export var params: Array[HenSaveParam]
@export var bind_params: Array[HenSaveParam]
@export var type: StringName
@export var signal_name: StringName
@export var signal_name_to_code: StringName


func get_new_name() -> String:
	return 'signal_callback_' + str(id)

