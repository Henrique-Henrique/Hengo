@tool
class_name HenActionRandomVector2 extends HenScriptMacroBase


# writes a random point inside the rectangle between Min and Max into Store.
# Min is the top-left corner, Max the bottom-right one.


func get_id() -> StringName:
	return &'random_vector2'


func get_description() -> String:
	return 'Picks a random point inside the rectangle between Min and Max.'


func get_display_name() -> String:
	return 'Random Vector2'


func get_icon() -> String:
	return 'dice-5'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Min',
			type = 'Vector2',
			id = &'min',
			doc = 'The top-left corner of the area.',
			default_value = Vector2.ZERO
		},
		{
			name = 'Max',
			type = 'Vector2',
			id = &'max',
			doc = 'The bottom-right corner of the area.',
			default_value = Vector2(100, 100)
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Result', type = 'Vector2', id = &'result', doc = 'The random point.'}
	]


func get_output_result() -> String:
	return 'Vector2(randf_range({{min}}.x, {{max}}.x), randf_range({{min}}.y, {{max}}.y))'


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
