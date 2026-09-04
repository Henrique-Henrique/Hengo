@tool
class_name HenActionBufferPress extends HenScriptMacroBase


# the press is recorded by an _input hook on the node and only taken by the state
# body, so it survives the states that had no way to act on it.


func get_id() -> StringName:
	return &'buffer_press'


func get_description() -> String:
	return 'Remembers a press for a moment and takes Buffered on the first frame that reads it. With Remember = 0.15, pressing jump a tenth of a second before landing still jumps, instead of being lost because the ground was not there yet. The press is taken only once.'


func get_display_name() -> String:
	return 'Buffered Press'


func get_icon() -> String:
	return 'history'


func get_default_phase() -> StringName:
	return &'update'


func get_validation_error() -> String:
	# the name is pasted into the _input hook, which no substitution ever reaches
	if is_bound(&'action'):
		return 'the input action has to be typed here, it cannot come from a variable'

	return gate_validation_error()


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Action',
			type = 'StringName',
			id = &'action',
			doc = 'The input action to remember, as named in the input map.',
			picker = 'input_action',
			default_value = 'ui_accept'
		},
		{
			name = 'Remember',
			type = 'float',
			id = &'remember',
			doc = 'How long the press stays available after it happened, in seconds.',
			default_value = 0.15
		}
	]


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'}
	]


func get_flow_outputs() -> Array[Dictionary]:
	return [
		{name = 'Buffered', id = &'buffered', optional = true, doc = 'Where to go on the first frame that takes a press still inside the window.'},
		{name = 'Nothing', id = &'nothing', optional = true, doc = 'Where to go while no press is waiting to be taken.'}
	]


# the stamp lives on the node, so entering a state never wipes a press made just
# before it
func get_script_scope() -> String:
	return 'var press_at_{{VCNODE_ID}}: float = -99.0'


func get_function_overrides() -> Array[Dictionary]:
	return [
		{
			name = '_input',
			params = [ {name = 'event', type = 'InputEvent'} ],
			body = 'if event.is_action_pressed(&"' + str(value_of(&'action', 'ui_accept')) + '"):\n' \
				+ '\tpress_at_{{VCNODE_ID}} = Time.get_ticks_msec() / 1000.0'
		}
	]


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


func _body() -> String:
	return 'if Time.get_ticks_msec() / 1000.0 - _ref.press_at_{{VCNODE_ID}} <= {{remember}}:\n' \
		+ '\t_ref.press_at_{{VCNODE_ID}} = -99.0\n' \
		+ '\t{{buffered}}\n' \
		+ 'else:\n' \
		+ '\t{{nothing}}'
