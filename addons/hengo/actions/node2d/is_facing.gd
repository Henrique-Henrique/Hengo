@tool
class_name HenActionIsFacing extends HenScriptMacroBase


func get_id() -> StringName:
	return &'is_facing'


func get_description() -> String:
	return 'Checks whether the node is turned toward a point, inside a cone of the given width, and branches on the answer. It fits an enemy that only notices what is in front of it, or a turret that only shoots forward.'


func get_display_name() -> String:
	return 'Is Facing'


func get_icon() -> String:
	return 'radar'


func get_target_classes() -> Array[StringName]:
	return [&'Node2D']


func get_default_phase() -> StringName:
	return &'update'


func get_inputs() -> Array[Dictionary]:
	return [
		node_ref_input('The node that does the facing. Leave it empty to check this node.'),
		{
			name = 'Target',
			type = 'Variant',
			id = &'target',
			doc = 'The point to face. A node works too, its global position is read.',
			default_value = null
		},
		{
			name = 'Angle',
			type = 'float',
			id = &'angle',
			doc = 'Half the width of the cone in degrees, so 45 accepts a target up to 45 degrees off to either side.',
			default_value = 45.0
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
		{name = 'Facing', id = &'facing', doc = 'Where to go while the target is inside the cone.'},
		{name = 'Away', id = &'away', doc = 'Where to go while the target is outside it.'}
	]


func get_flow_enter() -> String:
	return _body()


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


# get_angle_to already answers in the local frame, so the rotation of the node is
# the direction it faces and no forward vector has to be built
func _body() -> String:
	return 'var target_{{VCNODE_ID}} = {{target}}\n' \
		+ 'var point_{{VCNODE_ID}} = target_{{VCNODE_ID}}.global_position if target_{{VCNODE_ID}} is Node2D else target_{{VCNODE_ID}}\n' \
		+ 'if absf({{ref}}.get_angle_to(point_{{VCNODE_ID}})) <= deg_to_rad({{angle}}):\n' \
		+ '\t{{facing}}\n' \
		+ 'else:\n' \
		+ '\t{{away}}'
