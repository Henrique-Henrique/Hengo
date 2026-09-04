@tool
class_name HenActionGetVelocity extends HenScriptMacroBase


# writes the current body velocity into Store, in pixels per second. read it to
# gate on speed or to feed a squash, a bob or a speed readout.


func get_id() -> StringName:
	return &'get_velocity'


func get_description() -> String:
	return 'Reads the current body velocity and stores it, in pixels per second. Useful to react to how fast the body is moving.'


func get_display_name() -> String:
	return 'Get Velocity'


func get_icon() -> String:
	return 'gauge'


func get_target_classes() -> Array[StringName]:
	return [&'CharacterBody2D']


func get_default_phase() -> StringName:
	return &'physics'


func get_inputs() -> Array[Dictionary]:
	return [
		node_ref_input('The body to read. Leave it empty to read this node.'),
	]

func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Velocity', type = 'Vector2', id = &'velocity', doc = 'Where to store the current velocity, in pixels per second.'}
	]


func get_output_velocity() -> String:
	return '{{ref}}.velocity'


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
	return '{{out:velocity}}'
