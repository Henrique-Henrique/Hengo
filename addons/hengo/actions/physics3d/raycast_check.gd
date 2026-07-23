@tool
class_name HenActionRaycastCheck extends HenScriptMacroBase


# branches on what a RayCast node is touching right now. bind Ray to the node in
# the scene; it works with RayCast3D and RayCast2D alike.


func get_id() -> StringName:
	return &'raycast_check'


func get_display_name() -> String:
	return 'Raycast Check'


func get_icon() -> String:
	return 'crosshair'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Ray',
			type = 'Node',
			id = &'ray',
			bind_only = true,
			default_value = null
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Collider', type = 'Object', id = &'collider'},
		{name = 'Point', type = 'Vector3', id = &'point'},
		{name = 'Normal', type = 'Vector3', id = &'normal'}
	]


func get_output_collider() -> String:
	return 'ray_{{VCNODE_ID}}.get_collider()'


func get_output_point() -> String:
	return 'ray_{{VCNODE_ID}}.get_collision_point()'


func get_output_normal() -> String:
	return 'ray_{{VCNODE_ID}}.get_collision_normal()'


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'}
	]


func get_flow_outputs() -> Array[Dictionary]:
	return [
		{name = 'Hit', id = &'hit'},
		{name = 'Miss', id = &'miss'}
	]


func get_flow_enter() -> String:
	return _body()


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


# the update is forced before reading: on an idle frame is_colliding() still holds
# the result of the previous physics tick. the outputs land inside the hit branch,
# so an unbound one just drops its line
func _body() -> String:
	return 'var ray_{{VCNODE_ID}} = {{ray}}\n' \
		+ 'ray_{{VCNODE_ID}}.force_raycast_update()\n' \
		+ 'if ray_{{VCNODE_ID}}.is_colliding():\n' \
		+ '\t{{out:collider}}\n' \
		+ '\t{{out:point}}\n' \
		+ '\t{{out:normal}}\n' \
		+ '\t{{hit}}\n' \
		+ 'else:\n' \
		+ '\t{{miss}}'
