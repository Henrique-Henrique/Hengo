@tool
class_name HenActionCheckTouch extends HenScriptMacroBase


# branches on a finger touching or leaving the screen, and can keep where it
# happened. on desktop the engine turns touches into mouse events by default, so
# a single finger already reaches the Mouse Position source; this is for the
# touch event itself.


func get_id() -> StringName:
	return &'check_touch'


func get_description() -> String:
	return 'Checks the touch screen and branches when a finger touches or leaves it. Also stores where the touch happened.'


func get_display_name() -> String:
	return 'Check Touch'


func get_icon() -> String:
	return 'hand'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'When',
			type = 'String',
			id = &'when',
			doc = 'Whether to react as the finger touches down or as it lifts off.',
			raw = true,
			options = ['Pressed', 'Released'],
			default_value = 'Pressed'
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Position', type = 'Vector2', id = &'position', branch = &'true', doc = 'Where to store the screen point of the touch.'}
	]


func get_output_position() -> String:
	return '_ref.touch_at_{{VCNODE_ID}}'


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'}
	]


func get_flow_outputs() -> Array[Dictionary]:
	return [
		{name = 'True', id = &'true', doc = 'Where to go when the touch happens.'},
		{name = 'False', id = &'false', doc = 'Where to go when it does not.'}
	]


func get_script_scope() -> String:
	return 'var touch_on_{{VCNODE_ID}}: bool = false\n' \
		+ 'var touch_hit_{{VCNODE_ID}}: bool = false\n' \
		+ 'var touch_at_{{VCNODE_ID}}: Vector2 = Vector2.ZERO'


func get_function_overrides() -> Array[Dictionary]:
	return [
		{
			name = '_input',
			params = [ {name = 'event', type = 'InputEvent'} ],
			body = 'if touch_on_{{VCNODE_ID}} and event is InputEventScreenTouch:\n' \
				+ '\tif ' + _moment_test() + ':\n' \
				+ '\t\ttouch_at_{{VCNODE_ID}} = event.position\n' \
				+ '\t\ttouch_hit_{{VCNODE_ID}} = true'
		}
	]


func get_flow_reset() -> String:
	return '_ref.touch_on_{{VCNODE_ID}} = true\n_ref.touch_hit_{{VCNODE_ID}} = false'


func get_flow_teardown() -> String:
	return '_ref.touch_on_{{VCNODE_ID}} = false'


func get_flow_enter() -> String:
	return _body()


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


func _moment_test() -> String:
	return 'not event.pressed' if str(value_of(&'when', 'Pressed')) == 'Released' else 'event.pressed'


func _body() -> String:
	return 'if _ref.touch_hit_{{VCNODE_ID}}:\n' \
		+ '\t_ref.touch_hit_{{VCNODE_ID}} = false\n' \
		+ '\t{{out:position}}\n' \
		+ '\t{{true}}\n' \
		+ 'else:\n' \
		+ '\t{{false}}'
