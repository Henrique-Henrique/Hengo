@tool
class_name HenActionEraseCell extends HenScriptMacroBase


func get_id() -> StringName:
	return &'erase_cell'


func get_description() -> String:
	return 'Clears one cell of a TileMapLayer, leaving a hole where the tile was. With Cell = Vector2i(3, 5), that tile disappears and Get Cell then reads -1 there.'


func get_display_name() -> String:
	return 'Erase Cell'


func get_icon() -> String:
	return 'trash-2'


func get_default_phase() -> StringName:
	return &'enter'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Layer',
			type = 'Node',
			id = &'layer',
			doc = 'The TileMapLayer to erase from.',
			bind_only = true,
			default_value = null
		},
		{
			name = 'Cell',
			type = 'Vector2i',
			id = &'cell',
			doc = 'The cell to clear, in tiles, where Vector2i(1, 0) is one tile to the right.',
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
	return '{{layer}}.erase_cell({{cell}})'
