@tool
class_name HenActionArrayInsert extends HenScriptMacroBase


# inserts Value at Index, shifting later items right. an out of range index
# breaks at runtime, so pair it with Array Length when the index is dynamic.


func get_id() -> StringName:
	return &'array_insert'


func get_description() -> String:
	return 'Inserts a value at a given position in an array, shifting later items to the right.'


func get_display_name() -> String:
	return 'Array Insert'


func get_icon() -> String:
	return 'list-plus'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Array',
			type = 'Array',
			id = &'array',
			doc = 'The array to insert into. Must be bound to a variable or property.',
			bind_only = true,
			default_value = null
		},
		{
			name = 'Index',
			type = 'int',
			id = &'index',
			doc = 'Position where the value is inserted, starting at 0.',
			default_value = 0
		},
		{
			name = 'Value',
			type = 'Variant',
			id = &'value',
			doc = 'The value to insert into the array.',
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
	return '{{array}}.insert({{index}}, {{value}})'
