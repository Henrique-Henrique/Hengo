@tool
class_name HenActionRandomDirection extends HenScriptMacroBase


# writes a random direction into Store, as an arrow of Length pixels. the angle
# is picked in degrees: 0 points right, 90 points down.


func get_id() -> StringName:
	return &'random_direction'


func get_description() -> String:
	return 'Picks a random direction as a Vector2, with its angle chosen between Min Angle and Max Angle. In degrees, 0 points right and 90 points down.'


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
			doc = 'The smallest angle to pick, in degrees.',
			default_value = 0.0
		},
		{
			name = 'Max Angle',
			type = 'float',
			id = &'max',
			doc = 'The largest angle to pick, in degrees.',
			default_value = 360.0
		},
		{
			name = 'Length',
			type = 'float',
			id = &'length',
			doc = 'How long the resulting vector is, in pixels.',
			default_value = 1.0
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Result', type = 'Vector2', id = &'result', doc = 'The random direction vector.'}
	]


func get_output_result() -> String:
	return 'Vector2.from_angle(deg_to_rad(randf_range({{min}}, {{max}}))) * {{length}}'


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
