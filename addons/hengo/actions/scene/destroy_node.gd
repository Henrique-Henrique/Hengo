@tool
class_name HenActionDestroyNode extends HenScriptMacroBase


func get_id() -> StringName:
	return &'destroy_node'


func get_description() -> String:
	return 'Removes another node from the scene at the end of the frame. Destroy Self is the one that removes this node instead.'


func get_display_name() -> String:
	return 'Destroy Node'


func get_icon() -> String:
	return 'trash-2'


func get_default_phase() -> StringName:
	return &'enter'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Node',
			type = 'Node',
			id = &'node',
			doc = 'The node to destroy. Leave it empty to destroy this node.',
			bind_only = true,
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
	return '{{node}}.queue_free()'
