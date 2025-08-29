@tool
class_name HenMapObjects extends RefCounted

static var objects: Dictionary = {}


static func map_script_data(_id: StringName, _script_data: HenScriptData) -> void:
	objects[_id] = {
		type = _script_data.type,
		var_list = _script_data.side_bar_list.var_list,
		func_list = [],
		signal_list = _script_data.side_bar_list.signal_list,
	}
	
	for func_data: Dictionary in _script_data.side_bar_list.func_list:
		func_data.erase('virtual_cnode_list')
		(objects[_id].func_list as Array).append(func_data)