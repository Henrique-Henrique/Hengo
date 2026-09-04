@tool
class_name HenActionRotateToward3D extends HenScriptMacroBase


# turns the owner a little each frame until its front faces Target, instead of
# snapping like Look At. higher Speed turns faster. Up keeps it from rolling and
# must not point along the looking direction.


# a frame can stop just short of the target without landing on it exactly
const AIM_TOLERANCE: float = 0.02


func get_id() -> StringName:
	return &'rotate_toward_3d'


func get_description() -> String:
	return 'Turns the node smoothly each frame until its front faces a point, instead of snapping like Look At. Higher speed turns faster.'


func get_display_name() -> String:
	return 'Rotate Toward'


func get_icon() -> String:
	return 'crosshair'


func get_target_classes() -> Array[StringName]:
	return [&'Node3D']


func get_default_phase() -> StringName:
	return &'update'


func get_inputs() -> Array[Dictionary]:
	return [
		node_ref_input('The node to turn. Leave it empty to turn this node.'),
		{
			name = 'Target',
			type = 'Vector3',
			id = &'target',
			doc = 'The point in global space to face.',
			default_value = Vector3.ZERO
		},
		{
			name = 'Speed',
			type = 'float',
			id = &'speed',
			doc = 'How fast to turn, in degrees per second.',
			default_value = 360.0
		},
		{
			name = 'Up',
			type = 'Vector3',
			id = &'up',
			doc = 'Which direction is up, keeping the node from rolling. It must not point along the looking direction.',
			default_value = Vector3(0, 1, 0)
		}
	]


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'}
	]


func get_flow_outputs() -> Array[Dictionary]:
	return [
		{
			name = 'Aimed',
			id = &'aimed',
			optional = true,
			doc = 'Where to go once the front points at the target, give or take a degree.'
		},
		{
			name = 'Turning',
			id = &'turning',
			optional = true,
			doc = 'Where to go while the front is still off the target.'
		}
	]


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


# slerping by the fraction the frame's budget covers turns at a fixed rate and
# stops on the target, which is what the 2D one gets from the rotate_toward
# builtin. interpolate_with closes in asymptotically and never lands
# the guard skips the frame target and position coincide, where looking_at has no
# direction to face
func _turn() -> String:
	return 'var to_{{VCNODE_ID}} = {{target}}\n' \
		+ 'if not {{ref}}.global_position.is_equal_approx(to_{{VCNODE_ID}}):\n' \
		+ '\tvar aim_{{VCNODE_ID}} = {{ref}}.global_transform.looking_at(to_{{VCNODE_ID}}, {{up}}).basis.get_rotation_quaternion()\n' \
		+ '\tvar spin_{{VCNODE_ID}} = {{ref}}.global_basis.get_rotation_quaternion()\n' \
		+ '\tvar gap_{{VCNODE_ID}} = spin_{{VCNODE_ID}}.angle_to(aim_{{VCNODE_ID}})\n' \
		+ '\tif gap_{{VCNODE_ID}} > 0.0:\n' \
		+ '\t\t_ref.global_basis = Basis(spin_{{VCNODE_ID}}.slerp(aim_{{VCNODE_ID}}, clampf(deg_to_rad({{speed}}) * delta / gap_{{VCNODE_ID}}, 0.0, 1.0)))'


func _body() -> String:
	if not any_flow_connected():
		return _turn()

	return _turn() + '\n' \
		+ 'if (-{{ref}}.global_basis.z).angle_to(to_{{VCNODE_ID}} - {{ref}}.global_position) <= ' + str(AIM_TOLERANCE) + ':\n' \
		+ '\t{{aimed}}\n' \
		+ 'else:\n' \
		+ '\t{{turning}}'
