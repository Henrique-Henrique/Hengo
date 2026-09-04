@tool
class_name HenActionOnButtonPressed extends HenActionSignalBase


# fires when the Emitter button is clicked or activated by the keyboard.


func get_id() -> StringName:
	return &'on_button_pressed'


func get_description() -> String:
	return 'Runs when a Button is pressed by mouse or keyboard.'


func get_display_name() -> String:
	return 'On Button Pressed'


func get_icon() -> String:
	return 'square-mouse-pointer'


func get_inputs() -> Array[Dictionary]:
	return [_emitter_input()]


func get_signal_code() -> String:
	return "'pressed'"
