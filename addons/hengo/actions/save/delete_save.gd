@tool
class_name HenActionDeleteSave extends HenScriptMacroBase


func get_id() -> StringName:
	return &'delete_save'


func get_description() -> String:
	return 'Erases the save file, throwing away every value stored with Save Value. It is what a reset progress button does.'


func get_display_name() -> String:
	return 'Delete Save'


func get_icon() -> String:
	return 'trash-2'


func get_default_phase() -> StringName:
	return &'enter'


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'},
		{name = 'Exit', id = &'exit'}
	]


func get_flow_enter() -> String:
	return _body()


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


func get_flow_exit() -> String:
	return _body()


func _body() -> String:
	return 'DirAccess.remove_absolute("user://hengo_save.cfg")'
