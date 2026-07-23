@tool
class_name HenActionSetVolume extends HenScriptMacroBase


# sets how loud a player is, in decibels: 0 is the original volume, -80 is silent.
# every 6 db down halves the loudness.


func get_id() -> StringName:
	return &'set_volume'


func get_display_name() -> String:
	return 'Set Volume'


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
			bind_only = true,
			default_value = null
		},
		{
			name = 'Volume dB',
			type = 'float',
			id = &'volume',
			default_value = 0.0
		}
	]


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'},
		{name = 'Exit', id = &'exit'}
	]


func get_flow_enter() -> String:
	return _body()


func get_flow_update() -> String:
	return _body()


func get_flow_exit() -> String:
	return _body()


func _body() -> String:
	return '{{player}}.volume_db = {{volume}}'
