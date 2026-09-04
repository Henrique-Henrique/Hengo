@tool
class_name HenActionTweenProperty extends HenActionTweenBase


func get_id() -> StringName:
	return &'tween_property'


func get_description() -> String:
	return 'Smoothly animates any property of a node toward a value over time. Wire Finished and the flow moves on by itself when it ends, with no timer of your own. On enter it plays once; on update or physics it starts again as soon as the last one ended, so it keeps repeating while the state runs.'


func get_display_name() -> String:
	return 'Tween Property'


func get_icon() -> String:
	return 'spline'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Target',
			type = 'Node',
			id = &'target',
			doc = 'The node whose property is animated. Leave it empty to animate this node.',
			bind_only = true,
			optional = true,
			default_value = null
		},
		{
			name = 'Property',
			type = 'String',
			id = &'property',
			doc = 'The name of the property to animate, such as position or modulate.',
			default_value = 'position'
		},
		{
			name = 'To',
			type = 'Variant',
			id = &'to',
			doc = 'The value the property ends at.',
			default_value = 0
		},
		{
			name = 'Duration',
			type = 'float',
			id = &'duration',
			doc = 'How long the animation takes, in seconds.',
			default_value = 0.5
		}
	]




func get_flow_enter() -> String:
	return _body()


func get_flow_update() -> String:
	return guard_per_frame(_body())


func get_flow_physics() -> String:
	return guard_per_frame(_body())


func _body() -> String:
	return start_tween('tween_property({{target}}, {{property}}, {{to}}, {{duration}})')
