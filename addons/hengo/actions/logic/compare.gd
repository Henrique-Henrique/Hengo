@tool
class_name HenActionCompare extends HenScriptMacroBase


# branches on `A <op> B`. each flow output is a branch whose transition target is
# set per action in the inspector.


func get_id() -> StringName:
	return &'compare'


func get_description() -> String:
	return 'Answers how two values compare, using the operator picked in the middle. It can branch on the answer or hand it to a field that takes a yes or no.'


func get_display_name() -> String:
	return 'Compare'


func get_icon() -> String:
	return 'git-compare'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'A',
			type = 'Variant',
			id = &'a',
				doc = 'The left value in the comparison.',
			default_value = 0
		},
		{
			name = 'Operator',
			type = 'String',
			id = &'op',
				doc = 'How to compare the two values.',
			raw = true,
			options = ['==', '!=', '>', '>=', '<', '<='],
			default_value = '=='
		},
		{
			name = 'B',
			type = 'Variant',
			id = &'b',
				doc = 'The right value in the comparison.',
			type_from = &'a',
			default_value = 0
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Yes', type = 'bool', id = &'result', doc = 'Where to store the answer of the comparison.'}
	]


func get_output_result() -> String:
	return '{{a}} {{op}} {{b}}'


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'},
		{name = 'Exit', id = &'exit'}
	]


func get_flow_outputs() -> Array[Dictionary]:
	return [
		{name = 'True', id = &'true', optional = true, doc = 'Where to go when the comparison is true.'},
		{name = 'False', id = &'false', optional = true, doc = 'Where to go when the comparison is false.'}
	]


func get_flow_enter() -> String:
	return _body()


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


func get_flow_exit() -> String:
	return _body()


# with no branch wired it is only the answer, which is what lets it be read
# from inside another action's field
func _body() -> String:
	if not any_flow_connected():
		return '{{out:result}}'

	return '{{out:result}}\n' \
		+ 'if {{a}} {{op}} {{b}}:\n' \
		+ '\t{{true}}\n' \
		+ 'else:\n' \
		+ '\t{{false}}'
