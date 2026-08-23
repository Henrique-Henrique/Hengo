@tool
class_name HenActionTweenRotate extends HenActionTweenBase


# animates rotation toward To Degrees over Duration seconds. fire-and-forget, so
# it runs on enter, not per-frame.


func get_id() -> StringName:
	return &'tween_rotate'


func get_description() -> String:
	return 'Smoothly rotates the node to a target angle over time. Runs once when the state starts. Wire Finished and the flow moves on by itself when it ends, with no timer of your own.'


func get_display_name() -> String:
	return 'Tween Rotate'


func get_icon() -> String:
	return 'rotate-cw'


func get_target_classes() -> Array[StringName]:
	return [&'Node2D']


func get_default_phase() -> StringName:
	return &'enter'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'To Degrees',
			type = 'float',
			id = &'to',
				doc = 'The target angle, in degrees.',
			default_value = 0.0
		},
		{
			name = 'Duration',
			type = 'float',
			id = &'duration',
				doc = 'How long the rotation takes, in seconds.',
			default_value = 0.3
		}
	]


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'}
	]


func get_flow_enter() -> String:
	return _body()


func _body() -> String:
	return start_tween('tween_property(_ref, "rotation", deg_to_rad({{to}}), {{duration}})')
