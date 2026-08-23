@tool
class_name HenActionTweenProperty extends HenActionTweenBase


func get_id() -> StringName:
	return &'tween_property'


func get_description() -> String:
	return 'Smoothly animates any property of a node toward a value over time. Runs once when the state starts. Wire Finished and the flow moves on by itself when it ends, with no timer of your own.'


func get_display_name() -> String:
	return 'Tween Property'


func get_icon() -> String:
	return 'spline'


func get_default_phase() -> StringName:
	return &'enter'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Target',
			type = 'Node',
			id = &'target',
			doc = 'The node that owns the property.',
			bind_only = true,
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


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'}
	]


func get_flow_enter() -> String:
	return _body()


func _body() -> String:
	return start_tween('tween_property({{target}}, {{property}}, {{to}}, {{duration}})')
