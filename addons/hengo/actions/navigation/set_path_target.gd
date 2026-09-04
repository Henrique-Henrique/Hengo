@tool
class_name HenActionSetPathTarget extends HenScriptMacroBase


func get_id() -> StringName:
	return &'set_path_target'


func get_description() -> String:
	return 'Tells a navigation agent where to walk to, and the agent works out a route around the walls. Move Along Path then follows that route.'


func get_display_name() -> String:
	return 'Set Path Target'


func get_icon() -> String:
	return 'map-pin'


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
		},
		{
			name = 'Target',
			type = 'Variant',
			id = &'target',
			doc = 'The point to walk to, a Vector2 in 2D and a Vector3 in 3D.',
			default_value = 0
		}
	]


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'}
	]


func get_flow_enter() -> String:
	return _body()


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


func _body() -> String:
	return '{{agent}}.target_position = {{target}}'
