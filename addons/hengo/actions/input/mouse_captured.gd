@tool
class_name HenActionMouseCaptured extends HenScriptMacroBase


func get_id() -> StringName:
	return &'mouse_captured'


func get_description() -> String:
	return 'Answers whether the cursor is locked to the window for looking around, which is what keeps a pause screen from turning the camera. It can branch on the answer or hand it to a field that takes a yes or no.'


func get_display_name() -> String:
	return 'Mouse Captured'


func get_icon() -> String:
	return 'mouse-pointer-2'


func get_default_phase() -> StringName:
	return &'physics'


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Yes', type = 'bool', id = &'result', doc = 'Where to store whether the cursor is locked to the window.'}
	]


func get_output_result() -> String:
	return 'Input.mouse_mode == Input.MOUSE_MODE_CAPTURED'


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'}
	]


func get_flow_outputs() -> Array[Dictionary]:
	return [
		{name = 'Captured', id = &'captured', optional = true, doc = 'Where to go while the cursor is locked, which is when the game is being played.'},
		{name = 'Free', id = &'free', optional = true, doc = 'Where to go while the cursor is loose on screen.'}
	]


func get_flow_enter() -> String:
	return _body()


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


# with no branch wired it is only the answer, which is what lets it be read from
# inside another action's field
func _body() -> String:
	if not any_flow_connected():
		return '{{out:result}}'

	return '{{out:result}}\n' \
		+ 'if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:\n' \
		+ '\t{{captured}}\n' \
		+ 'else:\n' \
		+ '\t{{free}}'
