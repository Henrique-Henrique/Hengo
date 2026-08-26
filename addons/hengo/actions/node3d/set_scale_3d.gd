@tool
class_name HenActionSetScale3D extends HenScriptMacroBase


# sets the owner's scale.


func get_id() -> StringName:
	return &'set_scale_3d'


func get_description() -> String:
	return 'Sets the scale of the node.'


func get_display_name() -> String:
	return 'Set Scale'


func get_icon() -> String:
	return 'scale-3d'


func get_target_classes() -> Array[StringName]:
	return [&'Node3D']


func get_inputs() -> Array[Dictionary]:
	return [
		node_ref_input('The node to resize. Leave it empty to resize this node.'),
		{
			name = 'Scale',
			type = 'Vector3',
			id = &'scale',
			doc = 'The new scale, where 1, 1, 1 is the normal size.',
			default_value = Vector3.ONE
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
	return '{{ref}}.scale = {{scale}}'
