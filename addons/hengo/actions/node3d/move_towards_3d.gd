@tool
class_name HenActionMoveTowards3D extends HenScriptMacroBase


# steps the owner toward Target at Speed units per second, stopping on arrival.
# the body needs delta, so enter and exit are not offered.


func get_id() -> StringName:
	return &'move_towards_3d'


func get_description() -> String:
	return 'Moves the node a step toward a target each frame, stopping once it arrives.'


func get_display_name() -> String:
	return 'Move Towards'


func get_icon() -> String:
	return 'navigation'


func get_target_classes() -> Array[StringName]:
	return [&'Node3D']


func get_inputs() -> Array[Dictionary]:
	return [
		node_ref_input('The node to move. Leave it empty to move this node.'),
		{
			name = 'Target',
			type = 'Vector3',
			id = &'target',
			doc = 'The point in global space to move toward.',
			default_value = Vector3.ZERO
		},
		{
			name = 'Speed',
			type = 'float',
			id = &'speed',
			doc = 'How fast to move, in world units per second.',
			default_value = 5.0
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
			name = 'Arrived',
			id = &'arrived',
			optional = true,
			doc = 'Where to go on the frame the node lands on the target.'
		},
		{
			name = 'Moving',
			id = &'moving',
			optional = true,
			doc = 'Where to go while the target is still ahead.'
		}
	]


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


# move_toward returns the target itself once the step covers what is left
func _body() -> String:
	if not any_flow_connected():
		return '{{ref}}.position = {{ref}}.position.move_toward({{target}}, {{speed}} * delta)'

	return 'var to_{{VCNODE_ID}} = {{target}}\n' \
		+ '{{ref}}.position = {{ref}}.position.move_toward(to_{{VCNODE_ID}}, {{speed}} * delta)\n' \
		+ 'if {{ref}}.position.is_equal_approx(to_{{VCNODE_ID}}):\n' \
		+ '\t{{arrived}}\n' \
		+ 'else:\n' \
		+ '\t{{moving}}'
