@tool
class_name HenActionGetNode extends HenScriptMacroBase


# writes a node of the scene into Store, so the other actions can act on it.


func get_id() -> StringName:
	return &'get_node'


func get_display_name() -> String:
	return 'Get Node'


func get_icon() -> String:
	return 'list-tree'


func get_default_phase() -> StringName:
	return &'enter'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Path',
			type = 'String',
			id = &'path',
			default_value = 'Sprite2D'
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Node', type = 'Variant', id = &'result'}
	]


func get_output_result() -> String:
	return '_ref.get_node_or_null({{path}})'


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'}
	]


func get_flow_enter() -> String:
	return _body()


func get_flow_update() -> String:
	return _body()


func _body() -> String:
	return '{{out:result}}'
