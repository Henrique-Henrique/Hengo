@tool
class_name HenActionTweenFade extends HenActionTweenBase


# animates modulate alpha toward To Alpha over Duration seconds. fire-and-forget,
# so it runs on enter, not per-frame.


func get_id() -> StringName:
	return &'tween_fade'


func get_description() -> String:
	return 'Smoothly fades the node toward a target transparency over time. Wire Finished and the flow moves on by itself when it ends, with no timer of your own. On enter it plays once; on update or physics it starts again as soon as the last one ended, so it keeps repeating while the state runs.'


func get_display_name() -> String:
	return 'Tween Fade'


func get_icon() -> String:
	return 'eye'


func get_target_classes() -> Array[StringName]:
	return [&'CanvasItem']


func get_inputs() -> Array[Dictionary]:
	return [
		node_ref_input('The node to fade. Leave it empty to fade this node.'),
		{
			name = 'To Alpha',
			type = 'float',
			id = &'to',
				doc = 'Target transparency, where 1 is fully visible and 0 is invisible.',
			default_value = 1.0
		},
		{
			name = 'Duration',
			type = 'float',
			id = &'duration',
				doc = 'How long the fade takes, in seconds.',
			default_value = 0.3
		}
	]




func get_flow_enter() -> String:
	return _body()


func get_flow_update() -> String:
	return guard_per_frame(_body())


func get_flow_physics() -> String:
	return guard_per_frame(_body())


func _body() -> String:
	return start_tween('tween_property({{ref}}, "modulate:a", {{to}}, {{duration}})')
