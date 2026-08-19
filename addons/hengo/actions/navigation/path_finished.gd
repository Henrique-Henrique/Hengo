@tool
class_name HenActionPathFinished extends HenScriptMacroBase


func get_id() -> StringName:
	return &'path_finished'


func get_description() -> String:
	return 'Checks whether the navigation agent already arrived at the target it was given, and branches on the answer.'


func get_display_name() -> String:
	return 'Reached Target'


func get_icon() -> String:
	return 'flag'


func get_default_phase() -> StringName:
	return &'update'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Agent',
			type = 'Node',
			id = &'agent',
			doc = 'The NavigationAgent2D or NavigationAgent3D node that plans the route.',
			bind_only = true,
			default_value = null
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
		{name = 'Yes', id = &'yes', doc = 'Where to go once the agent arrived at the target.'},
		{name = 'No', id = &'no', doc = 'Where to go while the agent is still on its way.'}
	]


func get_flow_enter() -> String:
	return _body()


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


func _body() -> String:
	return 'if {{agent}}.is_navigation_finished():\n\t{{yes}}\nelse:\n\t{{no}}'
