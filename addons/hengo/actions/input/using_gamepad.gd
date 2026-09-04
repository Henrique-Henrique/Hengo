@tool
class_name HenActionUsingGamepad extends HenScriptMacroBase


# the answer is the kind of the last event that arrived, since nothing in the
# engine reports which device a player is holding right now.


func get_id() -> StringName:
	return &'using_gamepad'


func get_description() -> String:
	return 'Branches on whether the last input came from a gamepad or from the keyboard and mouse. It is what picks the right button icon to show, so a prompt reads "Press A" on a controller and "Press E" otherwise.'


func get_display_name() -> String:
	return 'Using Gamepad'


func get_icon() -> String:
	return 'gamepad-2'


func get_default_phase() -> StringName:
	return &'update'


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'}
	]


func get_flow_outputs() -> Array[Dictionary]:
	return [
		{name = 'Gamepad', id = &'gamepad', doc = 'Where to go while the last input came from a gamepad.'},
		{name = 'Keyboard', id = &'keyboard', doc = 'Where to go while the last input came from the keyboard, the mouse or a touch.'}
	]


# _input runs on the node, so the flag lives next to the variables and not in the
# state class
func get_script_scope() -> String:
	return 'var gamepad_{{VCNODE_ID}}: bool = false'


func get_function_overrides() -> Array[Dictionary]:
	return [
		{
			name = '_input',
			params = [ {name = 'event', type = 'InputEvent'} ],
			# a resting stick keeps sending motion, so only a real push counts
			body = 'if event is InputEventJoypadButton or (event is InputEventJoypadMotion and absf((event as InputEventJoypadMotion).axis_value) > 0.5):\n' \
				+ '\tgamepad_{{VCNODE_ID}} = true\n' \
				+ 'elif event is InputEventKey or event is InputEventMouseButton or event is InputEventScreenTouch:\n' \
				+ '\tgamepad_{{VCNODE_ID}} = false'
		}
	]


func get_flow_enter() -> String:
	return _body()


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


func _body() -> String:
	return 'if _ref.gamepad_{{VCNODE_ID}}:\n' \
		+ '\t{{gamepad}}\n' \
		+ 'else:\n' \
		+ '\t{{keyboard}}'
