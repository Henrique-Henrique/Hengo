@tool
class_name HenActionAngleDifference extends HenScriptMacroBase


# writes the shortest signed angle from From to To into Store, wrapping past a
# full turn so 350 to 10 degrees reads as a 20 degree step, not 340.


func get_id() -> StringName:
	return &'angle_difference'


func get_description() -> String:
	return 'Returns the shortest signed angle from one angle to another, wrapping around a full turn. Feed it to a smooth turn so the shorter way is always taken.'


func get_display_name() -> String:
	return 'Angle Difference'


func get_icon() -> String:
	return 'rotate-cw'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'From',
			type = 'float',
			id = &'from',
			doc = 'The current angle, in radians.',
			default_value = 0.0
		},
		{
			name = 'To',
			type = 'float',
			id = &'to',
			doc = 'The target angle, in radians.',
			default_value = 0.0
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Result', type = 'float', id = &'result', doc = 'The shortest signed angle from one to the other, in radians.'}
	]


func get_output_result() -> String:
	return 'angle_difference({{from}}, {{to}})'


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
	return '{{out:result}}'
