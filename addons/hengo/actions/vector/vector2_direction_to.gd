@tool
class_name HenActionVector2DirectionTo extends HenScriptMacroBase


# writes the unit direction from From to To into Store.


func get_id() -> StringName:
	return &'vector2_direction_to'


func get_description() -> String:
	return 'Gives the direction that points from one place to another, always exactly one unit long so it carries no speed of its own. Multiply it with Scale Vector2 to turn it into a velocity, such as sending a bullet toward the player.'


func get_display_name() -> String:
	return 'Vector2 Direction To'


func get_icon() -> String:
	return 'navigation'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'From',
			type = 'Vector2',
			id = &'from',
			doc = 'The starting point.',
			default_value = Vector2.ZERO
		},
		{
			name = 'To',
			type = 'Vector2',
			id = &'to',
			doc = 'The point to aim at.',
			default_value = Vector2.ZERO
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Result', type = 'Vector2', id = &'result', doc = 'The direction from From to To, one unit long.'}
	]


func get_output_result() -> String:
	return '{{from}}.direction_to({{to}})'


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
	return '{{out:result}}'
