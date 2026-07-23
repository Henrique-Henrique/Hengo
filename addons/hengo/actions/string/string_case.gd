@tool
class_name HenActionStringCase extends HenScriptMacroBase


# writes Value transformed by the chosen case method into Store.


func get_id() -> StringName:
	return &'string_case'


func get_display_name() -> String:
	return 'String Case'


func get_icon() -> String:
	return 'case-upper'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Function',
			type = 'String',
			id = &'func_name',
			raw = true,
			options = ['to_upper', 'to_lower', 'capitalize', 'strip_edges'],
			default_value = 'to_upper'
		},
		{
			name = 'Value',
			type = 'String',
			id = &'value',
			default_value = ''
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Result', type = 'String', id = &'result'}
	]


func get_output_result() -> String:
	return 'str({{value}}).{{func_name}}()'


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
