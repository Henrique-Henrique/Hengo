@tool
class_name HenActionPlayRandomSound extends HenScriptMacroBase


# picks a random stream from Sounds, loads it into the bound player and plays it.
# the easy way to vary a footstep or a hit so it does not sound repetitive.


func get_id() -> StringName:
	return &'play_random_sound'


func get_description() -> String:
	return 'Picks a random sound from a list and plays it on an audio player. Use it to vary a footstep or a hit so it does not sound repetitive.'


func get_display_name() -> String:
	return 'Play Random Sound'


func get_icon() -> String:
	return 'shuffle'


func get_default_phase() -> StringName:
	return &'enter'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Player',
			type = 'Node',
			id = &'player',
			doc = 'The audio player to play through.',
			bind_only = true,
			default_value = null
		},
		{
			name = 'Sounds',
			type = 'Array',
			id = &'sounds',
			doc = 'The list of sounds to pick from.',
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
	return '{{player}}.stream = {{sounds}}.pick_random()\n{{player}}.play()'
