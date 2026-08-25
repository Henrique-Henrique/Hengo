@tool
class_name HenActionGetProperty extends HenScriptMacroBase


func get_id() -> StringName:
	return &'get_property'


func get_description() -> String:
	return 'Reads a property or a variable of any node by its name and stores the value. It reaches values no dedicated action covers, on this node or on another one.'


func get_display_name() -> String:
	return 'Get Property'


func get_icon() -> String:
	return 'sliders-horizontal'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Node',
			type = 'Node',
			id = &'node',
			doc = 'The node to read from. Leave it empty to read this node.',
			bind_only = true,
			optional = true,
			default_value = null
		},
		{
			name = 'Name',
			type = 'String',
			id = &'name',
			doc = 'The name of the property or variable, such as health. Reach a part of it with a colon, as in position:y.',
			default_value = 'position'
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Result', type = 'Variant', id = &'result', doc = 'Where to store the value that was read.'}
	]


# get_indexed and not get: it also reaches a part of a property, as in position:y
func get_output_result() -> String:
	return '{{node}}.get_indexed({{name}})'


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
