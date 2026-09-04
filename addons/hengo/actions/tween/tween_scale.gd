@tool
class_name HenActionTweenScale extends HenActionTweenBase


# animates scale toward To over Duration seconds. fire-and-forget, so it runs
# on enter, not per-frame.


func get_id() -> StringName:
	return &'tween_scale'


func get_description() -> String:
	return 'Smoothly scales the node to a target size over time. Wire Finished and the flow moves on by itself when it ends, with no timer of your own. On enter it plays once; on update or physics it starts again as soon as the last one ended, so it keeps repeating while the state runs.'


func get_display_name() -> String:
	return 'Tween Scale'


func get_icon() -> String:
	return 'scaling'


func get_target_classes() -> Array[StringName]:
	return [&'Node2D']


func get_inputs() -> Array[Dictionary]:
	return [
		node_ref_input('The node to resize. Leave it empty to resize this node.'),
		{
			name = 'To',
			type = 'Vector2',
			id = &'to',
				doc = 'The target scale, where 1, 1 is the normal size.',
			default_value = Vector2.ONE
		},
		{
			name = 'Duration',
			type = 'float',
			id = &'duration',
				doc = 'How long the scaling takes, in seconds.',
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
	return start_tween('tween_property({{ref}}, "scale", {{to}}, {{duration}})')
