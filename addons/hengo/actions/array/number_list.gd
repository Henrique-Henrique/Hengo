@tool
class_name HenActionNumberList extends HenScriptMacroBase


func get_id() -> StringName:
	return &'number_list'


func get_description() -> String:
	return 'Builds a list of numbers, ready to walk with For Each or to use as indexes.'


func get_display_name() -> String:
	return 'Number List'


func get_icon() -> String:
	return 'list-ordered'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'From',
			type = 'int',
			id = &'from',
			doc = 'The first number of the list.',
			default_value = 0
		},
		{
			name = 'To',
			type = 'int',
			id = &'to',
			doc = 'The number to stop before, so it is never part of the list.',
			default_value = 10
		},
		{
			name = 'Step',
			type = 'int',
			id = &'step',
			doc = 'How much to advance between numbers. Negative counts down.',
			default_value = 1
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Result', type = 'Array', id = &'result', doc = 'The built list of numbers.'}
	]


func get_output_result() -> String:
	return 'range({{from}}, {{to}}, {{step}})'


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'},
		{name = 'Exit', id = &'exit'}
	]


# range() never advances with a step of 0 and hangs the game in an endless loop
func get_validation_error() -> String:
	return 'the step is 0, which would never reach the end' if int(value_of(&'step', 1)) == 0 else ''


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
