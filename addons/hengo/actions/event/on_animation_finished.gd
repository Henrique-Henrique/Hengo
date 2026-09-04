@tool
class_name HenActionOnAnimationFinished extends HenActionSignalBase


# fires when an AnimationPlayer reaches the end of a clip, the usual way to hold
# a state until the animation is over.


func get_id() -> StringName:
	return &'on_animation_finished'


func get_description() -> String:
	return 'Runs when an AnimationPlayer finishes playing its current clip.'


func get_display_name() -> String:
	return 'On Animation Finished'


func get_icon() -> String:
	return 'film'


func get_inputs() -> Array[Dictionary]:
	return [_emitter_input(), _store_input('Store Name')]


func get_signal_code() -> String:
	return "'animation_finished'"


func get_arg_count() -> int:
	return 1
