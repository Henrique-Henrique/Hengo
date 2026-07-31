@tool
class_name HenActionHorizontalLength extends HenScriptMacroBase


# writes the length of Vector on the ground plane (Y dropped) into Store: the
# ground speed of a velocity, or the flat distance of a position offset.


func get_id() -> StringName:
	return &'horizontal_length'


func get_description() -> String:
	return 'Measures the length of a 3D vector on the ground plane, ignoring its height. Feeding a velocity gives ground speed; feeding an offset gives flat distance.'


func get_display_name() -> String:
	return 'Ground Speed'


func get_icon() -> String:
	return 'ruler'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Vector',
			type = 'Vector3',
			id = &'vector',
			doc = 'The vector to measure on the ground plane.',
			default_value = Vector3.ZERO
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Result', type = 'float', id = &'result', doc = 'The ground-plane length of the vector.'}
	]


func get_output_result() -> String:
	return 'Vector2({{vector}}.x, {{vector}}.z).length()'


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
