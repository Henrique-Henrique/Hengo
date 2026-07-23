@tool
class_name HenActionIsInGroup extends HenScriptMacroBase


# branches on whether the owner carries a group tag.


func get_id() -> StringName:
	return &'is_in_group'


func get_display_name() -> String:
	return 'Is In Group'


func get_icon() -> String:
	return 'users'


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
		{name = 'Physics', id = &'physics'}
	]


func get_flow_outputs() -> Array[Dictionary]:
	return [
		{name = 'True', id = &'true'},
		{name = 'False', id = &'false'}
	]


func get_flow_enter() -> String:
	return _body()


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


func _body() -> String:
	return 'if _ref.is_in_group({{group}}):\n\t{{true}}\nelse:\n\t{{false}}'
