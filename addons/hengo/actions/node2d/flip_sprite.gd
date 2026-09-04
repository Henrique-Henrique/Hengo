@tool
class_name HenActionFlipSprite extends HenScriptMacroBase


# flips a bound Sprite2D or AnimatedSprite2D left to right. Target is bound by
# variable or node path; the assignment is duck-typed.


func get_id() -> StringName:
	return &'flip_sprite'


func get_description() -> String:
	return 'Flips a Sprite2D or AnimatedSprite2D left to right, the usual way to face a character the way it moves.'


func get_display_name() -> String:
	return 'Flip Sprite'


func get_icon() -> String:
	return 'flip-horizontal-2'


func get_default_phase() -> StringName:
	return &'update'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Target',
			type = 'Node2D',
			id = &'target',
			doc = 'The node to flip. Leave it empty to flip this node.',
			bind_only = true,
			optional = true,
			default_value = null
		},
		{
			name = 'Flipped',
			type = 'bool',
			id = &'flipped',
			doc = 'True to face left, false to face right.',
			default_value = false
		}
	]


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'},
		{name = 'Exit', id = &'exit'}
	]


func get_flow_enter() -> String:
	return _body()


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


func get_flow_exit() -> String:
	return _body()


func _body() -> String:
	return '{{target}}.flip_h = {{flipped}}'
