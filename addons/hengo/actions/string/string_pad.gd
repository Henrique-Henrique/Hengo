@tool
class_name HenActionStringPad extends HenScriptMacroBase


# writes Value padded on the left up to Width into Store, the trick a scoreboard
# uses to show 0042 instead of 42.


func get_id() -> StringName:
	return &'string_pad'


func get_description() -> String:
	return 'Pads text on the left with a character until it reaches a width. This is what turns 42 into 0042 for a scoreboard.'


func get_display_name() -> String:
	return 'Pad Number'


func get_icon() -> String:
	return 'hash'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Value',
			type = 'String',
			id = &'value',
			doc = 'The text or number to pad.',
			default_value = ''
		},
		{
			name = 'Width',
			type = 'int',
			id = &'width',
			doc = 'The least number of characters the result should have.',
			default_value = 4
		},
		{
			name = 'Pad',
			type = 'String',
			id = &'pad',
			doc = 'The single character used to fill the gap.',
			default_value = '0'
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Result', type = 'String', id = &'result', doc = 'The padded text.'}
	]


func get_output_result() -> String:
	return 'str({{value}}).lpad({{width}}, {{pad}})'


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
