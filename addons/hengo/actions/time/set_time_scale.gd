@tool
class_name HenActionSetTimeScale extends HenScriptMacroBase


# speeds the whole game up or down. 1 is normal, 0.5 is slow motion, 0 freezes
# everything that runs on delta.


func get_id() -> StringName:
	return &'set_time_scale'


func get_description() -> String:
	return 'Speeds up or slows down the whole game. 1 is normal speed, 0.5 is slow motion, and 0 freezes everything that runs on delta.'


func get_display_name() -> String:
	return 'Set Time Scale'


func get_icon() -> String:
	return 'hourglass'


func get_default_phase() -> StringName:
	return &'enter'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Scale',
			type = 'float',
			id = &'scale',
				doc = 'The time multiplier, where 1 is normal speed.',
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
	return 'Engine.time_scale = {{scale}}'
