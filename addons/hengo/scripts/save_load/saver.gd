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

	for v_cnode: HenVirtualCNode in HenGlobal.vc_list.get(HenGlobal.BASE_ROUTE.id):
		v_cnode_list.append(v_cnode.get_save())
			
	script_data.virtual_cnode_list = v_cnode_list


	# getting data from cnodes
	for v_cnode_arr: Array in HenGlobal.vc_list.values():
		for v_cnode: HenVirtualCNode in v_cnode_arr:
			if v_cnode.type == HenVirtualCNode.Type.STATE_EVENT:
				script_data.state_event_list.append(v_cnode.name)

	# ---------------------------------------------------------------------------- #
	# ---------------------------------------------------------------------------- #
	# ---------------------------------------------------------------------------- #
	# ---------------------------------------------------------------------------- #
	# Funcions
	# var func_list: Array[Dictionary] = []

	# for func_item in HenGlobal.ROUTE_REFERENCE_CONTAINER.get_children().filter(func(x: HenRouteReference): return x.type == HenRouteReference.TYPE.FUNC):
	# 	func_list.append({
	# 		hash = func_item.hash,
	# 		props = func_item.props,
	# 		ref_count = func_item.ref_count,
	# 		cnode_list = get_cnode_list(HenRouter.route_reference[func_item.route.id]),
	# 		pos = var_to_str(func_item.position)
	# 	})

	# script_data.func_list = func_list

	# ---------------------------------------------------------------------------- #
	# loading comments
	var comment_list: Array[Dictionary] = []
	var comment_node_list: Array = []

	for c_arr in HenRouter.comment_reference.values():
		comment_node_list += c_arr

	for comment in comment_node_list:
		comment_list.append({
			id = comment.get_instance_id(),
			is_pinned = comment.is_pinned,
			comment = comment.get_comment(),
			# getting the first cnode of router that comment are in (this is needed to get router ref later)
			router_ref_id = HenRouter.route_reference[comment.route_ref.id][0].hash,
			color = var_to_str(comment.get_color()),
			pos = var_to_str(comment.position),
			size = var_to_str(comment.size),
			cnode_inside_ids = comment.cnode_inside.map(
				func(x: HenCnode) -> int:
					return x.hash
		)
		})

	script_data.comments = comment_list

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
