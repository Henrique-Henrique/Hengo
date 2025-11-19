@tool
class_name HenScriptData extends RefCounted

var path: StringName
var type: String
var node_counter: int
var connections: Array
var flow_connections: Array
var virtual_cnode_list: Array
var state_event_list: Array
var side_bar_list: Dictionary
var deps: Array

const HENGO_EXT: StringName = '.hengo'

func get_save() -> Dictionary:
	return {
		path = path,
		type = type,
		node_counter = node_counter,
		connections = connections,
		flow_connections = flow_connections,
		virtual_cnode_list = virtual_cnode_list,
		state_event_list = state_event_list,
		side_bar_list = side_bar_list,
		deps = deps,
	}


static func load(_data: Dictionary) -> HenScriptData:
	var script_data: HenScriptData = HenScriptData.new()

	script_data.path = _data.path
	script_data.type = _data.type
	script_data.node_counter = _data.node_counter
	script_data.connections = _data.connections
	script_data.flow_connections = _data.flow_connections
	script_data.virtual_cnode_list = _data.virtual_cnode_list
	script_data.state_event_list = _data.state_event_list
	script_data.side_bar_list = _data.side_bar_list
	script_data.deps = _data.deps

	return script_data


static func load_from_file(_data_path: String) -> HenScriptData:
	if FileAccess.file_exists(_data_path):
		var file: FileAccess = FileAccess.open(_data_path, FileAccess.READ)
		var data: Dictionary = JSON.parse_string(file.get_as_text())
		file.close()


		return HenScriptData.load(data)
	else:
		return null


static func save(_script_data: HenScriptData, _data_path: String) -> bool:
	var file: FileAccess = FileAccess.open(_data_path, FileAccess.WRITE)

	if not file:
		return false

	file.store_string(JSON.stringify(_script_data.get_save()))
	file.close()

	return true


static func save_code(_script_data: HenScriptData, _script_id: int) -> void:
	if _script_id == -1:
		return
	
	var loader: HenLoader = Engine.get_singleton(&'Loader')
	var code: String = '#[hengo] ' + loader.get_data_path(_script_id) + '\n\n' + (Engine.get_singleton(&'CodeGeneration') as HenCodeGeneration).get_code(_script_data)

	var ref_file: FileAccess = FileAccess.open(ResourceUID.get_id_path(_script_id), FileAccess.WRITE)
	ref_file.store_string(code)
	ref_file.close()