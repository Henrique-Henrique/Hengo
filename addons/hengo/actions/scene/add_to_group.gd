@tool
class_name HenActionAddToGroup extends HenScriptMacroBase


# tags the owner with a group name, the usual way to mark "this is an enemy".


func get_id() -> StringName:
	return &'add_to_group'


func get_display_name() -> String:
	return 'Add To Group'


func get_icon() -> String:
	return 'users'


func get_default_phase() -> StringName:
	return &'enter'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Group',
			type = 'StringName',
			id = &'group',
			default_value = 'enemies'
		}
	]


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'},
		{name = 'Exit', id = &'exit'}
	]


func get_flow_enter() -> String:
	return _body()


func get_flow_update() -> String:
	return _body()


func get_flow_exit() -> String:
	return _body()


func _body() -> String:
	return '_ref.add_to_group({{group}})'
