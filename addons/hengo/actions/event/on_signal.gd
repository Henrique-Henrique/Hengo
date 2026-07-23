@tool
class_name HenActionOnSignal extends HenActionSignalBase


# listens to any signal of any node while the state runs. the connection is made
# on entry and dropped on exit, so it never fires from the wrong state.
# the presets of this folder are this action with the name already filled in.


func get_id() -> StringName:
	return &'on_signal'


func get_display_name() -> String:
	return 'On Signal'


func get_icon() -> String:
	return 'radio-tower'


func get_inputs() -> Array[Dictionary]:
	return [
		_emitter_input(),
		{
			name = 'Signal',
			type = 'String',
			id = &'signal_name',
			default_value = 'body_entered'
		},
		{
			name = 'Sends',
			type = 'String',
			id = &'args',
			raw = true,
			options = ['nothing', 'one value'],
			default_value = 'nothing'
		},
		_store_input('Store Value')
	]


# the signal name comes from the input, so it is a placeholder resolved per action
func get_signal_code() -> String:
	return '{{signal_name}}'


func get_arg_count() -> int:
	return 1 if str(value_of(&'args', 'nothing')) == 'one value' else 0


# a blank name would emit connect("", cb): compiles fine and never fires
func get_validation_error() -> String:
	return 'the signal name is empty' if str(value_of(&'signal_name', '')).strip_edges().is_empty() else ''
