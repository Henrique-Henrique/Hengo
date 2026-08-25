@tool
class_name HenActionIsOnFloor extends HenScriptMacroBase


# branches on the floor contact of the last Move And Slide.


func get_id() -> StringName:
	return &'is_on_floor'


func get_description() -> String:
	return 'Checks whether the body is standing on the floor and branches on the result. It uses the floor contact from the last Move And Slide.'


func get_display_name() -> String:
	return 'Is On Floor'


func get_icon() -> String:
	return 'chevrons-right'


func get_target_classes() -> Array[StringName]:
	return [&'CharacterBody2D']


func get_default_phase() -> StringName:
	return &'physics'


func get_inputs() -> Array[Dictionary]:
	return [
		node_ref_input('The body to check. Leave it empty to check this node.'),
	]

func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'}
	]


func get_flow_outputs() -> Array[Dictionary]:
	return [
		{name = 'True', id = &'true', doc = 'Where to go when the body is on the floor.'},
		{name = 'False', id = &'false', doc = 'Where to go when the body is in the air.'}
	]


func get_flow_enter() -> String:
	return _body()


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


func _body() -> String:
	return 'if {{ref}}.is_on_floor():\n\t{{true}}\nelse:\n\t{{false}}'
