@tool
class_name HenActionGetCell extends HenScriptMacroBase


func get_id() -> StringName:
	return &'get_cell'


func get_description() -> String:
	return 'Reads one cell of a TileMapLayer and stores the id of the tile source filling it, or -1 when the cell is empty. With Cell = Vector2i(3, 5) over a floor tile it stores 0, and over a hole it stores -1.'


func get_display_name() -> String:
	return 'Get Cell'


func get_icon() -> String:
	return 'search'


func get_default_phase() -> StringName:
	return &'update'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Layer',
			type = 'Node',
			id = &'layer',
			doc = 'The TileMapLayer to read from.',
			bind_only = true,
			default_value = null
		},
		{
			name = 'Cell',
			type = 'Vector2i',
			id = &'cell',
			doc = 'The cell to read, in tiles, where Vector2i(1, 0) is one tile to the right.',
			default_value = Vector2i.ZERO
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{
			name = 'Source',
			type = 'int',
			id = &'result',
			doc = 'Where to store the source id found in the cell, or -1 when it is empty.'
		}
	]


func get_output_result() -> String:
	if any_flow_connected():
		return 'source_{{VCNODE_ID}}'

	return '{{layer}}.get_cell_source_id({{cell}})'


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'}
	]


func get_flow_outputs() -> Array[Dictionary]:
	return [
		{
			name = 'Filled',
			id = &'filled',
			optional = true,
			doc = 'Where to go when a tile sits in the cell.'
		},
		{
			name = 'Empty',
			id = &'empty',
			optional = true,
			doc = 'Where to go when the cell holds no tile, which is when -1 is stored.'
		}
	]


func get_flow_enter() -> String:
	return _body()


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


func _body() -> String:
	if not any_flow_connected():
		return '{{out:result}}'

	return 'var source_{{VCNODE_ID}} = {{layer}}.get_cell_source_id({{cell}})\n' \
		+ '{{out:result}}\n' \
		+ 'if source_{{VCNODE_ID}} != -1:\n' \
		+ '\t{{filled}}\n' \
		+ 'else:\n' \
		+ '\t{{empty}}'
