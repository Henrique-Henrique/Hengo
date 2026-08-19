@tool
class_name HenActionCameraFollow extends HenScriptMacroBase


func get_id() -> StringName:
	return &'camera_follow'


func get_description() -> String:
	return 'Glides a camera toward a node every frame, so it trails the target instead of snapping onto it. Works with a 2D and a 3D camera.'


func get_display_name() -> String:
	return 'Follow With Camera'


func get_icon() -> String:
	return 'target'


func get_default_phase() -> StringName:
	return &'update'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Camera',
			type = 'Node',
			id = &'camera',
			doc = 'The camera that moves, a 2D or a 3D one.',
			bind_only = true,
			default_value = null
		},
		{
			name = 'Target',
			type = 'Node',
			id = &'target',
			doc = 'The node the camera chases.',
			bind_only = true,
			default_value = null
		},
		{
			name = 'Speed',
			type = 'float',
			id = &'speed',
			doc = 'How fast the camera catches up. A bigger value follows tighter.',
			default_value = 5.0
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
	return '{{camera}}.global_position = {{camera}}.global_position.lerp({{target}}.global_position, clampf({{speed}} * delta, 0.0, 1.0))'
