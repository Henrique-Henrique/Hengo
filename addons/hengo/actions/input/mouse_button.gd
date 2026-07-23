@tool
class_name HenActionMouseButton extends HenScriptMacroBase


# branches on a mouse button. it reads the button directly, so nothing has to be
# declared in the project input map.
# Held is a plain check every frame; Clicked, Released and Double Click are
# moments, so they come from the mouse event itself.


func get_id() -> StringName:
	return &'mouse_button'


func get_display_name() -> String:
	return 'Check Mouse Button'


func get_icon() -> String:
	return 'mouse-pointer-click'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Button',
			type = 'String',
			id = &'button',
			raw = true,
			options = ['MOUSE_BUTTON_LEFT', 'MOUSE_BUTTON_RIGHT', 'MOUSE_BUTTON_MIDDLE'],
			default_value = 'MOUSE_BUTTON_LEFT'
		},
		{
			name = 'When',
			type = 'String',
			id = &'when',
			raw = true,
			options = ['Held', 'Clicked', 'Released', 'Double Click'],
			default_value = 'Held'
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
		{name = 'True', id = &'true'},
		{name = 'False', id = &'false'}
	]


# a moment has to be caught when it happens, so it needs a flag the state arms.
# Held reads the button directly and declares nothing
func get_script_scope() -> String:
	if _is_held():
		return ''

	return 'var click_on_{{VCNODE_ID}}: bool = false\nvar clicked_{{VCNODE_ID}}: bool = false'


func get_function_overrides() -> Array[Dictionary]:
	if _is_held():
		return []

	return [
		{
			name = '_input',
			params = [ {name = 'event', type = 'InputEvent'} ],
			# the button is read from the action instead of {{button}}: an override
			# body never goes through the input substitution
			body = 'if click_on_{{VCNODE_ID}} and event is InputEventMouseButton and event.button_index == ' + str(value_of(&'button', 'MOUSE_BUTTON_LEFT')) + ':\n' \
				+ '\tif ' + _moment_test() + ':\n' \
				+ '\t\tclicked_{{VCNODE_ID}} = true'
		}
	]


func get_flow_reset() -> String:
	if _is_held():
		return ''

	return '_ref.click_on_{{VCNODE_ID}} = true\n_ref.clicked_{{VCNODE_ID}} = false'


func get_flow_teardown() -> String:
	return '' if _is_held() else '_ref.click_on_{{VCNODE_ID}} = false'


func get_flow_enter() -> String:
	return _body()


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


func _is_held() -> bool:
	return str(value_of(&'when', 'Held')) == 'Held'


# a double click arrives as a second press flagged as such, so a plain click has
# to rule it out or both would fire
func _moment_test() -> String:
	match str(value_of(&'when', 'Held')):
		'Released':
			return 'not event.pressed'
		'Double Click':
			return 'event.pressed and event.double_click'

	return 'event.pressed and not event.double_click'


func _body() -> String:
	if _is_held():
		return 'if Input.is_mouse_button_pressed({{button}}):\n\t{{true}}\nelse:\n\t{{false}}'

	return 'if _ref.clicked_{{VCNODE_ID}}:\n' \
		+ '\t_ref.clicked_{{VCNODE_ID}} = false\n' \
		+ '\t{{true}}\n' \
		+ 'else:\n' \
		+ '\t{{false}}'
