@tool
class_name HenActionInGroup extends HenScriptMacroBase


func get_id() -> StringName:
	return &'in_group'


func get_description() -> String:
	return 'Stores whether this node belongs to a named group. It is the Is In Group answer as a value, to feed Do If or Combine Checks.'


func get_display_name() -> String:
	return 'In Group'


func get_icon() -> String:
	return 'users'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Group',
			type = 'StringName',
			id = &'group',
			picker = 'group',
			doc = 'The name of the group to look for.',
			default_value = 'enemies'
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Result', type = 'bool', id = &'result', doc = 'True while this node is in the group.'}
	]


func get_output_result() -> String:
	return '_ref.is_in_group({{group}})'


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
	return '{{out:result}}'
