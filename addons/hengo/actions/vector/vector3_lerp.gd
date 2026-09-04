@tool
class_name HenActionVector3Lerp extends HenScriptMacroBase


# writes the blend of From and To into Store. Weight 0 is From, 1 is To.


func get_id() -> StringName:
	return &'vector3_lerp'


func get_description() -> String:
	return 'Blends two 3D vectors by a weight and stores the result. Weight 0 is the first, 1 is the second.'


func get_display_name() -> String:
	return 'Vector3 Lerp'


func get_icon() -> String:
	return 'blend'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'From',
			type = 'Vector3',
			id = &'from',
			doc = 'The value at weight 0.',
			default_value = Vector3.ZERO
		},
		{
			name = 'To',
			type = 'Vector3',
			id = &'to',
			doc = 'The value at weight 1.',
			default_value = Vector3.ZERO
		},
		{
			name = 'Weight',
			type = 'float',
			id = &'weight',
			doc = 'How far from the first to the second, 0 to 1.',
			default_value = 0.5
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Result', type = 'Vector3', id = &'result', doc = 'The blended vector.'}
	]


func get_output_result() -> String:
	return '{{from}}.lerp({{to}}, {{weight}})'


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
