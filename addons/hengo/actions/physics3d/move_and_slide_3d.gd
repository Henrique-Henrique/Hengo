@tool
class_name HenActionMoveAndSlide3D extends HenScriptMacroBase


# applies the body velocity for this frame. put it after the actions that write
# the velocity.


func get_id() -> StringName:
	return &'move_and_slide_3d'


func get_display_name() -> String:
	return 'Move And Slide'


func get_icon() -> String:
	return 'footprints'


func get_target_classes() -> Array[StringName]:
	return [&'CharacterBody3D']


func get_default_phase() -> StringName:
	return &'physics'


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
	return '_ref.move_and_slide()'
