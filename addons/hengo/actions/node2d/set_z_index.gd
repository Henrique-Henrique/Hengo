@tool
class_name HenActionSetZIndex extends HenScriptMacroBase


# sets the draw order of the owner. a higher value draws in front of lower ones.


func get_id() -> StringName:
	return &'set_z_index'


func get_description() -> String:
	return 'Sets the draw order of the node. A higher value draws in front of nodes with a lower one.'


func get_display_name() -> String:
	return 'Set Draw Order'


func get_icon() -> String:
	return 'layers'


func get_target_classes() -> Array[StringName]:
	return [&'CanvasItem']


func get_default_phase() -> StringName:
	return &'enter'


func get_inputs() -> Array[Dictionary]:
	return [
		node_ref_input('The node to reorder. Leave it empty to reorder this node.'),
		{
			name = 'Order',
			type = 'int',
			id = &'z',
			doc = 'The draw order. Higher draws in front.',
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
	return '{{ref}}.z_index = {{z}}'
