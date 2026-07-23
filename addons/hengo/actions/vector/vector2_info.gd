@tool
class_name HenActionVector2Info extends HenScriptMacroBase


# writes a scalar read of Vector into Store — length/length_squared/angle.


func get_id() -> StringName:
	return &'vector2_info'


func get_display_name() -> String:
	return 'Vector2 Info'


func get_icon() -> String:
	return 'ruler'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Function',
			type = 'String',
			id = &'func_name',
			raw = true,
			options = ['length', 'length_squared', 'angle'],
			default_value = 'length'
		},
		{
			name = 'Vector',
			type = 'Vector2',
			id = &'vector',
			default_value = Vector2.ZERO
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Result', type = 'float', id = &'result'}
	]


func get_output_result() -> String:
	return '{{vector}}.{{func_name}}()'


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'},
		{name = 'Exit', id = &'exit'}
	]


func get_flow_enter() -> String:
	return _body()


func get_flow_update() -> String:
	return _body()


func get_flow_exit() -> String:
	return _body()


func _body() -> String:
	return '{{out:result}}'
