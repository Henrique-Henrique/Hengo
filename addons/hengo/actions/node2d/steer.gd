@tool
class_name HenActionSteer extends HenScriptMacroBase


# turns the owner by Degrees per second scaled by Amount, a -1..1 steering input.
# the body needs delta, so only update and physics are offered.


func get_id() -> StringName:
	return &'steer'


func get_display_name() -> String:
	return 'Steer'


func get_icon() -> String:
	return 'rotate-cw'


func get_target_classes() -> Array[StringName]:
	return [&'Node2D']


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Amount',
			type = 'float',
			id = &'amount',
			default_value = 0.0
		},
		{
			name = 'Degrees',
			type = 'float',
			id = &'degrees',
			default_value = 180.0
		}
	]


func get_default_phase() -> StringName:
	return &'physics'


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'}
	]


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


func _body() -> String:
	return '_ref.rotation += deg_to_rad({{degrees}}) * {{amount}} * delta'
