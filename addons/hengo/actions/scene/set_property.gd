@tool
class_name HenActionSetProperty extends HenScriptMacroBase


func get_id() -> StringName:
	return &'set_property'


func get_description() -> String:
	return 'Writes a value into a property or a variable of any node, found by its name. It reaches other nodes, so one script can drive the whole scene.'


func get_display_name() -> String:
	return 'Set Property'


func get_icon() -> String:
	return 'sliders-vertical'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Node',
			type = 'Node',
			id = &'node',
			doc = 'The node to write to. Leave it empty to write to this node.',
			bind_only = true,
			optional = true,
			default_value = null
		},
		{
			name = 'Name',
			type = 'String',
			id = &'name',
			doc = 'The name of the property or variable, such as position or health.',
			default_value = 'position'
		},
		{
			name = 'Value',
			type = 'Variant',
			id = &'value',
			doc = 'The value to write.',
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
	return '{{node}}.set({{name}}, {{value}})'
