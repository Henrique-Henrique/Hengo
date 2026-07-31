@tool
class_name HenActionFadeAudio extends HenScriptMacroBase


# fades a bound audio player toward To Volume over Duration seconds. -80 dB is
# silence and 0 dB is full. runs once, so best on enter.


func get_id() -> StringName:
	return &'fade_audio'


func get_description() -> String:
	return 'Fades an audio player toward a target volume over time. -80 is silence and 0 is full. Runs once when the state starts.'


func get_display_name() -> String:
	return 'Fade Sound'


func get_icon() -> String:
	return 'volume-2'


func get_default_phase() -> StringName:
	return &'enter'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Player',
			type = 'Node',
			id = &'player',
			doc = 'The audio player to fade.',
			bind_only = true,
			default_value = null
		},
		{
			name = 'To Volume',
			type = 'float',
			id = &'to',
			doc = 'Target volume in decibels, -80 for silence and 0 for full.',
			default_value = 0.0
		},
		{
			name = 'Duration',
			type = 'float',
			id = &'duration',
			doc = 'How long the fade takes, in seconds.',
			default_value = 0.5
		}
	]


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'}
	]


func get_flow_enter() -> String:
	return _body()


func _body() -> String:
	return '_ref.create_tween().tween_property({{player}}, "volume_db", {{to}}, {{duration}})'
