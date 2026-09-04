@tool
class_name HenActionStopAllSounds extends HenScriptMacroBase


func get_id() -> StringName:
	return &'stop_all_sounds'


func get_description() -> String:
	return 'Stops every audio player under a node, whatever kind it is. Use it to silence a level at once, such as on a pause or a game over.'


func get_display_name() -> String:
	return 'Stop All Sounds'


func get_icon() -> String:
	return 'volume-x'


func get_default_phase() -> StringName:
	return &'enter'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Root',
			type = 'Node',
			id = &'root',
			doc = 'The node to search under, usually the level or the scene root.',
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


# owned is false, or a player created while the game runs is never found
func _body() -> String:
	return 'var players_{{VCNODE_ID}}: Array = []\n' \
		+ 'players_{{VCNODE_ID}}.append_array({{root}}.find_children("*", "AudioStreamPlayer", true, false))\n' \
		+ 'players_{{VCNODE_ID}}.append_array({{root}}.find_children("*", "AudioStreamPlayer2D", true, false))\n' \
		+ 'players_{{VCNODE_ID}}.append_array({{root}}.find_children("*", "AudioStreamPlayer3D", true, false))\n' \
		+ 'for player_{{VCNODE_ID}} in players_{{VCNODE_ID}}:\n' \
		+ '\tplayer_{{VCNODE_ID}}.stop()'
