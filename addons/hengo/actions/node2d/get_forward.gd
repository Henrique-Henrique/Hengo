@tool
class_name HenActionGetForward extends HenScriptMacroBase


# writes the unit direction the node points at into Store, in global space. feed
# it to thrust or to spawn something ahead of the node.


func get_id() -> StringName:
	return &'get_forward'


func get_description() -> String:
	return 'Reads the direction the node is facing and stores it, as a unit vector in global space. Useful to move or shoot straight ahead.'


func get_display_name() -> String:
	return 'Get Facing Direction'


func get_icon() -> String:
	return 'navigation'


func get_target_classes() -> Array[StringName]:
	return [&'Node2D']


func get_default_phase() -> StringName:
	return &'update'


func get_inputs() -> Array[Dictionary]:
	return [
		node_ref_input('The node to read the facing of. Leave it empty to read this node.')
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Forward', type = 'Vector2', id = &'forward', doc = 'Where to store the facing direction, as a unit vector.'}
	]


# a Node2D with no rotation faces right, which is where its sprite is drawn facing
func get_output_forward() -> String:
	return 'Vector2.RIGHT.rotated({{ref}}.global_rotation)'


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'},
		{name = 'Exit', id = &'exit'}
	]


func get_flow_enter() -> String:
	return _body()


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


func get_flow_exit() -> String:
	return _body()


func _body() -> String:
	return '{{out:forward}}'
