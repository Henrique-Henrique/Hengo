@tool
class_name HenActionRotateToward extends HenScriptMacroBase


# turns the owner a little each frame until it faces Target, instead of snapping
# like Look At. higher Speed turns faster.


# rotate_toward lands exactly, but a frame can still stop just short of it
const AIM_TOLERANCE: float = 0.02


func get_id() -> StringName:
	return &'rotate_toward'


func get_description() -> String:
	return 'Turns the node smoothly each frame until it faces a point, instead of snapping like Look At. Higher speed turns faster.'


func get_display_name() -> String:
	return 'Rotate Toward'


func get_icon() -> String:
	return 'crosshair'


func get_target_classes() -> Array[StringName]:
	return [&'Node2D']


func get_default_phase() -> StringName:
	return &'update'


func get_inputs() -> Array[Dictionary]:
	return [
		node_ref_input('The node to turn. Leave it empty to turn this node.'),
		{
			name = 'Target',
			type = 'Vector2',
			id = &'target',
			doc = 'The point in global space to face.',
			default_value = Vector2.ZERO
		},
		{
			name = 'Speed',
			type = 'float',
			id = &'speed',
			doc = 'How fast to turn, in degrees per second.',
			default_value = 360.0
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
			doc = 'Where to go once the node points at the target, give or take a degree.'
		},
		{
			name = 'Turning',
			id = &'turning',
			optional = true,
			doc = 'Where to go while the node is still off the target.'
		}
	]


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


# rotate_toward takes the short way around and never overshoots, which is what
# lerping the angle by hand gets wrong at the -180/180 seam
func _body() -> String:
	if not any_flow_connected():
		return '{{ref}}.rotation = rotate_toward({{ref}}.rotation, {{ref}}.global_position.angle_to_point({{target}}), deg_to_rad({{speed}}) * delta)'

	return 'var aim_{{VCNODE_ID}} = {{ref}}.global_position.angle_to_point({{target}})\n' \
		+ '{{ref}}.rotation = rotate_toward({{ref}}.rotation, aim_{{VCNODE_ID}}, deg_to_rad({{speed}}) * delta)\n' \
		+ 'if absf(angle_difference({{ref}}.rotation, aim_{{VCNODE_ID}})) <= ' + str(AIM_TOLERANCE) + ':\n' \
		+ '\t{{aimed}}\n' \
		+ 'else:\n' \
		+ '\t{{turning}}'
