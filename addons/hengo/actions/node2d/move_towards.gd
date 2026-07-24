@tool
class_name HenActionMoveTowards extends HenScriptMacroBase


# steps the owner toward Target at Speed pixels per second, stopping on arrival.
# the body needs delta, so only the update phase is offered.


func get_id() -> StringName:
	return &'move_towards'


func get_description() -> String:
	return 'Moves the node a step toward a target each frame, stopping once it arrives.'


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
			doc = 'The point in global space to move toward.',
			default_value = Vector2.ZERO
		},
		{
			name = 'Speed',
			type = 'float',
			id = &'speed',
			doc = 'How fast to move, in pixels per second.',
			default_value = 200.0
		}
	]


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Update', id = &'update'}
	]


func get_flow_update() -> String:
	return '_ref.position = _ref.position.move_toward({{target}}, {{speed}} * delta)'
