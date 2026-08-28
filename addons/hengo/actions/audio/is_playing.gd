@tool
class_name HenActionIsSoundPlaying extends HenScriptMacroBase


# branches on whether a player is still making sound, the usual way to wait for
# a clip to end before moving on.


func get_id() -> StringName:
	return &'is_sound_playing'


func get_description() -> String:
	return 'Answers whether an audio player is still playing, which is how a state waits for a sound to finish. It can branch on the answer or hand it to a field that takes a yes or no.'


func get_display_name() -> String:
	return 'Is Sound Playing'


func get_icon() -> String:
	return 'volume-2'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Player',
			type = 'Node',
			id = &'player',
				doc = 'The AudioStreamPlayer to check.',
			bind_only = true,
			default_value = null
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Yes', type = 'bool', id = &'result', doc = 'Where to store whether the sound is still playing.'}
	]


func get_output_result() -> String:
	return '{{player}}.playing'


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'}
	]


func get_flow_outputs() -> Array[Dictionary]:
	return [
		{name = 'True', id = &'true', optional = true, doc = 'Where to go while the sound is still playing.'},
		{name = 'False', id = &'false', optional = true, doc = 'Where to go once the sound has stopped.'}
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
		+ 'if {{player}}.playing:\n' \
		+ '\t{{true}}\n' \
		+ 'else:\n' \
		+ '\t{{false}}'
