@tool
class_name HenActionOnTimerTimeout extends HenActionSignalBase


# fires when the Emitter Timer node runs out. the Timer keeps its own wait time
# and autostart, this action only reacts to it.


func get_id() -> StringName:
	return &'on_timer_timeout'


func get_description() -> String:
	return 'Runs when a Timer node reaches the end of its countdown.'


func get_display_name() -> String:
	return 'On Timer Timeout'


func get_icon() -> String:
	return 'timer'


func get_inputs() -> Array[Dictionary]:
	return [_emitter_input()]


func get_signal_code() -> String:
	return "'timeout'"
