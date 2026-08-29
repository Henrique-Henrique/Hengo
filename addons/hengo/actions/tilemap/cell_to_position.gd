@tool
class_name HenActionCellToPosition extends HenScriptMacroBase


func get_id() -> StringName:
	return &'cell_to_position'


func get_description() -> String:
	return 'Turns a cell of a TileMapLayer into the world position at its center and stores it. With 16 by 16 tiles, Cell = Vector2i(2, 0) stores Vector2(40, 8).'


func get_display_name() -> String:
	return 'Cell To Position'


func get_icon() -> String:
	return 'map-pin'


func get_default_phase() -> StringName:
	return &'update'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Layer',
			type = 'Node',
			id = &'layer',
			doc = 'The TileMapLayer whose grid the cell belongs to.',
			bind_only = true,
			default_value = null
		},
		{
			name = 'Cell',
			type = 'Vector2i',
			id = &'cell',
			doc = 'The cell to locate, in tiles, where Vector2i(1, 0) is one tile to the right.',
			default_value = Vector2i.ZERO
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{
			name = 'Position',
			type = 'Vector2',
			id = &'result',
			doc = 'Where to store the world position at the center of the cell.'
		}
	]


func get_output_result() -> String:
	return '{{layer}}.to_global({{layer}}.map_to_local({{cell}}))'


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
