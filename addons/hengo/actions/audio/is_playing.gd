@tool
class_name HenActionIsSoundPlaying extends HenScriptMacroBase


# branches on whether a player is still making sound, the usual way to wait for
# a clip to end before moving on.


func get_id() -> StringName:
	return &'is_sound_playing'


func get_description() -> String:
	return 'Checks whether an audio player is still playing and branches on the result. Useful for waiting until a sound finishes before continuing.'


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


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'}
	]


func get_flow_outputs() -> Array[Dictionary]:
	return [
		{name = 'True', id = &'true', doc = 'Where to go while the sound is still playing.'},
		{name = 'False', id = &'false', doc = 'Where to go once the sound has stopped.'}
	]


func get_flow_enter() -> String:
	return _body()


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


func _body() -> String:
	return 'if {{player}}.playing:\n\t{{true}}\nelse:\n\t{{false}}'
