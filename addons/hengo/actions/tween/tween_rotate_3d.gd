@tool
class_name HenActionTweenRotate3D extends HenActionTweenBase


func get_id() -> StringName:
	return &'tween_rotate_3d'


func get_description() -> String:
	return 'Smoothly rotates the node to a target angle over time. Wire Finished and the flow moves on by itself when it ends, with no timer of your own. On enter it plays once; on update or physics it starts again as soon as the last one ended, so it keeps repeating while the state runs.'


func get_display_name() -> String:
	return 'Tween Rotate'


func get_icon() -> String:
	return 'rotate-cw'


func get_target_classes() -> Array[StringName]:
	return [&'Node3D']


func get_inputs() -> Array[Dictionary]:
	return [
		node_ref_input('The node to turn. Leave it empty to turn this node.'),
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




func get_flow_enter() -> String:
	return _body()


func get_flow_update() -> String:
	return guard_per_frame(_body())


func get_flow_physics() -> String:
	return guard_per_frame(_body())


# rotation_degrees keeps the 2d unit convention, deg_to_rad has no Vector3 form
func _body() -> String:
	return start_tween('tween_property({{ref}}, "rotation_degrees", {{to}}, {{duration}})')
