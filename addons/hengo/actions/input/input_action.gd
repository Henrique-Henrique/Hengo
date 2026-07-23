@tool
class_name HenActionInputAction extends HenScriptMacroBase


# branches on an input action. Mode picks between held, pressed this frame and
# released this frame.


func get_id() -> StringName:
	return &'input_action'


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
			default_value = 'ui_accept'
		},
		{
			name = 'Mode',
			type = 'String',
			id = &'mode',
			raw = true,
			options = ['is_action_pressed', 'is_action_just_pressed', 'is_action_just_released'],
			default_value = 'is_action_pressed'
		}
	]


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'}
	]


func get_flow_outputs() -> Array[Dictionary]:
	return [
		{name = 'True', id = &'true'},
		{name = 'False', id = &'false'}
	]


func get_flow_enter() -> String:
	return _body()


func get_flow_update() -> String:
	return _body()


func _body() -> String:
	return 'if Input.{{mode}}({{action}}):\n\t{{true}}\nelse:\n\t{{false}}'
