@tool
class_name HenActionPlayMusic extends HenActionTweenBase


func get_id() -> StringName:
	return &'play_music'


func get_description() -> String:
	return 'Swaps the track of a music player, fading the old one out and the new one back in. Wire Finished and the flow moves on by itself when it ends, with no timer of your own. On enter it plays once; on update or physics it starts again as soon as the last one ended, so it keeps repeating while the state runs. Leaving the state before it ends finishes the swap, so the new track never stays silent with the old one loaded.'


func get_display_name() -> String:
	return 'Play Music'


func get_icon() -> String:
	return 'music'


func finishes_on_cancel() -> bool:
	return true


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Player',
			type = 'Node',
			id = &'player',
			doc = 'The audio player that holds the music.',
			bind_only = true,
			default_value = null
		},
		{
			name = 'Sound',
			type = 'AudioStream',
			id = &'sound',
			doc = 'The music file to play.',
			bind_only = true,
			default_value = null
		},
		{
			name = 'Fade',
			type = 'float',
			id = &'fade',
			doc = 'How long the whole swap takes, in seconds, split between the fade out and the fade in.',
			default_value = 1.0
		}
	]




func get_flow_enter() -> String:
	return _body()


func get_flow_update() -> String:
	return guard_per_frame(_body())


func get_flow_physics() -> String:
	return guard_per_frame(_body())


func _body() -> String:
	return 'var music_{{VCNODE_ID}} = {{player}}\n' \
		+ 'var track_{{VCNODE_ID}} = {{sound}}\n' \
		+ 'var volume_{{VCNODE_ID}} = music_{{VCNODE_ID}}.volume_db\n' \
		+ 'var swap_{{VCNODE_ID}} = _ref.create_tween()\n' \
		+ 'swap_{{VCNODE_ID}}.tween_property(music_{{VCNODE_ID}}, "volume_db", -80.0, {{fade}} * 0.5)\n' \
		+ 'swap_{{VCNODE_ID}}.tween_callback(func(): music_{{VCNODE_ID}}.stream = track_{{VCNODE_ID}})\n' \
		+ 'swap_{{VCNODE_ID}}.tween_callback(func(): music_{{VCNODE_ID}}.play())\n' \
		+ 'swap_{{VCNODE_ID}}.tween_property(music_{{VCNODE_ID}}, "volume_db", volume_{{VCNODE_ID}}, {{fade}} * 0.5)\n' \
		+ finish_hook('swap_{{VCNODE_ID}}')
