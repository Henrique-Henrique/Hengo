@tool
class_name HenActionNodeExists extends HenScriptMacroBase


func get_id() -> StringName:
	return &'node_exists'


func get_description() -> String:
	return 'Stores whether a node exists at a path below this one. It is the Has Node answer as a value, to feed Do If or Combine Checks.'


func get_display_name() -> String:
	return 'Node Exists'


func get_icon() -> String:
	return 'search'


func get_inputs() -> Array[Dictionary]:
	return [
		node_ref_input('The node the path starts from. Leave it empty to start from this node.', 'From'),
		{
			name = 'Path',
			type = 'String',
			id = &'path',
			doc = 'The path to look for, counted from this node.',
			default_value = ''
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Result', type = 'bool', id = &'result', doc = 'True while a node sits at that path.'}
	]


func get_output_result() -> String:
	return '{{ref}}.has_node({{path}})'


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
