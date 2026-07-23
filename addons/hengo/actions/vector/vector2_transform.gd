@tool
class_name HenActionVector2Transform extends HenScriptMacroBase


# writes a Vector2 read of Vector into Store — normalized/abs/sign/floor/etc.


func get_id() -> StringName:
	return &'vector2_transform'


func get_display_name() -> String:
	return 'Vector2 Transform'


func get_icon() -> String:
	return 'move-3d'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Function',
			type = 'String',
			id = &'func_name',
			raw = true,
			options = ['normalized', 'abs', 'sign', 'floor', 'ceil', 'round', 'orthogonal'],
			default_value = 'normalized'
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
		{name = 'Result', type = 'Vector2', id = &'result'}
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
