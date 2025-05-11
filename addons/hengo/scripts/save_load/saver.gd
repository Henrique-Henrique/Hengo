@tool
class_name HenSaver extends Node


static func save(_code: String, _debug_symbols: Dictionary) -> void:
	# check if save dierctory exists
	if not DirAccess.dir_exists_absolute('res://hengo'):
		DirAccess.make_dir_absolute('res://hengo')

	if not DirAccess.dir_exists_absolute('res://hengo/save'):
		DirAccess.make_dir_absolute('res://hengo/save')
	
	var script_data: HenScriptData = HenScriptData.new()

	script_data.type = HenGlobal.script_config.type
	script_data.node_counter = HenGlobal.node_counter
	script_data.prop_counter = HenGlobal.prop_counter
	script_data.debug_symbols = _debug_symbols

	# ---------------------------------------------------------------------------- #
	# Side Bar List
	script_data.side_bar_list = HenGlobal.SIDE_BAR_LIST.get_save()

	# ---------------------------------------------------------------------------- #
	var v_cnode_list: Array[Dictionary] = []

	for v_cnode: HenVirtualCNode in HenGlobal.BASE_ROUTE.ref.virtual_cnode_list:
		v_cnode_list.append(v_cnode.get_save())

		if v_cnode.type == HenVirtualCNode.Type.STATE_EVENT:
			script_data.state_event_list.append(v_cnode.name)
			
	script_data.virtual_cnode_list = v_cnode_list

	var script_name: String = HenGlobal.script_config.name if HenGlobal.script_config.has('name') else str(Time.get_ticks_usec())
	var data_path: StringName = 'res://hengo/save/' + script_name + '.res'
	var script_path: StringName = 'res://hengo/' + script_name + '.gd'

	# saving data
	var error: int = ResourceSaver.save(script_data, data_path)

	if error != OK:
		printerr('Error saving script data.')

	# ---------------------------------------------------------------------------- #
	var script: GDScript = GDScript.new()

	script.source_code = '#[hengo] ' + data_path + '\n\n' + _code

	var reload_err: int = script.reload()

	if reload_err == OK:
		var err: int = ResourceSaver.save(script, script_path)

		if err == OK:
			var dict_data: Dictionary = {
				name = script_name,
				path = script_path,
				type = script_data.type,
				data_path = data_path
			}
			HenEnums.SCRIPT_LIST_DATA[dict_data.path] = dict_data
			print('SAVED HENGO SCRIPT')
	else:
		pass
