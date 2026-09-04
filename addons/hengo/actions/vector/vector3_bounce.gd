@tool
class_name HenActionVector3Bounce extends HenScriptMacroBase


# writes Vector reflected off a surface with the given Normal into Store, the
# velocity a ball keeps after hitting a wall. Normal must be a unit vector.


func get_id() -> StringName:
	return &'vector3_bounce'


func get_description() -> String:
	return 'Turns a velocity into the one it keeps after bouncing off a surface, the way a ball comes off a wall. Cast Ray and Move And Collide already report the Normal it needs on a hit.'


func get_display_name() -> String:
	return 'Vector3 Bounce'


func get_icon() -> String:
	return 'move-diagonal-2'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Vector',
			type = 'Vector3',
			id = &'vector',
			doc = 'The incoming vector, such as a velocity.',
			default_value = Vector3.ZERO
		},
		{
			name = 'Normal',
			type = 'Vector3',
			id = &'normal',
			doc = 'The direction the surface faces, straight out of it. A collision reports it as the normal.',
			default_value = Vector3(0, 1, 0)
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Result', type = 'Vector3', id = &'result', doc = 'The bounced vector.'}
	]


func get_output_result() -> String:
	return '{{vector}}.bounce({{normal}})'


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
