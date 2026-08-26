@tool
class_name HenActionVector3Transform extends HenScriptMacroBase


# writes a Vector3 read of Vector into Store — normalized/abs/sign/floor/etc.


func get_id() -> StringName:
	return &'vector3_transform'


func get_description() -> String:
	return 'Reshapes a 3D vector and stores the new one, most often to normalize it: keep the direction but set the length to 1, so it stops carrying a speed.'


func get_display_name() -> String:
	return 'Vector3 Transform'


func get_icon() -> String:
	return 'move-3d'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Function',
			type = 'String',
			id = &'func_name',
			doc = 'normalized keeps the direction and sets the length to 1, abs drops the minus signs, and floor, ceil and round snap to whole numbers.',
			raw = true,
			options = ['normalized', 'abs', 'sign', 'ceil', 'floor', 'round'],
			default_value = 'normalized'
		},
		{
			name = 'Vector',
			type = 'Vector3',
			id = &'vector',
			doc = 'The vector to transform.',
			default_value = Vector3.ZERO
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Result', type = 'Vector3', id = &'result', doc = 'The resulting vector.'}
	]


func get_output_result() -> String:
	return '{{vector}}.{{func_name}}()'


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
