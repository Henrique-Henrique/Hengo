@tool
class_name HenActionRotateToward3D extends HenScriptMacroBase


# turns the owner a little each frame until its front faces Target, instead of
# snapping like Look At. higher Speed turns faster. Up keeps it from rolling and
# must not point along the looking direction.


func get_id() -> StringName:
	return &'rotate_toward_3d'


func get_description() -> String:
	return 'Turns the node smoothly each frame until its front faces a point, instead of snapping like Look At. Higher speed turns faster.'


func get_display_name() -> String:
	return 'Rotate Toward'


func get_icon() -> String:
	return 'crosshair'


func get_target_classes() -> Array[StringName]:
	return [&'Node3D']


func get_default_phase() -> StringName:
	return &'update'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Target',
			type = 'Vector3',
			id = &'target',
			doc = 'The point in global space to face.',
			default_value = Vector3.ZERO
		},
		{
			name = 'Speed',
			type = 'float',
			id = &'speed',
			doc = 'How fast to turn. Higher reaches the target sooner.',
			default_value = 5.0
		},
		{
			name = 'Up',
			type = 'Vector3',
			id = &'up',
			doc = 'Which direction is up, keeping the node from rolling. It must not point along the looking direction.',
			default_value = Vector3(0, 1, 0)
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


# looking_at keeps the same origin, so interpolate_with only turns the node, it
# never drifts. the guard skips the frame target and position coincide, where
# looking_at has no direction to face
func _body() -> String:
	return 'if not _ref.global_position.is_equal_approx({{target}}):\n' \
		+ '\t_ref.global_transform = _ref.global_transform.interpolate_with(_ref.global_transform.looking_at({{target}}, {{up}}), clampf({{speed}} * delta, 0.0, 1.0))'
