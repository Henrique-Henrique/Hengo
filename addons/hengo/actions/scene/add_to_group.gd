@tool
class_name HenActionAddToGroup extends HenScriptMacroBase


# tags the owner with a group name, the usual way to mark "this is an enemy".


func get_id() -> StringName:
	return &'add_to_group'


func get_description() -> String:
	return 'Adds the node to a named group, a common way to tag it as something like an enemy or a pickup.'


func get_display_name() -> String:
	return 'Add To Group'


func get_icon() -> String:
	return 'users'


func get_default_phase() -> StringName:
	return &'enter'


func get_inputs() -> Array[Dictionary]:
	return [
		node_ref_input('The node to add. Leave it empty to add this node.'),
		{
			name = 'Group',
			type = 'StringName',
			id = &'group',
			picker = 'group',
			doc = 'The group name to tag the node with.',
			default_value = 'enemies'
		}
	]


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
	return '{{ref}}.add_to_group({{group}})'
