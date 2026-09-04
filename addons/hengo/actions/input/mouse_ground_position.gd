@tool
class_name HenActionMouseGroundPosition extends HenScriptMacroBase


func get_id() -> StringName:
	return &'mouse_ground_position'


func get_description() -> String:
	return 'Reads the world point the mouse is over on a flat ground and stores it. It is what a click to move, a tower placement or an RTS order needs, and it uses the active camera.'


func get_display_name() -> String:
	return 'Get Mouse World Position'


func get_icon() -> String:
	return 'map-pin'


func get_target_classes() -> Array[StringName]:
	return [&'Node3D']


func get_default_phase() -> StringName:
	return &'update'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Height',
			type = 'float',
			id = &'height',
			doc = 'How high the flat ground sits on the Y axis, usually 0 for the floor.',
			default_value = 0.0
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Result', type = 'Vector3', id = &'result', doc = 'Where to store the point the mouse is over. It stays at zero while no camera is active.'}
	]


func get_output_result() -> String:
	return 'ground_{{VCNODE_ID}} if ground_{{VCNODE_ID}} != null else Vector3.ZERO'


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


# intersects_ray answers null when the ray runs parallel to the ground
func _body() -> String:
	return 'var ground_{{VCNODE_ID}} = null\n' \
		+ 'var cam_{{VCNODE_ID}} = _ref.get_viewport().get_camera_3d()\n' \
		+ 'if is_instance_valid(cam_{{VCNODE_ID}}):\n' \
		+ '\tvar screen_{{VCNODE_ID}}: Vector2 = _ref.get_viewport().get_mouse_position()\n' \
		+ '\tground_{{VCNODE_ID}} = Plane(Vector3.UP, {{height}}).intersects_ray(cam_{{VCNODE_ID}}.project_ray_origin(screen_{{VCNODE_ID}}), cam_{{VCNODE_ID}}.project_ray_normal(screen_{{VCNODE_ID}}))\n' \
		+ '{{out:result}}'
