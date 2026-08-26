@tool
class_name HenActionWrapValue extends HenScriptMacroBase


func get_id() -> StringName:
	return &'wrap_value'


func get_description() -> String:
	return 'Brings a number back into a range, so a value past the end comes out at Min again. It is what cycles a menu index from the last item back to the first.'


func get_display_name() -> String:
	return 'Wrap Number'


func get_icon() -> String:
	return 'repeat'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Value',
			type = 'Variant',
			id = &'value',
			doc = 'The number to bring back into the range.',
			type_from = &'result',
			default_value = 0
		},
		{
			name = 'Min',
			type = 'Variant',
			id = &'min',
			doc = 'The start of the range, which the result can be.',
			type_from = &'result',
			default_value = 0
		},
		{
			name = 'Max',
			type = 'Variant',
			id = &'max',
			doc = 'The end of the range, which the result never is. With a Min of 0, this is the item count.',
			type_from = &'result',
			default_value = 10
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Result', type = 'Variant', id = &'result', doc = 'The wrapped value, a whole number when every input is one.'}
	]


# wrap() returns an int when every argument is an int, unlike wrapf()
func get_output_result() -> String:
	return 'wrap({{value}}, {{min}}, {{max}})'


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
