@tool
class_name HenActionPositionToCell extends HenScriptMacroBase


func get_id() -> StringName:
	return &'position_to_cell'


func get_description() -> String:
	return 'Turns a world position into the cell of a TileMapLayer that covers it and stores the coordinates. With 16 by 16 tiles, a position of Vector2(40, 8) stores Vector2i(2, 0).'


func get_display_name() -> String:
	return 'Position To Cell'


func get_icon() -> String:
	return 'locate-fixed'


func get_default_phase() -> StringName:
	return &'update'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Layer',
			type = 'Node',
			id = &'layer',
			doc = 'The TileMapLayer whose grid the position is measured against.',
			bind_only = true,
			default_value = null
		},
		{
			name = 'Position',
			type = 'Vector2',
			id = &'position',
			doc = 'A position in world space, such as the mouse position.',
			default_value = Vector2.ZERO
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{
			name = 'Cell',
			type = 'Vector2i',
			id = &'result',
			doc = 'Where to store the cell that covers the position, in tiles.'
		}
	]


func get_output_result() -> String:
	return '{{layer}}.local_to_map({{layer}}.to_local({{position}}))'


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'}
	]


func get_flow_enter() -> String:
	return _body()


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


func _body() -> String:
	return '{{out:result}}'
