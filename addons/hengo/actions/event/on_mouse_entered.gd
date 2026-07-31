@tool
class_name HenActionOnMouseEntered extends HenActionSignalBase


# fires when the mouse moves over the Emitter. works on a Control node and on a
# CollisionObject with mouse detection on.


func get_id() -> StringName:
	return &'on_mouse_entered'


func get_description() -> String:
	return 'Runs when the mouse moves over a node, such as a Control or an Area with mouse detection on.'


func get_display_name() -> String:
	return 'On Mouse Entered'


func get_icon() -> String:
	return 'mouse-pointer'


func get_inputs() -> Array[Dictionary]:
	return [_emitter_input()]


func get_signal_code() -> String:
	return "'mouse_entered'"
