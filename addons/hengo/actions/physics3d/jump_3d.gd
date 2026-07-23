@tool
class_name HenActionJump3D extends HenScriptMacroBase


# throws the body upwards, but only when it is standing on something — jumping in
# mid air is almost never what is wanted, and checking it here keeps the state
# machine simple.


func get_id() -> StringName:
	return &'jump_3d'


func get_display_name() -> String:
	return 'Jump'


func get_icon() -> String:
	return 'move-up'


func get_target_classes() -> Array[StringName]:
	return [&'CharacterBody3D']


func get_default_phase() -> StringName:
	return &'enter'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Force',
			type = 'float',
			id = &'force',
			default_value = 8.0
		}
	]


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'}
	]


func get_flow_enter() -> String:
	return _body()


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


func _body() -> String:
	return 'if _ref.is_on_floor():\n\t_ref.velocity.y = {{force}}'
