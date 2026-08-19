@tool
class_name HenActionCameraFov extends HenScriptMacroBase


func get_id() -> StringName:
	return &'camera_fov'


func get_description() -> String:
	return 'Sets the field of view of a 3D camera in degrees, where a wider angle exaggerates speed and a narrower one looks zoomed in. On update or physics it can ease toward the value instead of snapping.'


func get_display_name() -> String:
	return 'Set Field Of View'


func get_icon() -> String:
	return 'aperture'


func get_default_phase() -> StringName:
	return &'enter'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Camera',
			type = 'Node',
			id = &'camera',
			doc = 'The 3D camera to change.',
			bind_only = true,
			default_value = null
		},
		{
			name = 'FOV',
			type = 'float',
			id = &'fov',
			doc = 'The field of view in degrees, around 75 for a normal view.',
			default_value = 75.0
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
	return '{{camera}}.fov = {{fov}}'


func get_flow_update() -> String:
	return _eased_body()


func get_flow_physics() -> String:
	return _eased_body()


func _eased_body() -> String:
	return 'if {{speed}} > 0.0:\n' \
		+ '\t{{camera}}.fov = lerpf({{camera}}.fov, {{fov}}, clampf({{speed}} * delta, 0.0, 1.0))\n' \
		+ 'else:\n' \
		+ '\t{{camera}}.fov = {{fov}}'
