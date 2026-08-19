@tool
class_name HenActionStartTimer extends HenScriptMacroBase


func get_id() -> StringName:
	return &'start_timer'


func get_description() -> String:
	return 'Starts a Timer node counting down from a number of seconds. On Timer Timeout runs when the countdown ends.'


func get_display_name() -> String:
	return 'Start Timer'


func get_icon() -> String:
	return 'timer'


func get_default_phase() -> StringName:
	return &'enter'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Timer',
			type = 'Node',
			id = &'timer',
			doc = 'The Timer node to start.',
			bind_only = true,
			default_value = null
		},
		{
			name = 'Seconds',
			type = 'float',
			id = &'seconds',
			doc = 'How long the countdown lasts, in seconds.',
			default_value = 1.0
		},
		{
			name = 'One Shot',
			type = 'bool',
			id = &'one_shot',
			doc = 'On, the timer fires once. Off, it repeats forever until stopped.',
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


# the engine refuses a wait_time of zero, so the seconds are clamped
func _body() -> String:
	return '{{timer}}.one_shot = {{one_shot}}\n' \
		+ '{{timer}}.wait_time = maxf({{seconds}}, 0.001)\n' \
		+ '{{timer}}.start()'
