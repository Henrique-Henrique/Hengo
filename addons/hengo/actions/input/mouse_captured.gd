@tool
class_name HenActionMouseCaptured extends HenScriptMacroBase


func get_id() -> StringName:
	return &'mouse_captured'


func get_description() -> String:
	return 'Branches on whether the cursor is locked to the window for looking around. It is what keeps a pause screen from turning the camera and firing the gun while the menu is open.'


func get_display_name() -> String:
	return 'Mouse Captured'


func get_icon() -> String:
	return 'mouse-pointer-2'


func get_default_phase() -> StringName:
	return &'physics'


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'}
	]


func get_flow_outputs() -> Array[Dictionary]:
	return [
		{name = 'Captured', id = &'captured', doc = 'Where to go while the cursor is locked, which is when the game is being played.'},
		{name = 'Free', id = &'free', doc = 'Where to go while the cursor is loose on screen.'}
	]


func get_flow_enter() -> String:
	return _body()


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


func _body() -> String:
	return 'if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:\n' \
		+ '\t{{captured}}\n' \
		+ 'else:\n' \
		+ '\t{{free}}'
