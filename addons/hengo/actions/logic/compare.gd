@tool
class_name HenActionCompare extends HenScriptMacroBase


# branches on `A <op> B`. each flow output is a branch whose transition target is
# set per action in the inspector.


func get_id() -> StringName:
	return &'compare'


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
			default_value = 0
		},
		{
			name = 'Operator',
			type = 'String',
			id = &'op',
			raw = true,
			options = ['==', '!=', '>', '>=', '<', '<='],
			default_value = '=='
		},
		{
			name = 'B',
			type = 'Variant',
			id = &'b',
			type_from = &'a',
			default_value = 0
		}
	]


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'}
	]


func get_flow_outputs() -> Array[Dictionary]:
	return [
		{name = 'True', id = &'true'},
		{name = 'False', id = &'false'}
	]


func get_flow_enter() -> String:
	return _body()


func get_flow_update() -> String:
	return _body()


func _body() -> String:
	return 'if {{a}} {{op}} {{b}}:\n\t{{true}}\nelse:\n\t{{false}}'
