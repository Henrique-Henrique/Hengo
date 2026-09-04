@tool
class_name HenActionCallMethod extends HenScriptMacroBase


func get_id() -> StringName:
	return &'call_method'


func get_description() -> String:
	return 'Calls a method on a node, with an optional argument. It reaches methods no dedicated action covers, such as queue_free or a custom one.'


func get_display_name() -> String:
	return 'Call Method'


func get_icon() -> String:
	return 'phone-forwarded'


func get_default_phase() -> StringName:
	return &'enter'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Node',
			type = 'Node',
			id = &'node',
			doc = 'The node to call the method on. Leave it empty to call it on this node.',
			bind_only = true,
			optional = true,
			default_value = null
		},
		{
			name = 'Method',
			type = 'String',
			id = &'method',
			doc = 'The name of the method to call, such as queue_free.',
			default_value = 'queue_free'
		},
		{
			name = 'Argument',
			type = 'Variant',
			id = &'arg',
			doc = 'A single value passed to the method. Leave it empty for a method that takes none.',
			optional = true,
			default_value = null
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
	if is_bound(&'arg') or value_of(&'arg') != null:
		return '{{node}}.call({{method}}, {{arg}})'

	return '{{node}}.call({{method}})'
