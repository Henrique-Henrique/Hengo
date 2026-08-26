@tool
class_name HenActionMakeVector2 extends HenScriptMacroBase


# writes Vector2(X, Y) into Store.


func get_id() -> StringName:
	return &'make_vector2'


func get_description() -> String:
	return 'Builds a Vector2 from separate X and Y numbers.'


func get_display_name() -> String:
	return 'Make Vector2'


func get_icon() -> String:
	return 'move-diagonal'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'X',
			type = 'float',
			id = &'x',
			doc = 'The horizontal component.',
			default_value = 0.0
		},
		{
			name = 'Y',
			type = 'float',
			id = &'y',
			doc = 'The vertical component.',
			default_value = 0.0
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Result', type = 'Vector2', id = &'result', doc = 'The built vector.'}
	]


func get_output_result() -> String:
	return 'Vector2({{x}}, {{y}})'


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
