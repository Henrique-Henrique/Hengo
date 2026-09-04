@tool
class_name HenActionCheckKey extends HenScriptMacroBase


# branches on a keyboard key, without declaring anything in the project input map.
# Held is a plain check every frame; Pressed and Released are moments, so they
# come from the key event itself. repeats from holding the key are ignored.


const KEYS: Array[String] = [
	'KEY_SPACE', 'KEY_ENTER', 'KEY_ESCAPE', 'KEY_TAB', 'KEY_BACKSPACE',
	'KEY_SHIFT', 'KEY_CTRL', 'KEY_ALT',
	'KEY_LEFT', 'KEY_RIGHT', 'KEY_UP', 'KEY_DOWN',
	'KEY_A', 'KEY_B', 'KEY_C', 'KEY_D', 'KEY_E', 'KEY_F', 'KEY_G', 'KEY_H',
	'KEY_I', 'KEY_J', 'KEY_K', 'KEY_L', 'KEY_M', 'KEY_N', 'KEY_O', 'KEY_P',
	'KEY_Q', 'KEY_R', 'KEY_S', 'KEY_T', 'KEY_U', 'KEY_V', 'KEY_W', 'KEY_X',
	'KEY_Y', 'KEY_Z',
	'KEY_0', 'KEY_1', 'KEY_2', 'KEY_3', 'KEY_4',
	'KEY_5', 'KEY_6', 'KEY_7', 'KEY_8', 'KEY_9',
	'KEY_F1', 'KEY_F2', 'KEY_F3', 'KEY_F4', 'KEY_F5'
]


func get_id() -> StringName:
	return &'check_key'


func get_description() -> String:
	return 'Checks a keyboard key and branches on whether it is down. Reads the key directly, so nothing has to be set up in the input map.'


func get_display_name() -> String:
	return 'Check Key'


func get_icon() -> String:
	return 'keyboard'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Key',
			type = 'String',
			id = &'key',
			doc = 'Which keyboard key to watch.',
			raw = true,
			options = KEYS,
			default_value = 'KEY_SPACE'
		},
		{
			name = 'When',
			type = 'String',
			id = &'when',
			doc = 'Whether to react continuously while the key is down or only at the moment it changes.',
			raw = true,
			options = ['Held', 'Pressed', 'Released'],
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
		{name = 'True', id = &'true', doc = 'Where to go when the key check passes.'},
		{name = 'False', id = &'false', doc = 'Where to go when it does not.'}
	]


func get_script_scope() -> String:
	if _is_held():
		return ''

	return 'var key_on_{{VCNODE_ID}}: bool = false\nvar key_hit_{{VCNODE_ID}}: bool = false'


func get_function_overrides() -> Array[Dictionary]:
	if _is_held():
		return []

	return [
		{
			name = '_input',
			params = [ {name = 'event', type = 'InputEvent'} ],
			# the key is read from the action instead of {{key}}: an override body
			# never goes through the input substitution
			body = 'if key_on_{{VCNODE_ID}} and event is InputEventKey and event.keycode == ' + str(value_of(&'key', 'KEY_SPACE')) + ' and not event.echo:\n' \
				+ '\tif ' + _moment_test() + ':\n' \
				+ '\t\tkey_hit_{{VCNODE_ID}} = true'
		}
	]


func get_flow_reset() -> String:
	if _is_held():
		return ''

	return '_ref.key_on_{{VCNODE_ID}} = true\n_ref.key_hit_{{VCNODE_ID}} = false'


func get_flow_teardown() -> String:
	return '' if _is_held() else '_ref.key_on_{{VCNODE_ID}} = false'


func get_flow_enter() -> String:
	return _body()


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


func _is_held() -> bool:
	return str(value_of(&'when', 'Held')) == 'Held'


func _moment_test() -> String:
	return 'not event.pressed' if str(value_of(&'when', 'Held')) == 'Released' else 'event.pressed'


func _body() -> String:
	if _is_held():
		return 'if Input.is_key_pressed({{key}}):\n\t{{true}}\nelse:\n\t{{false}}'

	return 'if _ref.key_hit_{{VCNODE_ID}}:\n' \
		+ '\t_ref.key_hit_{{VCNODE_ID}} = false\n' \
		+ '\t{{true}}\n' \
		+ 'else:\n' \
		+ '\t{{false}}'
