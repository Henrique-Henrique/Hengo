@tool
class_name HenActionArrayGet extends HenScriptMacroBase


# writes the item at Index into Store. an out of range index breaks at runtime,
# so pair it with Array Length when the index is dynamic.


func get_id() -> StringName:
	return &'array_get'


func get_display_name() -> String:
	return 'Array Get'


func get_icon() -> String:
	return 'list'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Array',
			type = 'Array',
			id = &'array',
			bind_only = true,
			default_value = null
		},
		{
			name = 'Index',
			type = 'int',
			id = &'index',
			default_value = 0
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Result', type = 'Variant', id = &'result'}
	]


func get_output_result() -> String:
	return '{{array}}[{{index}}]'


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
