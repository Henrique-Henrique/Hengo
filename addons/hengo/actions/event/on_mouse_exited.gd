@tool
class_name HenActionOnMouseExited extends HenActionSignalBase


# fires when the mouse leaves the Emitter. the pair of On Mouse Entered, for
# clearing a hover highlight.


func get_id() -> StringName:
	return &'on_mouse_exited'


func get_description() -> String:
	return 'Runs when the mouse leaves a node, such as a Control or an Area with mouse detection on.'


func get_display_name() -> String:
	return 'On Mouse Exited'


func get_icon() -> String:
	return 'mouse-pointer'


func get_inputs() -> Array[Dictionary]:
	return [_emitter_input()]


func get_signal_code() -> String:
	return "'mouse_exited'"
