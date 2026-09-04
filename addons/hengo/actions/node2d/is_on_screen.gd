@tool
class_name HenActionIsOnScreen extends HenScriptMacroBase


func get_id() -> StringName:
	return &'is_on_screen'


func get_description() -> String:
	return 'Answers whether the node is inside the visible screen, so a bullet or an enemy that left the view can be cleared. It can branch on the answer or hand it to a field that takes a yes or no.'


func get_display_name() -> String:
	return 'Is On Screen'


func get_icon() -> String:
	return 'eye'


func get_target_classes() -> Array[StringName]:
	return [&'Node2D']


func get_inputs() -> Array[Dictionary]:
	return [
		node_ref_input('The node to check. Leave it empty to check this node.')
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Yes', type = 'bool', id = &'result', doc = 'Where to store whether the node is inside the view.'}
	]


func get_output_result() -> String:
	return '_ref.get_viewport_rect().has_point({{ref}}.get_global_transform_with_canvas().origin)'


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'}
	]


func get_flow_outputs() -> Array[Dictionary]:
	return [
		{name = 'True', id = &'true', optional = true, doc = 'Where to go while the node is on screen.'},
		{name = 'False', id = &'false', optional = true, doc = 'Where to go once the node is off screen.'}
	]


func get_flow_enter() -> String:
	return _body()


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


# get_global_transform_with_canvas() gives the screen point, so a camera counts
# with no branch wired it is only the answer, which is what lets it be read from
# inside another action's field
func _body() -> String:
	if not any_flow_connected():
		return '{{out:result}}'

	return '{{out:result}}\n' \
		+ 'if _ref.get_viewport_rect().has_point({{ref}}.get_global_transform_with_canvas().origin):\n' \
		+ '\t{{true}}\n' \
		+ 'else:\n' \
		+ '\t{{false}}'
