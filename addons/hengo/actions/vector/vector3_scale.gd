@tool
class_name HenActionVector3Scale extends HenScriptMacroBase


func get_id() -> StringName:
	return &'vector3_scale'


func get_description() -> String:
	return 'Multiplies a vector by a single number, keeping its direction and changing its length. It is how a direction becomes a speed.'


func get_display_name() -> String:
	return 'Scale Vector3'


func get_icon() -> String:
	return 'move-3d'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Vector',
			type = 'Vector3',
			id = &'vector',
			doc = 'The vector to grow or shrink.',
			default_value = Vector3.ZERO
		},
		{
			name = 'Factor',
			type = 'float',
			id = &'factor',
			doc = 'How much to multiply it by. Below 1 shrinks it, and a negative number flips it.',
			default_value = 1.0
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Result', type = 'Vector3', id = &'result', doc = 'The scaled vector.'}
	]


func get_output_result() -> String:
	return '{{vector}} * {{factor}}'


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
