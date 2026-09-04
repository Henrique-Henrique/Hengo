@tool
class_name HenActionPathFinished extends HenScriptMacroBase


func get_id() -> StringName:
	return &'path_finished'


func get_description() -> String:
	return 'Answers whether the navigation agent already arrived at the target it was given. It can branch on the answer or hand it to a field that takes a yes or no.'


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


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Yes', type = 'bool', id = &'result', doc = 'Where to store whether the agent already arrived.'}
	]


func get_output_result() -> String:
	return '{{agent}}.is_navigation_finished()'


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'}
	]


func get_flow_outputs() -> Array[Dictionary]:
	return [
		{name = 'Yes', id = &'yes', optional = true, doc = 'Where to go once the agent arrived at the target.'},
		{name = 'No', id = &'no', optional = true, doc = 'Where to go while the agent is still on its way.'}
	]


func get_flow_enter() -> String:
	return _body()


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


# with no branch wired it is only the answer, which is what lets it be read
# from inside another action's field
func _body() -> String:
	if not any_flow_connected():
		return '{{out:result}}'

	return '{{out:result}}\n' \
		+ 'if {{agent}}.is_navigation_finished():\n' \
		+ '\t{{yes}}\n' \
		+ 'else:\n' \
		+ '\t{{no}}'
