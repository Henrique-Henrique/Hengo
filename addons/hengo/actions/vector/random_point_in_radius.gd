@tool
class_name HenActionRandomPointInRadius extends HenScriptMacroBase


func get_id() -> StringName:
	return &'random_point_in_radius'


func get_description() -> String:
	return 'Picks a random point around a center, never farther than Radius. It picks inside a circle on a 2D script and inside a sphere on a 3D one.'


func get_display_name() -> String:
	return 'Random Point In Radius'


func get_icon() -> String:
	return 'dice-6'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Center',
			type = 'Variant',
			id = &'center',
			doc = 'The point to pick around, such as the position of a node.',
			bind_only = true,
			default_value = null
		},
		{
			name = 'Radius',
			type = 'float',
			id = &'radius',
			doc = 'How far from the center the point can land, in pixels for 2D and in units for 3D.',
			default_value = 100.0
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Result', type = 'Variant', id = &'result', doc = 'Where to store the point, a Vector2 in 2D and a Vector3 in 3D.'}
	]


# a normalized randfn triple spreads evenly over the sphere, a randf_range one does not
func get_output_result() -> String:
	if targets(&'Node3D'):
		return '{{center}} + Vector3(randfn(0.0, 1.0), randfn(0.0, 1.0), randfn(0.0, 1.0)).normalized() * randf_range(0.0, {{radius}})'

	return '{{center}} + Vector2.from_angle(randf_range(0.0, TAU)) * randf_range(0.0, {{radius}})'


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
