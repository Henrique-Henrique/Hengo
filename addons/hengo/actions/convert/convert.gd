@tool
class_name HenActionConvert extends HenScriptMacroBase


# writes Value cast to the chosen type into Store — one of int/float/str/bool.


func get_id() -> StringName:
	return &'convert'


func get_description() -> String:
	return 'Converts a value to another basic type, such as int, float, str, or bool.'


func get_display_name() -> String:
	return 'Convert'


func get_icon() -> String:
	return 'binary'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'To',
			type = 'String',
			id = &'to',
				doc = 'The type to convert the value into.',
			raw = true,
			options = ['int', 'float', 'str', 'bool'],
			default_value = 'int'
		},
		{
			name = 'Value',
			type = 'Variant',
			id = &'value',
				doc = 'The value to convert.',
			default_value = 0
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Result', type = 'Variant', id = &'result', doc = 'Where to store the converted value.'}
	]


func get_output_result() -> String:
	return '{{to}}({{value}})'


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
