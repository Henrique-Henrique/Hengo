@tool
class_name HenActionTweenRotate3D extends HenActionTweenBase


func get_id() -> StringName:
	return &'tween_rotate_3d'


func get_description() -> String:
	return 'Smoothly rotates the node to a target angle over time. Runs once when the state starts. Wire Finished and the flow moves on by itself when it ends, with no timer of your own.'


func get_display_name() -> String:
	return 'Tween Rotate'


func get_icon() -> String:
	return 'rotate-cw'


func get_target_classes() -> Array[StringName]:
	return [&'Node3D']


func get_default_phase() -> StringName:
	return &'enter'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'To Degrees',
			type = 'Vector3',
			id = &'to',
			doc = 'The target angle on each axis, in degrees.',
			default_value = Vector3.ZERO
		},
		{
			name = 'Duration',
			type = 'float',
			id = &'duration',
			doc = 'How long the rotation takes, in seconds.',
			default_value = 0.3
		}
	]


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'}
	]


func get_flow_enter() -> String:
	return _body()


# rotation_degrees keeps the 2d unit convention, deg_to_rad has no Vector3 form
func _body() -> String:
	return start_tween('tween_property(_ref, "rotation_degrees", {{to}}, {{duration}})')
