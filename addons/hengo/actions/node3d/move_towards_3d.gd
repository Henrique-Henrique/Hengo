@tool
class_name HenActionMoveTowards3D extends HenScriptMacroBase


# steps the owner toward Target at Speed units per second, stopping on arrival.
# the body needs delta, so enter and exit are not offered.


func get_id() -> StringName:
	return &'move_towards_3d'


func get_display_name() -> String:
	return 'Move Towards'


func get_icon() -> String:
	return 'navigation'


func get_target_classes() -> Array[StringName]:
	return [&'Node3D']


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Target',
			type = 'Vector3',
			id = &'target',
			default_value = Vector3.ZERO
		},
		{
			name = 'Speed',
			type = 'float',
			id = &'speed',
			default_value = 5.0
		}
	]


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'}
	]


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


func _body() -> String:
	return '_ref.position = _ref.position.move_toward({{target}}, {{speed}} * delta)'
