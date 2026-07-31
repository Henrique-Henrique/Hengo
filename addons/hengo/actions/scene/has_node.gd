@tool
class_name HenActionHasNode extends HenScriptMacroBase


# branches on whether a child exists at Path, relative to the owner. use it
# before reading a node that may have been freed or never spawned.


func get_id() -> StringName:
	return &'has_node'


func get_description() -> String:
	return 'Checks whether a node exists at a path below this node and branches on the answer. Useful before reading a node that may be missing.'


func get_display_name() -> String:
	return 'Has Node'


func get_icon() -> String:
	return 'git-branch'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Path',
			type = 'String',
			id = &'path',
			doc = 'The node path to check, relative to this node.',
			default_value = ''
		}
	]


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'}
	]


func get_flow_outputs() -> Array[Dictionary]:
	return [
		{name = 'True', id = &'true', doc = 'Where to go when the node exists.'},
		{name = 'False', id = &'false', doc = 'Where to go when the node is missing.'}
	]


func get_flow_enter() -> String:
	return _body()


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


func _body() -> String:
	return 'if _ref.has_node({{path}}):\n\t{{true}}\nelse:\n\t{{false}}'
