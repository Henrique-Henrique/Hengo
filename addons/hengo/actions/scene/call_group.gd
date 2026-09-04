@tool
class_name HenActionCallGroup extends HenScriptMacroBase


# calls a method on every node of Group. the method runs with no arguments, so
# it fits things like queue_free or a custom reset.


func get_id() -> StringName:
	return &'call_group'


func get_description() -> String:
	return 'Calls a method on every node in a group at once. The method runs with no arguments, so it suits calls like queue_free or a custom reset.'


func get_display_name() -> String:
	return 'Call On Group'


func get_icon() -> String:
	return 'megaphone'


func get_default_phase() -> StringName:
	return &'enter'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Group',
			type = 'StringName',
			id = &'group',
			picker = 'group',
			doc = 'The group whose nodes are called.',
			default_value = 'enemies'
		},
		{
			name = 'Method',
			type = 'StringName',
			id = &'method',
			doc = 'The name of the method to call on each node.',
			default_value = 'queue_free'
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
	return '_ref.get_tree().call_group({{group}}, {{method}})'
