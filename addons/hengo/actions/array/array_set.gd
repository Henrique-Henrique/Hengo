@tool
class_name HenActionArraySet extends HenScriptMacroBase


# overwrites the item at Index. an out of range index breaks at runtime, so
# pair it with Array Length when the index is dynamic.


func get_id() -> StringName:
	return &'array_set'


func get_description() -> String:
	return 'Overwrites the item at a given position in an array. An index outside the array fails at runtime.'


func get_display_name() -> String:
	return 'Array Set'


func get_icon() -> String:
	return 'list-checks'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Array',
			type = 'Array',
			id = &'array',
			doc = 'The array to write into. Must be bound to a variable or property.',
			bind_only = true,
			default_value = null
		},
		{
			name = 'Index',
			type = 'int',
			id = &'index',
			doc = 'Position of the item to overwrite, starting at 0.',
			default_value = 0
		},
		{
			name = 'Value',
			type = 'Variant',
			id = &'value',
			doc = 'The value written at the index.',
			default_value = 0
		}
	]


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
	return '{{array}}[{{index}}] = {{value}}'
