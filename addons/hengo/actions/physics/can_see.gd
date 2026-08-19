@tool
class_name HenActionCanSee extends HenScriptMacroBase


func get_id() -> StringName:
	return &'can_see'


func get_description() -> String:
	return 'Checks whether a straight line from this node to another node is free of obstacles. It is the usual way to give an enemy a line of sight.'


func get_display_name() -> String:
	return 'Can See'


func get_icon() -> String:
	return 'eye'


func get_target_classes() -> Array[StringName]:
	return [&'Node2D', &'Node3D']


func get_default_phase() -> StringName:
	return &'physics'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Target',
			type = 'Node',
			id = &'target',
			doc = 'The node to look at, such as the player. Point it at the body itself, since a parent above the collider never matches.',
			bind_only = true,
			default_value = null
		}
	]


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'}
	]


func get_flow_outputs() -> Array[Dictionary]:
	return [
		{name = 'Clear', id = &'clear', doc = 'Where to go when nothing stands between the two nodes.'},
		{name = 'Blocked', id = &'blocked', doc = 'Where to go when something is in the way.'}
	]


func get_flow_enter() -> String:
	return _body()


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


# the line ends inside the target body, so touching the target still counts as clear
func _body() -> String:
	if targets(&'Node3D'):
		return 'var target_{{VCNODE_ID}} = {{target}}\n' \
			+ 'var skip_{{VCNODE_ID}}: Array[RID] = []\n' \
			+ 'if _ref is CollisionObject3D:\n' \
			+ '\tskip_{{VCNODE_ID}}.append((_ref as CollisionObject3D).get_rid())\n' \
			+ 'var query_{{VCNODE_ID}} = PhysicsRayQueryParameters3D.create(_ref.global_position, target_{{VCNODE_ID}}.global_position)\n' \
			+ 'query_{{VCNODE_ID}}.exclude = skip_{{VCNODE_ID}}\n' \
			+ 'var hit_{{VCNODE_ID}} = _ref.get_world_3d().direct_space_state.intersect_ray(query_{{VCNODE_ID}})\n' \
			+ 'if hit_{{VCNODE_ID}}.is_empty() or hit_{{VCNODE_ID}}.collider == target_{{VCNODE_ID}}:\n' \
			+ '\t{{clear}}\n' \
			+ 'else:\n' \
			+ '\t{{blocked}}'

	return 'var target_{{VCNODE_ID}} = {{target}}\n' \
		+ 'var skip_{{VCNODE_ID}}: Array[RID] = []\n' \
		+ 'if _ref is CollisionObject2D:\n' \
		+ '\tskip_{{VCNODE_ID}}.append((_ref as CollisionObject2D).get_rid())\n' \
		+ 'var query_{{VCNODE_ID}} = PhysicsRayQueryParameters2D.create(_ref.global_position, target_{{VCNODE_ID}}.global_position)\n' \
		+ 'query_{{VCNODE_ID}}.exclude = skip_{{VCNODE_ID}}\n' \
		+ 'var hit_{{VCNODE_ID}} = _ref.get_world_2d().direct_space_state.intersect_ray(query_{{VCNODE_ID}})\n' \
		+ 'if hit_{{VCNODE_ID}}.is_empty() or hit_{{VCNODE_ID}}.collider == target_{{VCNODE_ID}}:\n' \
		+ '\t{{clear}}\n' \
		+ 'else:\n' \
		+ '\t{{blocked}}'
