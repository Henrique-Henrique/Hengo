@tool
class_name HenActionVector3DirectionTo extends HenScriptMacroBase


# writes the unit direction from From to To into Store.


func get_id() -> StringName:
	return &'vector3_direction_to'


func get_description() -> String:
	return 'Gives the direction that points from one place to another in 3D, always exactly one unit long so it carries no speed of its own. Multiply it with Scale Vector3 to turn it into a velocity.'


func get_display_name() -> String:
	return 'Vector3 Direction To'


func get_icon() -> String:
	return 'navigation'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'From',
			type = 'Vector3',
			id = &'from',
			doc = 'The starting point.',
			default_value = Vector3.ZERO
		},
		{
			name = 'To',
			type = 'Vector3',
			id = &'to',
			doc = 'The point to aim at.',
			default_value = Vector3.ZERO
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Result', type = 'Vector3', id = &'result', doc = 'The direction from From to To, one unit long.'}
	]


func get_output_result() -> String:
	return '{{from}}.direction_to({{to}})'


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
	return '{{out:result}}'
