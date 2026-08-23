@tool
class_name HenActionCameraShake extends HenActionTweenBase


func get_id() -> StringName:
	return &'camera_shake'


func get_description() -> String:
	return 'Shakes a camera for a moment and settles it back, the punch a screen gets on a hit or an explosion. It runs once when the state starts. Wire Finished and the flow moves on by itself when it ends, with no timer of your own.'


func get_display_name() -> String:
	return 'Shake Camera'


func get_icon() -> String:
	return 'vibrate'


func get_default_phase() -> StringName:
	return &'enter'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Camera',
			type = 'Node',
			id = &'camera',
			doc = 'The camera to shake, a 2D or a 3D one.',
			bind_only = true,
			default_value = null
		},
		{
			name = 'Strength',
			type = 'float',
			id = &'strength',
			doc = 'How far the camera jumps at the start, in pixels on a 2D camera and in world units on a 3D one.',
			default_value = 8.0
		},
		{
			name = 'Duration',
			type = 'float',
			id = &'duration',
			doc = 'How long the shake takes to fade back to zero, in seconds.',
			default_value = 0.3
		}
	]


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'}
	]


func get_flow_enter() -> String:
	return _body()


# Camera3D has no offset property, only h_offset and v_offset
func _body() -> String:
	if targets(&'Node3D'):
		return 'var cam_{{VCNODE_ID}} = {{camera}}\n' \
			+ 'var shake_{{VCNODE_ID}} = _ref.create_tween()\n' \
			+ 'var jitter_h_{{VCNODE_ID}} = func(v: float) -> void: cam_{{VCNODE_ID}}.h_offset = randf_range(-v, v)\n' \
			+ 'var jitter_v_{{VCNODE_ID}} = func(v: float) -> void: cam_{{VCNODE_ID}}.v_offset = randf_range(-v, v)\n' \
			+ 'shake_{{VCNODE_ID}}.tween_method(jitter_h_{{VCNODE_ID}}, {{strength}}, 0.0, {{duration}})\n' \
			+ 'shake_{{VCNODE_ID}}.parallel().tween_method(jitter_v_{{VCNODE_ID}}, {{strength}}, 0.0, {{duration}})\n' \
			+ finish_hook('shake_{{VCNODE_ID}}')

	return 'var cam_{{VCNODE_ID}} = {{camera}}\n' \
		+ 'var shake_{{VCNODE_ID}} = _ref.create_tween()\n' \
		+ 'var jitter_{{VCNODE_ID}} = func(v: float) -> void: cam_{{VCNODE_ID}}.offset = Vector2(randf_range(-v, v), randf_range(-v, v))\n' \
		+ 'shake_{{VCNODE_ID}}.tween_method(jitter_{{VCNODE_ID}}, {{strength}}, 0.0, {{duration}})\n' \
		+ finish_hook('shake_{{VCNODE_ID}}')
