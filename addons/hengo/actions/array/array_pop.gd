@tool
class_name HenActionArrayPop extends HenScriptMacroBase


# removes and writes the last or first item of Array into Store. an empty
# array returns null, so check the length first when the size matters.


func get_id() -> StringName:
	return &'array_pop'


func get_description() -> String:
	return 'Removes and returns the last or first item of an array. An empty array returns null.'


func get_display_name() -> String:
	return 'Array Pop'


func get_icon() -> String:
	return 'list-x'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Array',
			type = 'Array',
			id = &'array',
			doc = 'The array to pop from. Must be bound to a variable or property.',
			bind_only = true,
			default_value = null
		},
		{
			name = 'End',
			type = 'String',
			id = &'end',
			doc = 'Which end of the array the item is removed from.',
			raw = true,
			options = ['back', 'front'],
			default_value = 'back'
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Result', type = 'Variant', id = &'result', doc = 'Where to store the removed item.'}
	]


func get_output_result() -> String:
	return '{{array}}.pop_{{end}}()'


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'},
		{name = 'Exit', id = &'exit'}
	]


func get_flow_enter() -> String:
	return _body()


func get_flow_update() -> String:
	return _body()


func get_flow_exit() -> String:
	return _body()


func _body() -> String:
	return '{{out:result}}'
