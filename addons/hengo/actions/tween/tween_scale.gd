@tool
class_name HenActionTweenScale extends HenScriptMacroBase


# animates scale toward To over Duration seconds. fire-and-forget, so it runs
# on enter, not per-frame.


func get_id() -> StringName:
	return &'tween_scale'


func get_display_name() -> String:
	return 'Tween Scale'


func get_icon() -> String:
	return 'scaling'


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
			default_value = Vector2.ONE
		},
		{
			name = 'Duration',
			type = 'float',
			id = &'duration',
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
	return '_ref.create_tween().tween_property(_ref, "scale", {{to}}, {{duration}})'
