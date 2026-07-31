@tool
class_name HenActionOnAreaExited extends HenActionSignalBase


# fires when another Area2D stops overlapping the Emitter. the pair of On Area
# Entered, for when a hitbox or trigger zone is left.


func get_id() -> StringName:
	return &'on_area_exited'


func get_description() -> String:
	return 'Runs when another Area2D stops overlapping this Area2D.'


func get_display_name() -> String:
	return 'On Area Exited'


func get_icon() -> String:
	return 'scan'


func get_inputs() -> Array[Dictionary]:
	return [_emitter_input(), _store_input('Store Area')]


func get_signal_code() -> String:
	return "'area_exited'"


func get_arg_count() -> int:
	return 1
