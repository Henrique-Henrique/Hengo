@tool
class_name HenActionFadeAudio extends HenActionTweenBase


# fades a bound audio player toward To Volume over Duration seconds. -80 dB is
# silence and 0 dB is full. runs once, so best on enter.


func get_id() -> StringName:
	return &'fade_audio'


func get_description() -> String:
	return 'Fades an audio player toward a target volume over time. -80 is silence and 0 is full. Wire Finished and the flow moves on by itself when it ends, with no timer of your own. On enter it plays once; on update or physics it starts again as soon as the last one ended, so it keeps repeating while the state runs. Leaving the state before it ends jumps to the target volume, so it never stops at some level in between.'


func get_display_name() -> String:
	return 'Fade Sound'


func get_icon() -> String:
	return 'volume-2'


func finishes_on_cancel() -> bool:
	return true


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




func get_flow_enter() -> String:
	return _body()


func get_flow_update() -> String:
	return guard_per_frame(_body())


func get_flow_physics() -> String:
	return guard_per_frame(_body())


func _body() -> String:
	return start_tween('tween_property({{player}}, "volume_db", {{to}}, {{duration}})')
