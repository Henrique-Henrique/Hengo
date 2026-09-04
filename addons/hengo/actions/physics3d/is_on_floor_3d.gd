@tool
class_name HenActionIsOnFloor3D extends HenScriptMacroBase


# branches on the floor contact of the last Move And Slide.


func get_id() -> StringName:
	return &'is_on_floor_3d'


func get_description() -> String:
	return 'Answers whether the body is standing on the floor, from the contact of the last Move And Slide. It can branch on the answer or hand it to a field that takes a yes or no.'


func get_display_name() -> String:
	return 'Is On Floor'


func get_icon() -> String:
	return 'chevrons-right'


func get_target_classes() -> Array[StringName]:
	return [&'CharacterBody3D']


func get_default_phase() -> StringName:
	return &'physics'


func get_inputs() -> Array[Dictionary]:
	return [
		node_ref_input('The body to check. Leave it empty to check this node.'),
	]

func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Yes', type = 'bool', id = &'result', doc = 'Where to store whether the body is on the floor.'}
	]


func get_output_result() -> String:
	return '{{ref}}.is_on_floor()'


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'}
	]


func get_flow_outputs() -> Array[Dictionary]:
	return [
		{name = 'True', id = &'true', optional = true, doc = 'Where to go when the body is on the floor.'},
		{name = 'False', id = &'false', optional = true, doc = 'Where to go when the body is in the air.'}
	]


func get_flow_enter() -> String:
	return _body()


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


# with no branch wired it is only the answer, which is what lets it be read
# from inside another action's field
func _body() -> String:
	if not any_flow_connected():
		return '{{out:result}}'

	return '{{out:result}}\n' \
		+ 'if {{ref}}.is_on_floor():\n' \
		+ '\t{{true}}\n' \
		+ 'else:\n' \
		+ '\t{{false}}'
