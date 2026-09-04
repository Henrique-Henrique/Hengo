@tool
class_name HenActionRandomVector3 extends HenScriptMacroBase


func get_id() -> StringName:
	return &'random_vector3'


func get_description() -> String:
	return 'Picks a random point inside the box between Min and Max, useful to spawn something at a random spot.'


func get_display_name() -> String:
	return 'Random Vector3'


func get_icon() -> String:
	return 'dice-5'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Min',
			type = 'Vector3',
			id = &'min',
			doc = 'The lowest corner of the box.',
			default_value = Vector3.ZERO
		},
		{
			name = 'Max',
			type = 'Vector3',
			id = &'max',
			doc = 'The highest corner of the box.',
			default_value = Vector3(10, 10, 10)
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Result', type = 'Vector3', id = &'result', doc = 'The random point.'}
	]


func get_output_result() -> String:
	return 'Vector3(randf_range({{min}}.x, {{max}}.x), randf_range({{min}}.y, {{max}}.y), randf_range({{min}}.z, {{max}}.z))'


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
