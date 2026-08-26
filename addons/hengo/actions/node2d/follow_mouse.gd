@tool
class_name HenActionFollowMouse extends HenScriptMacroBase


# chases the mouse at Speed pixels per second, optionally facing it. the body
# needs delta, so only the update phase is offered.


func get_id() -> StringName:
	return &'follow_mouse'


func get_description() -> String:
	return 'Continuously moves the node toward the mouse, optionally turning to face it.'


func get_display_name() -> String:
	return 'Follow Mouse'


func get_icon() -> String:
	return 'mouse-pointer-2'


func get_target_classes() -> Array[StringName]:
	return [&'Node2D']


func get_inputs() -> Array[Dictionary]:
	return [
		node_ref_input('The node to move. Leave it empty to move this node.'),
		{
			name = 'Speed',
			type = 'float',
			id = &'speed',
			doc = 'How fast to move toward the mouse, in pixels per second.',
			default_value = 200.0
		},
		{
			name = 'Rotate To Face',
			type = 'bool',
			id = &'rotate',
			doc = 'When true, the node turns to face the mouse.',
			default_value = true
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
	return 'var mouse_{{VCNODE_ID}}: Vector2 = _ref.get_global_mouse_position()\n' \
		+ 'if {{rotate}}:\n' \
		+ '\t{{ref}}.look_at(mouse_{{VCNODE_ID}})\n' \
		+ '{{ref}}.position = {{ref}}.position.move_toward(mouse_{{VCNODE_ID}}, {{speed}} * delta)'
