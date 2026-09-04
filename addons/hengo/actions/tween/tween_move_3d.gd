@tool
class_name HenActionTweenMove3D extends HenActionTweenBase


func get_id() -> StringName:
	return &'tween_move_3d'


func get_description() -> String:
	return 'Smoothly moves the node to a target position over time. Wire Finished and the flow moves on by itself when it ends, with no timer of your own. On enter it plays once; on update or physics it starts again as soon as the last one ended, so it keeps repeating while the state runs.'


func get_display_name() -> String:
	return 'Tween Move'


func get_icon() -> String:
	return 'move'


func get_target_classes() -> Array[StringName]:
	return [&'Node3D']


func get_inputs() -> Array[Dictionary]:
	return [
		node_ref_input('The node to move. Leave it empty to move this node.'),
		{
			name = 'To',
			type = 'Vector3',
			id = &'to',
			doc = 'The position to move to.',
			default_value = Vector3.ZERO
		},
		{
			name = 'Duration',
			type = 'float',
			id = &'duration',
			doc = 'How long the movement takes, in seconds.',
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
	return start_tween('tween_property({{ref}}, "position", {{to}}, {{duration}})')
