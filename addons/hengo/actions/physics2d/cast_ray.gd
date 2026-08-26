@tool
class_name HenActionCastRay extends HenScriptMacroBase


func get_id() -> StringName:
	return &'cast_ray'


func get_description() -> String:
	return 'Shoots an invisible line between two points and branches on whether it touched anything. On a hit it reports the node that was touched, the contact point and the surface normal.'


func get_display_name() -> String:
	return 'Cast Ray'


func get_icon() -> String:
	return 'crosshair'


func get_target_classes() -> Array[StringName]:
	return [&'Node2D']


func get_default_phase() -> StringName:
	return &'physics'


func get_inputs() -> Array[Dictionary]:
	return [
		node_ref_input('The node the ray starts from. Leave it empty to start from this node.'),
		{
			name = 'From',
			type = 'Vector2',
			id = &'from',
			doc = 'The global point the line starts at, usually the position of this node.',
			default_value = Vector2.ZERO
		},
		{
			name = 'To',
			type = 'Vector2',
			id = &'to',
			doc = 'The global point the line ends at.',
			default_value = Vector2.ZERO
		},
		{
			name = 'Ignore Self',
			type = 'bool',
			id = &'ignore_self',
			doc = 'True to skip the body of this node, so a line starting inside it does not hit it.',
			default_value = true
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Collider', type = 'Object', id = &'collider', branch = &'hit', doc = 'The node the line touched.'},
		{name = 'Point', type = 'Vector2', id = &'point', branch = &'hit', doc = 'The global position where the line touched it.'},
		{name = 'Normal', type = 'Vector2', id = &'normal', branch = &'hit', doc = 'The direction the touched surface faces.'}
	]


func get_output_collider() -> String:
	return 'hit_{{VCNODE_ID}}.collider'


func get_output_point() -> String:
	return 'hit_{{VCNODE_ID}}.position'


func get_output_normal() -> String:
	return 'hit_{{VCNODE_ID}}.normal'


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'}
	]


func get_flow_outputs() -> Array[Dictionary]:
	return [
		{name = 'Hit', id = &'hit', doc = 'Where to go when the line touches something.'},
		{name = 'Miss', id = &'miss', doc = 'Where to go when the line touches nothing.'}
	]


func get_flow_enter() -> String:
	return _body()


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


# get_rid() lives on CollisionObject2D, so a plain Node2D owner has nothing to skip
func _body() -> String:
	return _self_skip() \
		+ 'var query_{{VCNODE_ID}} = PhysicsRayQueryParameters2D.create({{from}}, {{to}})\n' \
		+ 'query_{{VCNODE_ID}}.exclude = skip_{{VCNODE_ID}}\n' \
		+ 'var hit_{{VCNODE_ID}} = _ref.get_world_2d().direct_space_state.intersect_ray(query_{{VCNODE_ID}})\n' \
		+ 'if not hit_{{VCNODE_ID}}.is_empty():\n' \
		+ '\t{{out:collider}}\n' \
		+ '\t{{out:point}}\n' \
		+ '\t{{out:normal}}\n' \
		+ '\t{{hit}}\n' \
		+ 'else:\n' \
		+ '\t{{miss}}'


# the script class already answers whether the owner is a collision object, so
# only the user's own toggle is left for runtime
func _self_skip() -> String:
	var empty: String = 'var skip_{{VCNODE_ID}}: Array[RID] = []\n'

	if not targets(&'CollisionObject2D'):
		return empty

	# a toggle nobody bound is known here, so the branch never reaches the game
	if not is_bound(&'ignore_self'):
		if not bool(value_of(&'ignore_self', true)):
			return empty

		return 'var skip_{{VCNODE_ID}}: Array[RID] = [({{ref}} as CollisionObject2D).get_rid()]\n'

	return empty \
		+ 'if {{ignore_self}}:\n' \
		+ '\tskip_{{VCNODE_ID}}.append(({{ref}} as CollisionObject2D).get_rid())\n'
