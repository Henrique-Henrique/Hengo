@tool
class_name HenActionSetPitch extends HenScriptMacroBase


# changes the playback speed of a player, which also changes the pitch. 1 is
# normal, 2 is twice as fast. pairs well with Random Float for varied hits.


func get_id() -> StringName:
	return &'set_pitch'


func get_description() -> String:
	return 'Changes the playback speed of an audio player, which also shifts its pitch.'


func get_display_name() -> String:
	return 'Set Pitch'


func get_icon() -> String:
	return 'gauge'


func get_default_phase() -> StringName:
	return &'enter'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Player',
			type = 'Node',
			id = &'player',
				doc = 'The AudioStreamPlayer to adjust.',
			bind_only = true,
			default_value = null
		},
		{
			name = 'Pitch',
			type = 'float',
			id = &'pitch',
				doc = 'Playback speed multiplier, where 1 is normal and 2 is twice as fast.',
			default_value = 1.0
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
	return '{{player}}.pitch_scale = {{pitch}}'
