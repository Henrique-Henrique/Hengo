@tool
class_name HenActionOnBodyExited extends HenActionSignalBase


# fires when a physics body leaves the Emitter, an Area2D or a RigidBody2D.


func get_id() -> StringName:
	return &'on_body_exited'


func get_description() -> String:
	return 'Runs when a physics body leaves this Area2D or RigidBody2D.'


func get_display_name() -> String:
	return 'On Body Exited'


func get_icon() -> String:
	return 'door-open'


func get_inputs() -> Array[Dictionary]:
	return [_emitter_input(), _store_input('Store Body')]


func get_signal_code() -> String:
	return "'body_exited'"


func get_arg_count() -> int:
	return 1
