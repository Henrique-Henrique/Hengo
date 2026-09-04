@tool
class_name HenActionMouseLook extends HenScriptMacroBase


# first person camera: the owner turns sideways and the Camera looks up and down.
# mouse motion only reaches a script through _input, so this action installs one
# and the state arms it on entry and drops it on exit.


func get_id() -> StringName:
	return &'mouse_look'


func get_description() -> String:
	return 'Turns the body left and right and tilts a camera up and down from mouse motion, for a first person view.'


func get_display_name() -> String:
	return 'Mouse Look'


func get_icon() -> String:
	return 'eye'


func get_target_classes() -> Array[StringName]:
	return [&'Node3D']


func get_default_phase() -> StringName:
	return &'physics'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Camera',
			type = 'Node',
			id = &'camera',
			doc = 'The camera node that tilts up and down.',
			bind_only = true,
			default_value = null
		},
		{
			name = 'Sensitivity',
			type = 'float',
			id = &'sensitivity',
			doc = 'How much the view moves per pixel of mouse motion.',
			default_value = 0.003
		},
		{
			name = 'Max Pitch',
			type = 'float',
			id = &'max_pitch',
			doc = 'How far the camera can look up or down, in degrees.',
			default_value = 85.0
		}
	]


# script scope, not state scope: _input runs on the node, and the state class
# reaches these through `_ref.`
func get_script_scope() -> String:
	return 'var look_on_{{VCNODE_ID}}: bool = false\n' \
		+ 'var look_move_{{VCNODE_ID}}: Vector2 = Vector2.ZERO'


func get_function_overrides() -> Array[Dictionary]:
	return [
		{
			name = '_input',
			params = [ {name = 'event', type = 'InputEvent'} ],
			body = 'if look_on_{{VCNODE_ID}} and event is InputEventMouseMotion:\n\tlook_move_{{VCNODE_ID}} += event.relative'
		}
	]


func get_flow_reset() -> String:
	return '_ref.look_on_{{VCNODE_ID}} = true\n_ref.look_move_{{VCNODE_ID}} = Vector2.ZERO'


func get_flow_teardown() -> String:
	return '_ref.look_on_{{VCNODE_ID}} = false'


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'}
	]


# the camera is resolved once: bound to a node path it is a get_node() call
func _body() -> String:
	return 'var cam_{{VCNODE_ID}} = {{camera}}\n' \
		+ 'var pitch_{{VCNODE_ID}}: float = deg_to_rad({{max_pitch}})\n' \
		+ '_ref.rotate_y(-_ref.look_move_{{VCNODE_ID}}.x * {{sensitivity}})\n' \
		+ 'cam_{{VCNODE_ID}}.rotation.x = clamp(cam_{{VCNODE_ID}}.rotation.x - _ref.look_move_{{VCNODE_ID}}.y * {{sensitivity}}, -pitch_{{VCNODE_ID}}, pitch_{{VCNODE_ID}})\n' \
		+ '_ref.look_move_{{VCNODE_ID}} = Vector2.ZERO'
