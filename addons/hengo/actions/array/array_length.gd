@tool
class_name HenActionArrayLength extends HenScriptMacroBase


# writes the item count of Array into Store.


func get_id() -> StringName:
	return &'array_length'


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
			bind_only = true,
			default_value = null
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Length', type = 'int', id = &'result'}
	]


func get_output_result() -> String:
	return '{{array}}.size()'


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
