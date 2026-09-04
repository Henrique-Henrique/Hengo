@tool
class_name HenActionFollowNode3D extends HenScriptMacroBase


func get_id() -> StringName:
	return &'follow_node_3d'


func get_description() -> String:
	return 'Glides the node toward another node every frame, so it trails the target instead of snapping onto it. With Speed = 8 it keeps a health bar over an enemy head, a pet behind the player or a marker on a minimap, and Follow With Camera does the same for a camera.'


func get_display_name() -> String:
	return 'Follow Node'


func get_icon() -> String:
	return 'target'


func get_target_classes() -> Array[StringName]:
	return [&'Node3D']


func get_default_phase() -> StringName:
	return &'update'


func get_inputs() -> Array[Dictionary]:
	return [
		node_ref_input('The node that follows. Leave it empty to move this node.'),
		{
			name = 'Target',
			type = 'Node',
			id = &'target',
			doc = 'The node to follow.',
			bind_only = true,
			default_value = null
		},
		{
			name = 'Offset',
			type = 'Vector3',
			id = &'offset',
			doc = 'How far from the target to sit, such as above its head.',
			default_value = Vector3.ZERO
		},
		{
			name = 'Speed',
			type = 'float',
			id = &'speed',
			doc = 'How fast the node catches up. A bigger value follows tighter.',
			default_value = 8.0
		}
	]


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'}
	]


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


func _body() -> String:
	return '{{ref}}.global_position = {{ref}}.global_position.lerp({{target}}.global_position + {{offset}}, clampf({{speed}} * delta, 0.0, 1.0))'
