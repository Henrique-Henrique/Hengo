@tool
class_name HenActionVector3ToVector2 extends HenScriptMacroBase


func get_id() -> StringName:
	return &'vector3_to_vector2'


func get_description() -> String:
	return 'Drops the height of a 3D vector and keeps the ground part as a flat one, such as reading how a body moves along the floor.'


func get_display_name() -> String:
	return 'Vector3 To Vector2'


func get_icon() -> String:
	return 'move'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Vector',
			type = 'Vector3',
			id = &'vector',
			doc = 'The 3D vector to flatten, such as a velocity.',
			default_value = Vector3.ZERO
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Result', type = 'Vector2', id = &'result', doc = 'The X and Z of the vector, as a flat one.'}
	]


func get_output_result() -> String:
	return 'Vector2({{vector}}.x, {{vector}}.z)'


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
