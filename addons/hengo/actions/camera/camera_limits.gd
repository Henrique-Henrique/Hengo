@tool
class_name HenActionCameraLimits extends HenScriptMacroBase


func get_id() -> StringName:
	return &'camera_limits'


func get_description() -> String:
	return 'Fences a 2D camera inside a rectangle so it stops at the edges of the level instead of showing the empty space around it.'


func get_display_name() -> String:
	return 'Set Camera Limits'


func get_icon() -> String:
	return 'crop'


func get_default_phase() -> StringName:
	return &'enter'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Camera',
			type = 'Node',
			id = &'camera',
			doc = 'The 2D camera to fence in.',
			bind_only = true,
			default_value = null
		},
		{
			name = 'Min',
			type = 'Vector2',
			id = &'min',
			doc = 'The top-left corner of the area the camera can reach.',
			default_value = Vector2(-1000, -1000)
		},
		{
			name = 'Max',
			type = 'Vector2',
			id = &'max',
			doc = 'The bottom-right corner of the area the camera can reach.',
			default_value = Vector2(1000, 1000)
		}
	]


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'},
		{name = 'Exit', id = &'exit'}
	]


func get_flow_enter() -> String:
	return _body()


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


func get_flow_exit() -> String:
	return _body()


# the limit properties on Camera2D are ints, not floats
func _body() -> String:
	return '{{camera}}.limit_left = int({{min}}.x)\n' \
		+ '{{camera}}.limit_top = int({{min}}.y)\n' \
		+ '{{camera}}.limit_right = int({{max}}.x)\n' \
		+ '{{camera}}.limit_bottom = int({{max}}.y)'
