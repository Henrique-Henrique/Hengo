@tool
class_name HenActionIsOnWall extends HenScriptMacroBase


# branches on the wall contact of the last Move And Slide.


func get_id() -> StringName:
	return &'is_on_wall'


func get_description() -> String:
	return 'Answers whether the body is pressed against a wall, from the contact of the last Move And Slide. It can branch on the answer or hand it to a field that takes a yes or no.'


func get_display_name() -> String:
	return 'Is On Wall'


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

func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Yes', type = 'bool', id = &'result', doc = 'Where to store whether the body is against a wall.'}
	]


func get_output_result() -> String:
	return '{{ref}}.is_on_wall()'


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'}
	]


func get_flow_outputs() -> Array[Dictionary]:
	return [
		{name = 'True', id = &'true', optional = true, doc = 'Where to go when the body touches a wall.'},
		{name = 'False', id = &'false', optional = true, doc = 'Where to go when the body touches no wall.'}
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
		+ 'if {{ref}}.is_on_wall():\n' \
		+ '\t{{true}}\n' \
		+ 'else:\n' \
		+ '\t{{false}}'
