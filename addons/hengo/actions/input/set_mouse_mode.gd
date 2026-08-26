@tool
class_name HenActionSetMouseMode extends HenScriptMacroBase


# controls the mouse cursor. Captured hides it and locks it to the window, which
# is what a first person camera needs; Visible gives it back.


func get_id() -> StringName:
	return &'set_mouse_mode'


func get_description() -> String:
	return 'Sets how the mouse cursor behaves, such as capturing it for a first person camera or making it visible again.'


func get_display_name() -> String:
	return 'Set Mouse Mode'


func get_icon() -> String:
	return 'mouse-pointer'


func get_default_phase() -> StringName:
	return &'enter'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Mode',
			type = 'String',
			id = &'mode',
			doc = 'How the cursor should behave.',
			raw = true,
			options = ['MOUSE_MODE_VISIBLE', 'MOUSE_MODE_CAPTURED', 'MOUSE_MODE_HIDDEN', 'MOUSE_MODE_CONFINED'],
			default_value = 'MOUSE_MODE_CAPTURED'
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
	return 'Input.mouse_mode = Input.{{mode}}'
