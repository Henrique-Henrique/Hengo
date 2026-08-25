@tool
class_name HenActionMoveAlongPath extends HenScriptMacroBase


func get_id() -> StringName:
	return &'move_along_path'


func get_description() -> String:
	return 'Moves the body one step along the route a navigation agent planned, so it walks around walls instead of into them. Set Path Target picks the destination first.'


func get_display_name() -> String:
	return 'Move Along Path'


func get_icon() -> String:
	return 'route'


func get_target_classes() -> Array[StringName]:
	return [&'CharacterBody2D', &'CharacterBody3D']


func get_default_phase() -> StringName:
	return &'physics'


func get_inputs() -> Array[Dictionary]:
	return [
		node_ref_input('The body to move along the path. Leave it empty to move this node.'),
		{
			name = 'Agent',
			type = 'Node',
			id = &'agent',
			doc = 'The NavigationAgent2D or NavigationAgent3D node that plans the route.',
			bind_only = true,
			default_value = null
		},
		{
			name = 'Speed',
			type = 'float',
			id = &'speed',
			doc = 'How fast to follow the route, in pixels per second in 2D and in world units per second in 3D.',
			default_value = 100.0
		}
	]


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'}
	]


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


# 3d keeps velocity.y so the gravity written by another action is not wiped each frame
func _body() -> String:
	if targets(&'CharacterBody3D'):
		return 'var to_{{VCNODE_ID}} = {{agent}}.get_next_path_position() - {{ref}}.global_position\n' \
			+ 'var dir_{{VCNODE_ID}} = Vector3(to_{{VCNODE_ID}}.x, 0.0, to_{{VCNODE_ID}}.z).normalized()\n' \
			+ '{{ref}}.velocity = Vector3(dir_{{VCNODE_ID}}.x * {{speed}}, {{ref}}.velocity.y, dir_{{VCNODE_ID}}.z * {{speed}})\n' \
			+ '{{ref}}.move_and_slide()'

	return '{{ref}}.velocity = {{ref}}.global_position.direction_to({{agent}}.get_next_path_position()) * {{speed}}\n' \
		+ '{{ref}}.move_and_slide()'
