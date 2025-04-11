@tool
class_name HenSaver extends Node


class ScriptData:
	var type: String
	var node_counter: int
	var prop_counter: int
	var debug_symbols: Dictionary
	var props: Array
	var generals: Array
	var connections: Array
	var flow_connections: Array
	var func_list: Array
	var comments: Array
	var virtual_cnode_list: Array
	var state_event_list: Array
	var side_bar_list: Dictionary

	func get_save() -> Dictionary:
		return {
			type = type,
			prop_counter = prop_counter,
			node_counter = node_counter,
			debug_symbols = debug_symbols,
			props = props,
			generals = generals,
			connections = connections,
			flow_connections = flow_connections,
			func_list = func_list,
			comments = comments,
			virtual_cnode_list = virtual_cnode_list,
			state_event_list = state_event_list,
			side_bar_list = side_bar_list
		}


static func save(_code: String, _debug_symbols: Dictionary) -> void:
	var script_data: ScriptData = ScriptData.new()

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

	print(JSON.stringify(script_data.get_save()))

	# ---------------------------------------------------------------------------- #
	var code = '#[hengo] ' + JSON.stringify(script_data.get_save()) + '\n\n' + _code
	var script: GDScript = GDScript.new()


	print(code)

	script.source_code = code

	var reload_err: int = script.reload()

	if reload_err == OK:
		var err: int = ResourceSaver.save(script, 'res://hengo/testing.gd')
		# var err: int = ResourceSaver.save(script, HenGlobal.current_script_path)

		if err == OK:
			print('SAVED HENGO SCRIPT')
	else:
		pass
