@tool
class_name HenActionArrayLength extends HenScriptMacroBase


# writes the item count of Array into Store.


func get_id() -> StringName:
	return &'array_length'


func get_description() -> String:
	return 'Counts how many items an array holds.'


func get_display_name() -> String:
	return 'Array Length'


func get_icon() -> String:
	return 'list-ordered'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Array',
			type = 'Array',
			id = &'array',
				doc = 'The array to measure.',
			bind_only = true,
			default_value = null
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Length', type = 'int', id = &'result', doc = 'Where to store the number of items.'}
	]


func get_output_result() -> String:
	return '{{array}}.size()'


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
