@tool
class_name HenActionBodiesInRadius extends HenScriptMacroBase


func get_id() -> StringName:
	return &'bodies_in_radius'


func get_description() -> String:
	return 'Asks the physics world which bodies sit inside a circle around this node and stores them as a list. Use it for a blast, a shockwave or a scan of what is near.'


func get_display_name() -> String:
	return 'Get Bodies In Radius'


func get_icon() -> String:
	return 'radar'


func get_target_classes() -> Array[StringName]:
	return [&'Node2D', &'Node3D']


func get_default_phase() -> StringName:
	return &'physics'


func get_inputs() -> Array[Dictionary]:
	return [
		node_ref_input('The node the circle is centered on. Leave it empty to center it on this node.'),
		{
			name = 'Radius',
			type = 'float',
			id = &'radius',
			doc = 'How far around the node to look, in pixels in 2D and in meters in 3D.',
			default_value = 100.0
		},
		{
			name = 'Mask',
			type = 'int',
			id = &'mask',
			doc = 'Which collision layers to look at, as the same number the inspector shows for a collision mask.',
			default_value = 1
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Result', type = 'Array', id = &'result', doc = 'The bodies found inside the circle, without this node.'}
	]


func get_output_result() -> String:
	return 'list_{{VCNODE_ID}}'


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'}
	]


func get_flow_outputs() -> Array[Dictionary]:
	return [
		{
			name = 'Any',
			id = &'any',
			optional = true,
			doc = 'Where to go when at least one body sits inside the radius.'
		},
		{
			name = 'None',
			id = &'none',
			optional = true,
			doc = 'Where to go when the radius is clear, which is when an empty list is stored.'
		}
	]


func get_flow_enter() -> String:
	return _body()


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


# intersect_shape needs a result cap
func _body() -> String:
	var tail: String = ''

	if any_flow_connected():
		tail = '\nif not list_{{VCNODE_ID}}.is_empty():\n' \
			+ '\t{{any}}\n' \
			+ 'else:\n' \
			+ '\t{{none}}'

	if targets(&'Node3D'):
		return _self_skip(&'CollisionObject3D') \
			+ 'var shape_{{VCNODE_ID}} = SphereShape3D.new()\n' \
			+ 'shape_{{VCNODE_ID}}.radius = {{radius}}\n' \
			+ 'var query_{{VCNODE_ID}} = PhysicsShapeQueryParameters3D.new()\n' \
			+ 'query_{{VCNODE_ID}}.shape = shape_{{VCNODE_ID}}\n' \
			+ 'query_{{VCNODE_ID}}.transform = Transform3D(Basis.IDENTITY, {{ref}}.global_position)\n' \
			+ 'query_{{VCNODE_ID}}.collision_mask = {{mask}}\n' \
			+ 'query_{{VCNODE_ID}}.exclude = skip_{{VCNODE_ID}}\n' \
			+ 'var found_{{VCNODE_ID}} = _ref.get_world_3d().direct_space_state.intersect_shape(query_{{VCNODE_ID}}, 32)\n' \
			+ 'var list_{{VCNODE_ID}}: Array = []\n' \
			+ 'for item_{{VCNODE_ID}} in found_{{VCNODE_ID}}:\n' \
			+ '\tlist_{{VCNODE_ID}}.append(item_{{VCNODE_ID}}.collider)\n' \
			+ '{{out:result}}' + tail

	return _self_skip(&'CollisionObject2D') \
		+ 'var shape_{{VCNODE_ID}} = CircleShape2D.new()\n' \
		+ 'shape_{{VCNODE_ID}}.radius = {{radius}}\n' \
		+ 'var query_{{VCNODE_ID}} = PhysicsShapeQueryParameters2D.new()\n' \
		+ 'query_{{VCNODE_ID}}.shape = shape_{{VCNODE_ID}}\n' \
		+ 'query_{{VCNODE_ID}}.transform = Transform2D(0.0, {{ref}}.global_position)\n' \
		+ 'query_{{VCNODE_ID}}.collision_mask = {{mask}}\n' \
		+ 'query_{{VCNODE_ID}}.exclude = skip_{{VCNODE_ID}}\n' \
		+ 'var found_{{VCNODE_ID}} = _ref.get_world_2d().direct_space_state.intersect_shape(query_{{VCNODE_ID}}, 32)\n' \
		+ 'var list_{{VCNODE_ID}}: Array = []\n' \
		+ 'for item_{{VCNODE_ID}} in found_{{VCNODE_ID}}:\n' \
		+ '\tlist_{{VCNODE_ID}}.append(item_{{VCNODE_ID}}.collider)\n' \
		+ '{{out:result}}' + tail


# the owner excludes itself from the query only when the script is a collision
# object, which the class it extends already answers: no `is` reaches the game
func _self_skip(_class: StringName) -> String:
	if not targets(_class):
		return 'var skip_{{VCNODE_ID}}: Array[RID] = []\n'

	return 'var skip_{{VCNODE_ID}}: Array[RID] = [({{ref}} as ' + str(_class) + ').get_rid()]\n'
