@tool
class_name HenActionJump3D extends HenScriptMacroBase


# throws the body upwards, but only when it is standing on something — jumping in
# mid air is almost never what is wanted, and checking it here keeps the state
# machine simple.


func get_id() -> StringName:
	return &'jump_3d'


func get_description() -> String:
	return 'Pushes the body upward, but only when it is standing on the floor. Sets the upward velocity to the given force.'


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
		node_ref_input('The body to jump. Leave it empty to jump this node.'),
		{
			name = 'Force',
			type = 'float',
			id = &'force',
				doc = 'How hard the jump is, in units per second.',
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
	return 'if {{ref}}.is_on_floor():\n\t_ref.velocity.y = {{force}}'
