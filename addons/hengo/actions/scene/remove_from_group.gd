@tool
class_name HenActionRemoveFromGroup extends HenScriptMacroBase


func get_id() -> StringName:
	return &'remove_from_group'


func get_description() -> String:
	return 'Removes the node from a named group, so group checks and group calls no longer reach it.'


func get_display_name() -> String:
	return 'Remove From Group'


func get_icon() -> String:
	return 'user-round-x'


func get_default_phase() -> StringName:
	return &'enter'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Group',
			type = 'StringName',
			id = &'group',
			picker = 'group',
			doc = 'The group name to drop from the node.',
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
	return '_ref.remove_from_group({{group}})'
