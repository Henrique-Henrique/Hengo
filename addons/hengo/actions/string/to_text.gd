@tool
class_name HenActionToText extends HenScriptMacroBase


func get_id() -> StringName:
	return &'to_text'


func get_description() -> String:
	return 'Turns a number into text in the chosen format. Use it to feed a label without writing the conversion by hand.'


func get_display_name() -> String:
	return 'To Text'


func get_icon() -> String:
	return 'hash'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Value',
			type = 'Variant',
			id = &'value',
			doc = 'The number to turn into text.',
			default_value = 0
		},
		{
			name = 'Format',
			type = 'String',
			id = &'mode',
			doc = 'How much of the number to keep. Whole rounds to the nearest, cut drops the decimals.',
			raw = true,
			options = ['whole', 'cut', '1 decimal', '2 decimals', 'plain'],
			default_value = 'whole'
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Result', type = 'String', id = &'result', doc = 'Where to store the resulting text.'}
	]


func get_output_result() -> String:
	match str(value_of(&'mode', 'whole')):
		'cut':
			return 'str(int({{value}}))'
		'1 decimal':
			return "('%.1f' % {{value}})"
		'2 decimals':
			return "('%.2f' % {{value}})"
		'plain':
			return 'str({{value}})'

	return 'str(roundi({{value}}))'


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
