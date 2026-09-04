@tool
class_name HenActionGetVector2XY extends HenScriptMacroBase


# splits Vector into its two components, one output each. store the ones needed.


func get_id() -> StringName:
	return &'get_vector2_xy'


func get_description() -> String:
	return 'Splits a Vector2 into its separate X and Y numbers.'


func get_display_name() -> String:
	return 'Get Vector2 XY'


func get_icon() -> String:
	return 'move-diagonal-2'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Vector',
			type = 'Vector2',
			id = &'vector',
			doc = 'The vector to split.',
			default_value = Vector2.ZERO
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'X', type = 'float', id = &'x', doc = 'The horizontal component.'},
		{name = 'Y', type = 'float', id = &'y', doc = 'The vertical component.'}
	]


func get_output_x() -> String:
	return '{{vector}}.x'


func get_output_y() -> String:
	return '{{vector}}.y'


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
	return '{{out:x}}\n{{out:y}}'
