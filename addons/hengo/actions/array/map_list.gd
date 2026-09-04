@tool
class_name HenActionMapList extends HenScriptMacroBase


func get_id() -> StringName:
	return &'map_list'


func get_description() -> String:
	return 'Reads one property from every item of a list and stores the values as a new list, such as turning a list of nodes into a list of their scores.'


func get_display_name() -> String:
	return 'Collect Property'


func get_icon() -> String:
	return 'list-plus'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'List',
			type = 'Array',
			id = &'list',
			doc = 'The list to read from.',
			bind_only = true,
			default_value = null
		},
		{
			name = 'Property',
			type = 'String',
			id = &'property',
			doc = 'The property read from each item, with a colon to reach a part of it, as in position:x.',
			default_value = 'name'
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Result', type = 'Array', id = &'result', doc = 'One value per item, in the same order.'}
	]


# get_indexed and not get: it also reaches a part of a property, as in position:x
func get_output_result() -> String:
	return '{{list}}.map(func(it): return it.get_indexed({{property}}))'


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
