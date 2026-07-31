@tool
class_name HenActionOnTextSubmitted extends HenActionSignalBase


# fires when Enter is pressed in the Emitter LineEdit. Store Text receives what
# was typed.


func get_id() -> StringName:
	return &'on_text_submitted'


func get_description() -> String:
	return 'Runs when Enter is pressed in a LineEdit. The submitted text is sent to Store Text.'


func get_display_name() -> String:
	return 'On Text Submitted'


func get_icon() -> String:
	return 'corner-down-left'


func get_inputs() -> Array[Dictionary]:
	return [_emitter_input(), _store_input('Store Text')]


func get_signal_code() -> String:
	return "'text_submitted'"


func get_arg_count() -> int:
	return 1
