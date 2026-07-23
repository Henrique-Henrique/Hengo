@tool
class_name HenActionRandomDirection extends HenScriptMacroBase


# writes a random direction into Store, as an arrow of Length pixels. the angle
# is picked in degrees: 0 points right, 90 points down.


func get_id() -> StringName:
	return &'random_direction'


func get_display_name() -> String:
	return 'Random Direction'


func get_icon() -> String:
	return 'navigation'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Min Angle',
			type = 'float',
			id = &'min',
			default_value = 0.0
		},
		{
			name = 'Max Angle',
			type = 'float',
			id = &'max',
			default_value = 360.0
		},
		{
			name = 'Length',
			type = 'float',
			id = &'length',
			default_value = 1.0
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Result', type = 'Vector2', id = &'result'}
	]


func get_output_result() -> String:
	return 'Vector2.from_angle(deg_to_rad(randf_range({{min}}, {{max}}))) * {{length}}'


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
