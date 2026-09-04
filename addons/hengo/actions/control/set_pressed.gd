@tool
class_name HenActionSetPressed extends HenScriptMacroBase


# sets the pressed state of a bound toggle button (CheckBox, CheckButton, a
# toggle-mode Button). Target is bound by variable or node path; the assignment
# is duck-typed.


func get_id() -> StringName:
	return &'set_pressed'


func get_description() -> String:
	return 'Turns a toggle button on or off, such as a CheckBox or a CheckButton. Setting it here does not emit the toggled signal.'


func get_display_name() -> String:
	return 'Set Toggled'


func get_icon() -> String:
	return 'toggle-right'


func get_default_phase() -> StringName:
	return &'enter'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Target',
			type = 'BaseButton',
			id = &'target',
			doc = 'The button to press or release. Leave it empty to change this node.',
			bind_only = true,
			optional = true,
			default_value = null
		},
		{
			name = 'On',
			type = 'bool',
			id = &'pressed',
			doc = 'True to turn the button on, false to turn it off.',
			default_value = true
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
	return '{{target}}.set_pressed_no_signal({{pressed}})'
