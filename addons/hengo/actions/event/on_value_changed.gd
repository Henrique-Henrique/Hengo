@tool
class_name HenActionOnValueChanged extends HenActionSignalBase


# fires when the Emitter Range moves (Slider, ProgressBar, SpinBox). Store Value
# receives the new number.


func get_id() -> StringName:
	return &'on_value_changed'


func get_description() -> String:
	return 'Runs when a Range node such as a Slider or SpinBox changes. The new value is sent to Store Value.'


func get_display_name() -> String:
	return 'On Value Changed'


func get_icon() -> String:
	return 'sliders-horizontal'


func get_inputs() -> Array[Dictionary]:
	return [_emitter_input(), _store_input('Store Value')]


func get_signal_code() -> String:
	return "'value_changed'"


func get_arg_count() -> int:
	return 1
