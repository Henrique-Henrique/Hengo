@tool
class_name HenActionWave extends HenScriptMacroBase


# writes a sine oscillation driven by the engine clock into Store: it swings
# between -Amplitude and +Amplitude at Frequency cycles per second. good for a
# bob, a float or a breathing pulse without keeping a time counter by hand.


func get_id() -> StringName:
	return &'wave'


func get_description() -> String:
	return 'Produces a sine wave from the game clock that swings between minus Amplitude and plus Amplitude. Useful for bobbing, floating or pulsing without tracking time by hand.'


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
			doc = 'How many full cycles happen each second.',
			default_value = 1.0
		},
		{
			name = 'Amplitude',
			type = 'float',
			id = &'amplitude',
			doc = 'How far the wave reaches from the center.',
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
