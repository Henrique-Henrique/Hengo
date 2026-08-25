@tool
class_name HenActionBillboard3D extends HenScriptMacroBase


# turns the node each frame so its front faces the active 3d camera, the way a
# health bar or a sprite stays readable from any angle.


func get_id() -> StringName:
	return &'billboard_3d'


func get_description() -> String:
	return 'Turns the node so its front faces the active 3D camera, keeping it readable from any angle. Best on update so it tracks the camera each frame.'


func get_display_name() -> String:
	return 'Face Camera'


func get_icon() -> String:
	return 'camera'


func get_target_classes() -> Array[StringName]:
	return [&'Node3D']


func get_default_phase() -> StringName:
	return &'update'


func get_inputs() -> Array[Dictionary]:
	return [
		node_ref_input('The node to keep facing the camera. Leave it empty to turn this node.'),
	]

func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'}
	]


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


# guard the frame the node and camera share a position, where look_at has no
# direction to face
func _body() -> String:
	return 'var cam_{{VCNODE_ID}} = _ref.get_viewport().get_camera_3d()\n' \
		+ 'if is_instance_valid(cam_{{VCNODE_ID}}) and not {{ref}}.global_position.is_equal_approx(cam_{{VCNODE_ID}}.global_position):\n' \
		+ '\t{{ref}}.look_at(cam_{{VCNODE_ID}}.global_position, Vector3.UP)'
