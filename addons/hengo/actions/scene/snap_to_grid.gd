@tool
class_name HenActionSnapToGrid extends HenScriptMacroBase


func get_id() -> StringName:
	return &'snap_to_grid'


func get_description() -> String:
	return 'Rounds the position of the node to the nearest grid cell, so it lines up with a tile or a board square.'


func get_display_name() -> String:
	return 'Snap To Grid'


func get_icon() -> String:
	return 'grid-3x3'


func get_target_classes() -> Array[StringName]:
	return [&'Node2D', &'Node3D']


func get_inputs() -> Array[Dictionary]:
	return [
		node_ref_input('The node to snap. Leave it empty to snap this node.'),
		{
			name = 'Cell Size',
			type = 'float',
			id = &'cell',
			doc = 'How wide one grid cell is, in pixels for a 2D node and in units for a 3D one.',
			default_value = 32.0
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
	if targets(&'Node3D'):
		return '{{ref}}.position = {{ref}}.position.snapped(Vector3.ONE * {{cell}})'

	return '{{ref}}.position = {{ref}}.position.snapped(Vector2.ONE * {{cell}})'
