@tool
class_name HenActionStringJoin extends HenScriptMacroBase


# joins every item of Array into one string, placing Separator between them, and
# writes it into Store.


func get_id() -> StringName:
	return &'string_join'


func get_description() -> String:
	return 'Joins the items of an array into one piece of text, placing a separator between them.'


func get_display_name() -> String:
	return 'Join Text'


func get_icon() -> String:
	return 'link'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Array',
			type = 'Array',
			id = &'array',
			doc = 'The array of items to join.',
			bind_only = true,
			default_value = null
		},
		{
			name = 'Separator',
			type = 'String',
			id = &'sep',
			doc = 'The text placed between each item.',
			default_value = ', '
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Result', type = 'String', id = &'result', doc = 'Where to store the joined text.'}
	]


# join expects strings, so map the items through str() first
func get_output_result() -> String:
	return 'str({{sep}}).join({{array}}.map(func(item): return str(item)))'


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
