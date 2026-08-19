@tool
class_name HenActionCameraZoom extends HenScriptMacroBase


func get_id() -> StringName:
	return &'camera_zoom'


func get_description() -> String:
	return 'Sets how close a 2D camera looks, where a bigger value gets closer. On update or physics it can ease toward the value instead of snapping.'


func get_display_name() -> String:
	return 'Zoom Camera'


func get_icon() -> String:
	return 'zoom-in'


func get_default_phase() -> StringName:
	return &'enter'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Camera',
			type = 'Node',
			id = &'camera',
			doc = 'The 2D camera to zoom.',
			bind_only = true,
			default_value = null
		},
		{
			name = 'Zoom',
			type = 'float',
			id = &'zoom',
			doc = 'The zoom factor, where 1 is the normal view and 2 looks twice as close.',
			default_value = 1.0
		},
		{
			name = 'Speed',
			type = 'float',
			id = &'speed',
			doc = 'How fast it eases toward the value on update or physics. Zero jumps straight to it.',
			default_value = 0.0
		}
	]


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'}
	]


func get_flow_enter() -> String:
	return '{{camera}}.zoom = Vector2.ONE * {{zoom}}'


func get_flow_update() -> String:
	return _eased_body()


func get_flow_physics() -> String:
	return _eased_body()


func _eased_body() -> String:
	return 'if {{speed}} > 0.0:\n' \
		+ '\t{{camera}}.zoom = {{camera}}.zoom.lerp(Vector2.ONE * {{zoom}}, clampf({{speed}} * delta, 0.0, 1.0))\n' \
		+ 'else:\n' \
		+ '\t{{camera}}.zoom = Vector2.ONE * {{zoom}}'
