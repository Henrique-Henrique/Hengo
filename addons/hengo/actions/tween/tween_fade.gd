@tool
class_name HenActionTweenFade extends HenScriptMacroBase


# animates modulate alpha toward To Alpha over Duration seconds. fire-and-forget,
# so it runs on enter, not per-frame.


func get_id() -> StringName:
	return &'tween_fade'


func get_display_name() -> String:
	return 'Tween Fade'


func get_icon() -> String:
	return 'eye'


func get_target_classes() -> Array[StringName]:
	return [&'CanvasItem']


func get_default_phase() -> StringName:
	return &'enter'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'To Alpha',
			type = 'float',
			id = &'to',
			default_value = 1.0
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
	return '_ref.create_tween().tween_property(_ref, "modulate:a", {{to}}, {{duration}})'
