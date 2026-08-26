@tool
class_name HenActionArraySum extends HenScriptMacroBase


# writes the total of every number in Array into Store. an empty array totals 0.


func get_id() -> StringName:
	return &'array_sum'


func get_description() -> String:
	return 'Adds up every number in an array and stores the total. An empty array totals zero.'


func get_display_name() -> String:
	return 'Array Sum'


func get_icon() -> String:
	return 'sigma'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Array',
			type = 'Array',
			id = &'array',
			doc = 'The array of numbers to add up.',
			bind_only = true,
			default_value = null
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Total', type = 'float', id = &'result', doc = 'Where to store the sum of the numbers.'}
	]


func get_output_result() -> String:
	return '{{array}}.reduce(func(acc, item): return acc + item, 0.0)'


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
