@tool
class_name HenActionMoveAndSlide3D extends HenScriptMacroBase


# applies the body velocity for this frame. put it after the actions that write
# the velocity.


func get_id() -> StringName:
	return &'move_and_slide_3d'


func get_description() -> String:
	return 'Moves the body with its current velocity, resolving collisions. Place it after the actions that set the velocity.'


func get_display_name() -> String:
	return 'Move And Slide'


func get_icon() -> String:
	return 'footprints'


func get_target_classes() -> Array[StringName]:
	return [&'CharacterBody3D']


func get_default_phase() -> StringName:
	return &'physics'


func get_inputs() -> Array[Dictionary]:
	return [
		node_ref_input('The body to move. Leave it empty to move this node.'),
	]

func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'}
	]


func get_flow_outputs() -> Array[Dictionary]:
	return [
		{
			name = 'Hit Something',
			id = &'hit',
			optional = true,
			doc = 'Where to go when the move ran into a wall, a floor or another body.'
		},
		{
			name = 'Clear',
			id = &'clear',
			optional = true,
			doc = 'Where to go when the move touched nothing.'
		}
	]


func get_flow_enter() -> String:
	return _body()


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


# get_slide_collision_count reports what the last move_and_slide call ran into
func _body() -> String:
	if not any_flow_connected():
		return '{{ref}}.move_and_slide()'

	return '{{ref}}.move_and_slide()\n' \
		+ 'if {{ref}}.get_slide_collision_count() > 0:\n' \
		+ '\t{{hit}}\n' \
		+ 'else:\n' \
		+ '\t{{clear}}'
