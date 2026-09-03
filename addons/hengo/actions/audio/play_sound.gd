@tool
class_name HenActionPlaySound extends HenScriptMacroBase


# starts an audio player of the scene. bind Player to the AudioStreamPlayer node,
# either by variable or by node path.


func get_id() -> StringName:
	return &'play_sound'


func get_description() -> String:
	return 'Plays a sound from an audio player. One player carries one sound at a time, so playing again cuts the first one short, and raising Max Polyphony on the player is what lets three coins picked up in a row all ring out together.'


func get_display_name() -> String:
	return 'Play Sound'


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
				doc = 'The AudioStreamPlayer to play.',
			bind_only = true,
			default_value = null
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
	return '{{player}}.play()'
