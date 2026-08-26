@tool
class_name HenActionInputAction extends HenScriptMacroBase


# branches on an input action. Mode picks between held, pressed this frame and
# released this frame.


func get_id() -> StringName:
	return &'input_action'


func get_description() -> String:
	return 'Checks an input action and branches on whether it is active. Mode chooses between held, pressed this frame, and released this frame.'


func get_display_name() -> String:
	return 'Check Action'


func get_icon() -> String:
	return 'gamepad-2'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Action',
			type = 'StringName',
			id = &'action',
			picker = 'input_action',
			doc = 'The input action to check, as named in the input map.',
			default_value = 'ui_accept'
		},
		{
			name = 'Mode',
			type = 'String',
			id = &'mode',
			doc = 'How to test the action, from held down to the single frame it changes.',
			raw = true,
			options = ['is_action_pressed', 'is_action_just_pressed', 'is_action_just_released'],
			default_value = 'is_action_pressed'
		}
	]


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'}
	]


func get_flow_outputs() -> Array[Dictionary]:
	return [
		{name = 'True', id = &'true', doc = 'Where to go when the action check passes.'},
		{name = 'False', id = &'false', doc = 'Where to go when it does not.'}
	]


func get_flow_enter() -> String:
	return _body()


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


func _body() -> String:
	return 'if Input.{{mode}}({{action}}):\n\t{{true}}\nelse:\n\t{{false}}'
