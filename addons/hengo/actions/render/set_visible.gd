@tool
class_name HenActionSetVisible extends HenScriptMacroBase


# shows or hides the owner. a hidden node keeps running, it just is not drawn.


func get_id() -> StringName:
	return &'set_visible'


func get_description() -> String:
	return 'Shows or hides the node. A hidden node keeps running, it just is not drawn.'


func get_display_name() -> String:
	return 'Set Visible'


func get_icon() -> String:
	return 'eye'


func get_default_phase() -> StringName:
	return &'enter'


func get_target_classes() -> Array[StringName]:
	return [&'Node2D', &'Node3D', &'Control']


func get_inputs() -> Array[Dictionary]:
	return [
		node_ref_input('The node to show or hide. Leave it empty to change this node.'),
		{
			name = 'Visible',
			type = 'bool',
			id = &'visible',
				doc = 'On to show the node, off to hide it.',
			default_value = true
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
	return '{{ref}}.visible = {{visible}}'
