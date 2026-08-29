@tool
class_name HenActionSetCell extends HenScriptMacroBase


func get_id() -> StringName:
	return &'set_cell'


func get_description() -> String:
	return 'Paints a tile into one cell of a TileMapLayer. With Cell = Vector2i(3, 5), Source = 0 and Atlas = Vector2i(2, 0), the tile at column 2 row 0 of the first source fills that cell.'


func get_display_name() -> String:
	return 'Set Cell'


func get_icon() -> String:
	return 'square-plus'


func get_default_phase() -> StringName:
	return &'enter'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Layer',
			type = 'Node',
			id = &'layer',
			doc = 'The TileMapLayer to paint into.',
			bind_only = true,
			default_value = null
		},
		{
			name = 'Cell',
			type = 'Vector2i',
			id = &'cell',
			doc = 'The cell to paint, in tiles, where Vector2i(1, 0) is one tile to the right.',
			default_value = Vector2i.ZERO
		},
		{
			name = 'Source',
			type = 'int',
			id = &'source',
			doc = 'Which tile set source the tile comes from, where the first source is 0.',
			default_value = 0
		},
		{
			name = 'Atlas',
			type = 'Vector2i',
			id = &'atlas',
			doc = 'The column and row of the tile inside that source, such as Vector2i(2, 0).',
			default_value = Vector2i.ZERO
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
	return '{{layer}}.set_cell({{cell}}, {{source}}, {{atlas}})'
