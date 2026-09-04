@tool
class_name HenActionGetGlobalPosition extends HenScriptMacroBase


# writes the global position of Node into Store. it is the piece a homing action
# needs after Get Nearest: move or look actions want a point, not the node.


func get_id() -> StringName:
	return &'get_global_position'


func get_description() -> String:
	return 'Reads the global position of a node and stores it. This is what a move or look action needs after Get Nearest, which hands back the node, not its point.'


func get_display_name() -> String:
	return 'Get Position'


func get_icon() -> String:
	return 'map-pin'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Node',
			type = 'Node',
			id = &'node',
			doc = 'The node to read the position of. Leave it empty to read this node.',
			bind_only = true,
			optional = true,
			default_value = null
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Result', type = 'Variant', id = &'result', doc = 'Where to store the global position (Vector2 in 2D, Vector3 in 3D).'}
	]


func get_output_result() -> String:
	return '{{node}}.global_position'


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
