@tool
class_name HenActionOnAreaEntered extends HenActionSignalBase


# fires when another Area2D overlaps the Emitter. use it for hitboxes, where both
# sides are areas instead of bodies.


func get_id() -> StringName:
	return &'on_area_entered'


func get_description() -> String:
	return 'Runs when another Area2D overlaps this Area2D.'


func get_display_name() -> String:
	return 'On Area Entered'


func get_icon() -> String:
	return 'scan'


func get_inputs() -> Array[Dictionary]:
	return [_emitter_input(), _store_input('Store Area')]


func get_signal_code() -> String:
	return "'area_entered'"


func get_arg_count() -> int:
	return 1
