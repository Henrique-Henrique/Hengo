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
		node_ref_input('The node that looks. Leave it empty to look from this node.'),
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
			+ _self_skip(&'CollisionObject3D') \
			+ 'var query_{{VCNODE_ID}} = PhysicsRayQueryParameters3D.create({{ref}}.global_position, target_{{VCNODE_ID}}.global_position)\n' \
			+ 'query_{{VCNODE_ID}}.exclude = skip_{{VCNODE_ID}}\n' \
			+ 'var hit_{{VCNODE_ID}} = _ref.get_world_3d().direct_space_state.intersect_ray(query_{{VCNODE_ID}})\n' \
			+ 'if hit_{{VCNODE_ID}}.is_empty() or hit_{{VCNODE_ID}}.collider == target_{{VCNODE_ID}}:\n' \
			+ '\t{{clear}}\n' \
			+ 'else:\n' \
			+ '\t{{blocked}}'

	return 'var target_{{VCNODE_ID}} = {{target}}\n' \
		+ _self_skip(&'CollisionObject2D') \
		+ 'var query_{{VCNODE_ID}} = PhysicsRayQueryParameters2D.create({{ref}}.global_position, target_{{VCNODE_ID}}.global_position)\n' \
		+ 'query_{{VCNODE_ID}}.exclude = skip_{{VCNODE_ID}}\n' \
		+ 'var hit_{{VCNODE_ID}} = _ref.get_world_2d().direct_space_state.intersect_ray(query_{{VCNODE_ID}})\n' \
		+ 'if hit_{{VCNODE_ID}}.is_empty() or hit_{{VCNODE_ID}}.collider == target_{{VCNODE_ID}}:\n' \
		+ '\t{{clear}}\n' \
		+ 'else:\n' \
		+ '\t{{blocked}}'


# the owner excludes itself from the query only when the script is a collision
# object, which the class it extends already answers: no `is` reaches the game
func _self_skip(_class: StringName) -> String:
	if not targets(_class):
		return 'var skip_{{VCNODE_ID}}: Array[RID] = []\n'

	return 'var skip_{{VCNODE_ID}}: Array[RID] = [({{ref}} as ' + str(_class) + ').get_rid()]\n'
