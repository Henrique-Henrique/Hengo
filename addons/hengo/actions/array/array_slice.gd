@tool
class_name HenActionArraySlice extends HenScriptMacroBase


# writes a copy of Array from From up to (not including) To into Store. the
# source array is left untouched.


func get_id() -> StringName:
	return &'array_slice'


func get_description() -> String:
	return 'Copies a range of an array from one position up to another into a new array. The original array is left untouched.'


func get_display_name() -> String:
	return 'Array Slice'


func get_icon() -> String:
	return 'list'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Array',
			type = 'Array',
			id = &'array',
			doc = 'The array to copy from.',
			bind_only = true,
			default_value = null
		},
		{
			name = 'From',
			type = 'int',
			id = &'from',
			doc = 'Position to start at, starting at 0.',
			default_value = 0
		},
		{
			name = 'To',
			type = 'int',
			id = &'to',
			doc = 'Position to stop before. Negative counts from the end.',
			default_value = 1
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Result', type = 'Array', id = &'result', doc = 'Where to store the copied range.'}
	]


func get_output_result() -> String:
	return '{{array}}.slice({{from}}, {{to}})'


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
