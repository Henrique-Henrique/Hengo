@tool
class_name HenActionStringSplit extends HenScriptMacroBase


# splits Value on Separator and writes the pieces as an Array into Store.


func get_id() -> StringName:
	return &'string_split'


func get_description() -> String:
	return 'Splits text into pieces wherever a separator appears and stores them as an array.'


func get_display_name() -> String:
	return 'String Split'


func get_icon() -> String:
	return 'split'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Value',
			type = 'String',
			id = &'value',
			doc = 'The text to split.',
			default_value = ''
		},
		{
			name = 'Separator',
			type = 'String',
			id = &'sep',
			doc = 'The text that marks where to split.',
			default_value = ' '
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Result', type = 'Array', id = &'result', doc = 'Where to store the array of pieces.'}
	]


# Array() converts the PackedStringArray so it fits an Array-typed variable
func get_output_result() -> String:
	return 'Array(str({{value}}).split({{sep}}))'


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
