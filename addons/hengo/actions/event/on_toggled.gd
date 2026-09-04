@tool
class_name HenActionOnToggled extends HenActionSignalBase


# fires when the Emitter toggle button flips (CheckBox, CheckButton). Store On
# receives true when it turned on, false when it turned off.


func get_id() -> StringName:
	return &'on_toggled'


func get_description() -> String:
	return 'Runs when a toggle button such as a CheckBox flips on or off. The new state is sent to Store On.'


func get_display_name() -> String:
	return 'On Toggled'


func get_icon() -> String:
	return 'toggle-right'


func get_inputs() -> Array[Dictionary]:
	return [_emitter_input(), _store_input('Store On')]


func get_signal_code() -> String:
	return "'toggled'"


func get_arg_count() -> int:
	return 1
