@tool
class_name HenActionIsOnScreen extends HenScriptMacroBase


func get_id() -> StringName:
	return &'is_on_screen'


func get_description() -> String:
	return 'Checks whether the node is inside the visible screen and branches on the answer. A bullet or an enemy that left the view takes the False side.'


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


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'}
	]


func get_flow_outputs() -> Array[Dictionary]:
	return [
		{name = 'True', id = &'true', doc = 'Where to go while the node is on screen.'},
		{name = 'False', id = &'false', doc = 'Where to go once the node is off screen.'}
	]


func get_flow_enter() -> String:
	return _body()


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


# get_global_transform_with_canvas() gives the screen point, so a camera counts
func _body() -> String:
	return 'if _ref.get_viewport_rect().has_point({{ref}}.get_global_transform_with_canvas().origin):\n' \
		+ '\t{{true}}\n' \
		+ 'else:\n' \
		+ '\t{{false}}'
