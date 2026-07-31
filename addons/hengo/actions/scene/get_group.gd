@tool
class_name HenActionGetGroup extends HenScriptMacroBase


# writes every node of Group into Store as an array. pair it with For Each to act
# on all of them; Get Nearest already handles the closest-one case.


func get_id() -> StringName:
	return &'get_group'


func get_description() -> String:
	return 'Collects every node in a group and stores it as an array. Pair it with For Each to act on all of them at once.'


func get_display_name() -> String:
	return 'Get Group'


func get_icon() -> String:
	return 'group'


func get_default_phase() -> StringName:
	return &'update'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Group',
			type = 'StringName',
			id = &'group',
			doc = 'The group whose nodes are collected.',
			default_value = 'enemies'
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Members', type = 'Array', id = &'members', doc = 'Where to store the array of nodes in the group.'}
	]


func get_output_members() -> String:
	return '_ref.get_tree().get_nodes_in_group({{group}})'


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
	return '{{out:members}}'
