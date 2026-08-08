@tool
class_name HenActionBestInList extends HenScriptMacroBase


func get_id() -> StringName:
	return &'best_in_list'


func get_description() -> String:
	return 'Picks one number out of a list: the smallest, the biggest, or the one nearest to a target.'


func get_display_name() -> String:
	return 'Best In List'


func get_icon() -> String:
	return 'list-checks'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'List',
			type = 'Array',
			id = &'list',
			doc = 'The list of numbers to choose from.',
			bind_only = true,
			default_value = null
		},
		{
			name = 'Pick',
			type = 'String',
			id = &'mode',
			doc = 'Which one to take.',
			raw = true,
			options = ['lowest', 'highest', 'nearest'],
			default_value = 'lowest'
		},
		{
			name = 'Near',
			type = 'float',
			id = &'target',
			doc = 'The number to be near, used only by nearest.',
			optional = true,
			default_value = 0.0
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Result', type = 'Variant', id = &'result', doc = 'The chosen number, or null when the list is empty.'}
	]


func get_output_result() -> String:
	match str(value_of(&'mode', 'lowest')):
		'highest':
			return '{{list}}.reduce(func(a, b): return a if a >= b else b)'
		'nearest':
			return '{{list}}.reduce(func(a, b): return a if absf(a - {{target}}) <= absf(b - {{target}}) else b)'

	return '{{list}}.reduce(func(a, b): return a if a <= b else b)'


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
