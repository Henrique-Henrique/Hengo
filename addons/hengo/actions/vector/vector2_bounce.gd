@tool
class_name HenActionVector2Bounce extends HenScriptMacroBase


# writes Vector reflected off a surface with the given Normal into Store, the
# velocity a ball keeps after hitting a wall. Normal must be a unit vector.


func get_id() -> StringName:
	return &'vector2_bounce'


func get_description() -> String:
	return 'Reflects a 2D vector off a surface and stores the result, such as the velocity a ball keeps after hitting a wall. Normal must be a unit vector.'


func get_display_name() -> String:
	return 'Vector2 Bounce'


func get_icon() -> String:
	return 'move-diagonal-2'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Vector',
			type = 'Vector2',
			id = &'vector',
			doc = 'The incoming vector, such as a velocity.',
			default_value = Vector2.ZERO
		},
		{
			name = 'Normal',
			type = 'Vector2',
			id = &'normal',
			doc = 'The unit direction the surface faces.',
			default_value = Vector2(0, 1)
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Result', type = 'Vector2', id = &'result', doc = 'The bounced vector.'}
	]


func get_output_result() -> String:
	return '{{vector}}.bounce({{normal}})'


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
