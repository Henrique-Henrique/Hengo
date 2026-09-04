@tool
class_name HenActionClamp extends HenScriptMacroBase


# writes Value limited to the Min..Max range into Store.


func get_id() -> StringName:
	return &'clamp_value'


func get_description() -> String:
	return 'Keeps a value inside a range, so it never goes below Min or above Max.'


func get_display_name() -> String:
	return 'Clamp'


func get_icon() -> String:
	return 'ruler'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Value',
			type = 'Variant',
			id = &'value',
			doc = 'The value to limit.',
			type_from = &'result',
			default_value = 0.0
		},
		{
			name = 'Min',
			type = 'Variant',
			id = &'min',
			doc = 'The lowest allowed value.',
			type_from = &'result',
			default_value = 0.0
		},
		{
			name = 'Max',
			type = 'Variant',
			id = &'max',
			doc = 'The highest allowed value.',
			type_from = &'result',
			default_value = 1.0
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Result', type = 'Variant', id = &'result', doc = 'The clamped value.'}
	]


func get_output_result() -> String:
	return 'clamp({{value}}, {{min}}, {{max}})'


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
