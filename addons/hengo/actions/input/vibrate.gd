@tool
class_name HenActionVibrate extends HenScriptMacroBase


# shakes the gamepad. Weak is the light motor and Strong the heavy one, both from
# 0 to 1; the vibration stops on its own after Duration.


func get_id() -> StringName:
	return &'vibrate'


func get_description() -> String:
	return 'Vibrates the gamepad for a set time, then stops on its own.'


func get_display_name() -> String:
	return 'Vibrate'


func get_icon() -> String:
	return 'gamepad'


func get_default_phase() -> StringName:
	return &'enter'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Weak',
			type = 'float',
			id = &'weak',
			doc = 'Strength of the light motor, from 0 to 1.',
			default_value = 0.5
		},
		{
			name = 'Strong',
			type = 'float',
			id = &'strong',
			doc = 'Strength of the heavy motor, from 0 to 1.',
			default_value = 0.5
		},
		{
			name = 'Duration',
			type = 'float',
			id = &'duration',
			doc = 'How long the vibration lasts, in seconds.',
			default_value = 0.2
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
	return 'Input.start_joy_vibration(0, {{weak}}, {{strong}}, {{duration}})'
