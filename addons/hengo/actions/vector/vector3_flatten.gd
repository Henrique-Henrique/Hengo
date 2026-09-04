@tool
class_name HenActionVector3Flatten extends HenScriptMacroBase


# writes Vector with its Y set to zero into Store, dropping height so a velocity
# or a position reads on the ground plane only.


func get_id() -> StringName:
	return &'vector3_flatten'


func get_description() -> String:
	return 'Drops the height of a 3D vector, leaving only its ground-plane part. Useful for measuring horizontal movement or facing without the vertical component.'


func get_display_name() -> String:
	return 'Drop Height'


func get_icon() -> String:
	return 'ruler'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Vector',
			type = 'Vector3',
			id = &'vector',
			doc = 'The vector to flatten onto the ground plane.',
			default_value = Vector3.ZERO
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Result', type = 'Vector3', id = &'result', doc = 'The vector with its Y set to zero.'}
	]


func get_output_result() -> String:
	return 'Vector3({{vector}}.x, 0.0, {{vector}}.z)'


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
