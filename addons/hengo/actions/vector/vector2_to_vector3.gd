@tool
class_name HenActionVector2ToVector3 extends HenScriptMacroBase


func get_id() -> StringName:
	return &'vector2_to_vector3'


func get_description() -> String:
	return 'Turns a flat direction into a 3D one lying on the ground, so a 2D input drives movement in a 3D world. The Y of the vector becomes the Z of the result.'


func get_display_name() -> String:
	return 'Vector2 To Vector3'


func get_icon() -> String:
	return 'move-3d'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Vector',
			type = 'Vector2',
			id = &'vector',
			doc = 'The flat direction, such as the one a movement input gives.',
			default_value = Vector2.ZERO
		},
		{
			name = 'Height',
			type = 'float',
			id = &'height',
			doc = 'The value the Y of the result takes.',
			default_value = 0.0
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Result', type = 'Vector3', id = &'result', doc = 'The direction on the ground plane.'}
	]


func get_output_result() -> String:
	return 'Vector3({{vector}}.x, {{height}}, {{vector}}.y)'


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
