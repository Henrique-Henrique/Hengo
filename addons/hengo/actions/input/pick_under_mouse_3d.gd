@tool
class_name HenActionPickUnderMouse3D extends HenScriptMacroBase


func get_id() -> StringName:
	return &'pick_under_mouse_3d'


func get_description() -> String:
	return 'Asks the 3D physics world which collider sits under the mouse and branches on whether one is found. It shoots a ray from the active camera, so the scene needs one.'


func get_display_name() -> String:
	return 'Pick Under Mouse'


func get_icon() -> String:
	return 'mouse-pointer'


func get_target_classes() -> Array[StringName]:
	return [&'Node3D']


func get_default_phase() -> StringName:
	return &'physics'


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Collider', type = 'Object', id = &'collider', branch = &'hit', doc = 'Where to store the collider found under the mouse.'},
		{name = 'Point', type = 'Vector3', id = &'point', branch = &'hit', doc = 'Where to store the world position the ray touched.'}
	]


func get_output_collider() -> String:
	return 'found_{{VCNODE_ID}}.collider'


func get_output_point() -> String:
	return 'found_{{VCNODE_ID}}.position'


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Physics', id = &'physics'}
	]


func get_flow_outputs() -> Array[Dictionary]:
	return [
		{name = 'Hit', id = &'hit', doc = 'Where to go when a collider is under the mouse.'},
		{name = 'Miss', id = &'miss', doc = 'Where to go when nothing is under it, which is also the case while no camera is active.'}
	]


# a viewport with no active camera has no ray to cast, so it reads as a miss
func get_flow_physics() -> String:
	return 'var found_{{VCNODE_ID}} = {}\n' \
		+ 'var cam_{{VCNODE_ID}} = _ref.get_viewport().get_camera_3d()\n' \
		+ 'if is_instance_valid(cam_{{VCNODE_ID}}):\n' \
		+ '\tvar screen_{{VCNODE_ID}}: Vector2 = _ref.get_viewport().get_mouse_position()\n' \
		+ '\tvar from_{{VCNODE_ID}}: Vector3 = cam_{{VCNODE_ID}}.project_ray_origin(screen_{{VCNODE_ID}})\n' \
		+ '\tvar query_{{VCNODE_ID}} := PhysicsRayQueryParameters3D.create(from_{{VCNODE_ID}}, from_{{VCNODE_ID}} + cam_{{VCNODE_ID}}.project_ray_normal(screen_{{VCNODE_ID}}) * 1000.0)\n' \
		+ '\tquery_{{VCNODE_ID}}.collide_with_areas = true\n' \
		+ '\tfound_{{VCNODE_ID}} = _ref.get_world_3d().direct_space_state.intersect_ray(query_{{VCNODE_ID}})\n' \
		+ 'if not found_{{VCNODE_ID}}.is_empty():\n' \
		+ '\t{{out:collider}}\n' \
		+ '\t{{out:point}}\n' \
		+ '\t{{hit}}\n' \
		+ 'else:\n' \
		+ '\t{{miss}}'
