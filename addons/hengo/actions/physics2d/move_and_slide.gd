@tool
class_name HenActionMoveAndSlide extends HenScriptMacroBase


# applies the body velocity for this frame. put it after the actions that write
# the velocity.


func get_id() -> StringName:
	return &'move_and_slide'


func get_description() -> String:
	return 'Moves the body with its current velocity, resolving collisions. Place it after the actions that set the velocity.'


func get_display_name() -> String:
	return 'Move And Slide'


func get_icon() -> String:
	return 'footprints'


func get_target_classes() -> Array[StringName]:
	return [&'CharacterBody2D']


func get_default_phase() -> StringName:
	return &'physics'


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
	return '_ref.move_and_slide()'
