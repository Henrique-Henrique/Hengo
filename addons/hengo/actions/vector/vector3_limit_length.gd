@tool
class_name HenActionVector3LimitLength extends HenScriptMacroBase


# writes Vector shortened to at most Max length into Store, the cap a max speed
# needs so diagonal motion is not faster than straight.


func get_id() -> StringName:
	return &'vector3_limit_length'


func get_description() -> String:
	return 'Shortens a 3D vector when it is longer than Max, and leaves it alone when it is not. Capping a velocity is what stops diagonal movement from being faster than walking straight.'


func get_display_name() -> String:
	return 'Vector3 Limit Length'


func get_icon() -> String:
	return 'scaling'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Vector',
			type = 'Vector3',
			id = &'vector',
			doc = 'The vector to cap.',
			default_value = Vector3.ZERO
		},
		{
			name = 'Max',
			type = 'float',
			id = &'max',
			doc = 'The longest the vector may be.',
			default_value = 1.0
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Result', type = 'Vector3', id = &'result', doc = 'The capped vector.'}
	]


func get_output_result() -> String:
	return '{{vector}}.limit_length({{max}})'


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
