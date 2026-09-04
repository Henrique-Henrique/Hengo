@tool
class_name HenActionMoveRelative extends HenScriptMacroBase


# walks the body in the direction it is facing: Direction.x is sideways and
# Direction.y is forward, so it pairs with Get Move Vector. it writes the
# horizontal velocity and leaves the vertical one to gravity.


func get_id() -> StringName:
	return &'move_relative'


func get_description() -> String:
	return 'Moves the body across the ground in a direction relative to where it is facing, leaving vertical velocity to gravity.'


func get_display_name() -> String:
	return 'Move Relative'


func get_icon() -> String:
	return 'navigation'


func get_target_classes() -> Array[StringName]:
	return [&'CharacterBody3D']


func get_default_phase() -> StringName:
	return &'physics'


func get_inputs() -> Array[Dictionary]:
	return [
		node_ref_input('The body to move. Leave it empty to move this node.'),
		{
			name = 'Direction',
			type = 'Vector2',
			id = &'direction',
				doc = 'Movement direction relative to the body, with x sideways and y forward.',
			default_value = Vector2.ZERO
		},
		{
			name = 'Speed',
			type = 'float',
			id = &'speed',
				doc = 'How fast to move, in units per second.',
			default_value = 6.0
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


func _body() -> String:
	return 'var dir_{{VCNODE_ID}}: Vector2 = {{direction}}\n' \
		+ 'var world_{{VCNODE_ID}}: Vector3 = ({{ref}}.transform.basis * Vector3(dir_{{VCNODE_ID}}.x, 0, dir_{{VCNODE_ID}}.y)).normalized()\n' \
		+ '{{ref}}.velocity.x = world_{{VCNODE_ID}}.x * {{speed}}\n' \
		+ '{{ref}}.velocity.z = world_{{VCNODE_ID}}.z * {{speed}}'
