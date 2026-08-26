@tool
class_name HenActionVector2Rotated extends HenScriptMacroBase


# writes Vector turned by Angle (degrees) into Store.


func get_id() -> StringName:
	return &'vector2_rotated'


func get_description() -> String:
	return 'Rotates a vector by an angle and returns the turned vector.'


func get_display_name() -> String:
	return 'Vector2 Rotated'


func get_icon() -> String:
	return 'rotate-cw'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Vector',
			type = 'Vector2',
			id = &'vector',
			doc = 'The vector to rotate.',
			default_value = Vector2.RIGHT
		},
		{
			name = 'Angle',
			type = 'float',
			id = &'angle',
			doc = 'How far to turn it, in degrees.',
			default_value = 0.0
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Result', type = 'Vector2', id = &'result', doc = 'The rotated vector.'}
	]


func get_output_result() -> String:
	return '{{vector}}.rotated(deg_to_rad({{angle}}))'


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
