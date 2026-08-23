@tool
class_name HenActionWave extends HenScriptMacroBase


# writes a sine oscillation driven by the engine clock into Store: it swings
# between -Amplitude and +Amplitude at Frequency cycles per second. good for a
# bob, a float or a breathing pulse without keeping a time counter by hand.


func get_id() -> StringName:
	return &'wave'


func get_description() -> String:
	return 'Gives a number that swings smoothly up and down forever, driven by the game clock. With Amplitude = 10 it travels between -10 and 10, and Frequency = 2 makes it do that twice a second. Add it to a position for a coin that bobs or a light that pulses.'


func get_display_name() -> String:
	return 'Oscillate'


func get_icon() -> String:
	return 'spline'


func get_default_phase() -> StringName:
	return &'update'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Frequency',
			type = 'float',
			id = &'frequency',
			doc = 'How many full up-and-down trips happen each second.',
			default_value = 1.0
		},
		{
			name = 'Amplitude',
			type = 'float',
			id = &'amplitude',
			doc = 'How far it reaches from the middle, in each direction.',
			default_value = 1.0
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Result', type = 'float', id = &'result', doc = 'The current wave value.'}
	]


func get_output_result() -> String:
	return 'sin(Time.get_ticks_msec() / 1000.0 * {{frequency}} * TAU) * {{amplitude}}'


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
	return '{{out:result}}'
