@tool
class_name HenActionFollowMouse extends HenScriptMacroBase


# chases the mouse at Speed pixels per second, optionally facing it. the body
# needs delta, so only the update phase is offered.


func get_id() -> StringName:
	return &'follow_mouse'


func get_display_name() -> String:
	return 'Follow Mouse'


func get_icon() -> String:
	return 'mouse-pointer-2'


func get_target_classes() -> Array[StringName]:
	return [&'Node2D']


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Speed',
			type = 'float',
			id = &'speed',
			default_value = 200.0
		},
		{
			name = 'Rotate To Face',
			type = 'bool',
			id = &'rotate',
			default_value = true
		}
	]


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Update', id = &'update'}
	]


func get_flow_update() -> String:
	return 'var mouse_{{VCNODE_ID}}: Vector2 = _ref.get_global_mouse_position()\n' \
		+ 'if {{rotate}}:\n' \
		+ '\t_ref.look_at(mouse_{{VCNODE_ID}})\n' \
		+ '_ref.position = _ref.position.move_toward(mouse_{{VCNODE_ID}}, {{speed}} * delta)'
