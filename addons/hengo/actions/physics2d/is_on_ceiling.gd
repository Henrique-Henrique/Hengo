@tool
class_name HenActionIsOnCeiling extends HenScriptMacroBase


# branches on the ceiling contact of the last Move And Slide.


func get_id() -> StringName:
	return &'is_on_ceiling'


func get_description() -> String:
	return 'Checks whether the body hit a ceiling and branches on the result. It uses the ceiling contact from the last Move And Slide.'


func get_display_name() -> String:
	return 'Is On Ceiling'


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
		{name = 'True', id = &'true', doc = 'Where to go when the body touches a ceiling.'},
		{name = 'False', id = &'false', doc = 'Where to go when the body touches no ceiling.'}
	]


func get_flow_enter() -> String:
	return _body()


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


func _body() -> String:
	return 'if {{ref}}.is_on_ceiling():\n\t{{true}}\nelse:\n\t{{false}}'
