@tool
class_name HenActionMouseButton extends HenScriptMacroBase


# branches on a mouse button. it reads the button directly, so nothing has to be
# declared in the project input map.
# Held is a plain check every frame; Clicked, Released and Double Click are
# moments, so they come from the mouse event itself.


func get_id() -> StringName:
	return &'mouse_button'


func get_description() -> String:
	return 'Checks a mouse button and branches on its state. Reads the button directly, so nothing has to be set up in the input map. Picking a wheel direction is how scrolling is read, such as swapping weapons.'


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
			doc = 'Which mouse button to watch.',
			raw = true,
			options = [
				'MOUSE_BUTTON_LEFT',
				'MOUSE_BUTTON_RIGHT',
				'MOUSE_BUTTON_MIDDLE',
				'MOUSE_BUTTON_WHEEL_UP',
				'MOUSE_BUTTON_WHEEL_DOWN'
			],
			default_value = 'MOUSE_BUTTON_LEFT'
		},
		{
			name = 'When',
			type = 'String',
			id = &'when',
			doc = 'Whether to react continuously while the button is down or only at the moment it changes. A wheel is always a moment, so it ignores Held.',
			raw = true,
			options = ['Held', 'Clicked', 'Released', 'Double Click'],
			default_value = 'Held'
		}
	]


# a wheel turn arrives as a press that is never released, so those two moments
# would wait forever
func get_validation_error() -> String:
	if _is_wheel() and str(value_of(&'when', 'Held')) in ['Released', 'Double Click']:
		return 'the mouse wheel only reports a turn, so it has no Released and no Double Click'

	return ''


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'}
	]


func get_flow_outputs() -> Array[Dictionary]:
	return [
		{name = 'True', id = &'true', doc = 'Where to go when the button check passes.'},
		{name = 'False', id = &'false', doc = 'Where to go when it does not.'}
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
	return str(value_of(&'when', 'Held')) == 'Held' and not _is_wheel()


# is_mouse_button_pressed never reports a wheel, which only exists as an event
func _is_wheel() -> bool:
	return str(value_of(&'button', 'MOUSE_BUTTON_LEFT')).begins_with('MOUSE_BUTTON_WHEEL')


# a double click arrives as a second press flagged as such, so a plain click has
# to rule it out or both would fire
func _moment_test() -> String:
	if _is_wheel():
		return 'event.pressed'

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
