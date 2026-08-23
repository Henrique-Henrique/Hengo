@tool
class_name HenActionTweenMove extends HenActionTweenBase


# animates position toward To over Duration seconds. create_tween is
# fire-and-forget, so it belongs on enter, never per-frame.


func get_id() -> StringName:
	return &'tween_move'


func get_description() -> String:
	return 'Smoothly moves the node to a target position over time. Runs once when the state starts. Wire Finished and the flow moves on by itself when it ends, with no timer of your own.'


func get_display_name() -> String:
	return 'Tween Move'


func get_icon() -> String:
	return 'move'


func get_target_classes() -> Array[StringName]:
	return [&'Node2D']


func get_default_phase() -> StringName:
	return &'enter'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'To',
			type = 'Vector2',
			id = &'to',
				doc = 'The position to move to.',
			default_value = Vector2.ZERO
		},
		{
			name = 'Duration',
			type = 'float',
			id = &'duration',
				doc = 'How long the movement takes, in seconds.',
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
	return start_tween('tween_property(_ref, "position", {{to}}, {{duration}})')
