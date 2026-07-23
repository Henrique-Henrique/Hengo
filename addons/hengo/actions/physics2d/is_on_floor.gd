@tool
class_name HenActionIsOnFloor extends HenScriptMacroBase


# branches on the floor contact of the last Move And Slide.


func get_id() -> StringName:
	return &'is_on_floor'


func get_display_name() -> String:
	return 'Is On Floor'


func get_icon() -> String:
	return 'chevrons-right'


func get_target_classes() -> Array[StringName]:
	return [&'CharacterBody2D']


func get_default_phase() -> StringName:
	return &'physics'


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'}
	]


func get_flow_outputs() -> Array[Dictionary]:
	return [
		{name = 'True', id = &'true'},
		{name = 'False', id = &'false'}
	]


func get_flow_enter() -> String:
	return _body()


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


func _body() -> String:
	return 'if _ref.is_on_floor():\n\t{{true}}\nelse:\n\t{{false}}'
