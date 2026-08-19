@tool
class_name HenActionIsInGroup extends HenScriptMacroBase


# branches on whether the owner carries a group tag.


func get_id() -> StringName:
	return &'is_in_group'


func get_description() -> String:
	return 'Checks whether the node belongs to a named group and branches on the answer.'


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
			picker = 'group',
			doc = 'The group name to check for.',
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
		{name = 'True', id = &'true', doc = 'Where to go when the node is in the group.'},
		{name = 'False', id = &'false', doc = 'Where to go when the node is not in the group.'}
	]


func get_flow_enter() -> String:
	return _body()


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


func _body() -> String:
	return 'if _ref.is_in_group({{group}}):\n\t{{true}}\nelse:\n\t{{false}}'
