@tool
class_name HenActionGrabFocus extends HenScriptMacroBase


# moves keyboard and gamepad focus to a bound Control node (Button, LineEdit...).
# Target is bound by variable or node path; the call is duck-typed.


func get_id() -> StringName:
	return &'grab_focus'


func get_description() -> String:
	return 'Moves keyboard and gamepad focus to a Control node, such as a Button or a LineEdit. Use it to guide input to the right field.'


func get_display_name() -> String:
	return 'Focus Control'


func get_icon() -> String:
	return 'focus'


func get_default_phase() -> StringName:
	return &'enter'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Target',
			type = 'Control',
			id = &'target',
			doc = 'The node to give keyboard focus to. Leave it empty to focus this node.',
			bind_only = true,
			optional = true,
			default_value = null
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
	return '{{target}}.grab_focus()'
