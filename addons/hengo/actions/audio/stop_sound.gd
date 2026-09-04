@tool
class_name HenActionStopSound extends HenScriptMacroBase


# stops an audio player of the scene.


func get_id() -> StringName:
	return &'stop_sound'


func get_description() -> String:
	return 'Stops a sound that an audio player is playing.'


func get_display_name() -> String:
	return 'Stop Sound'


func get_icon() -> String:
	return 'volume-x'


func get_default_phase() -> StringName:
	return &'enter'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Player',
			type = 'Node',
			id = &'player',
				doc = 'The AudioStreamPlayer to stop.',
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
	return '{{player}}.stop()'
