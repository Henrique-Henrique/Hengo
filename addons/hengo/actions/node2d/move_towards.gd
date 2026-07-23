@tool
class_name HenActionMoveTowards extends HenScriptMacroBase


# steps the owner toward Target at Speed pixels per second, stopping on arrival.
# the body needs delta, so only the update phase is offered.


func get_id() -> StringName:
	return &'move_towards'


func get_display_name() -> String:
	return 'Move Towards'


func get_icon() -> String:
	return 'navigation'


func get_target_classes() -> Array[StringName]:
	return [&'Node2D']


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Target',
			type = 'Vector2',
			id = &'target',
			default_value = Vector2.ZERO
		},
		{
			name = 'Speed',
			type = 'float',
			id = &'speed',
			default_value = 200.0
		}
	]


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Update', id = &'update'}
	]


func get_flow_update() -> String:
	return '_ref.position = _ref.position.move_toward({{target}}, {{speed}} * delta)'
