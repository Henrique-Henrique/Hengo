@tool
class_name HenSaver extends Node


class ScriptData:
	var type: String
	var node_counter: int
	var prop_counter: int
	var debug_symbols: Dictionary
	var state_name_counter: int
	var props: Array
	var generals: Array
	var states: Array
	var connections: Array
	var flow_connections: Array
	var func_list: Array
	var comments: Array

	func get_save() -> Dictionary:
		return {
			type = type,
			prop_counter = prop_counter,
			node_counter = node_counter,
			debug_symbols = debug_symbols,
			state_name_counter = state_name_counter,
			props = props,
			generals = generals,
			states = states,
			connections = connections,
			flow_connections = flow_connections,
			func_list = func_list,
			comments = comments
		}


static func save(_code: String, _debug_symbols: Dictionary) -> void:
	var script_data: ScriptData = ScriptData.new()

	script_data.type = HenGlobal.script_config.type
	script_data.node_counter = HenGlobal.node_counter
	script_data.prop_counter = HenGlobal.prop_counter
	script_data.debug_symbols = _debug_symbols
	script_data.state_name_counter = HenState._name_counter

	# ---------------------------------------------------------------------------- #
	# Props
	script_data.props = HenGlobal.PROPS_CONTAINER.get_all_values()

	# ---------------------------------------------------------------------------- #
	# Generals
	var generals: Array[Dictionary] = []

	for general: HenGeneralRoute in HenGlobal.GENERAL_CONTAINER.get_children():
		var data: Dictionary = general.custom_data

		data.pos = var_to_str(general.position)
		data.id = general.id

		for cnode in general.virtual_cnode_list:
			data.cnode_list = get_cnode_list(HenRouter.route_reference[general.route.id])

		generals.append(data)

	script_data.generals = generals

	# ---------------------------------------------------------------------------- #
	# STATES
	var states: Array[Dictionary] = []

	for v_state: HenVirtualState in HenGlobal.vs_list:
		var data: Dictionary = {
			id = v_state.id,
			name = v_state.name,
			position = var_to_str(v_state.position),
			cnode_list = [],
			events = [],
			transitions = [],
		}

		# transitions
		for transition: HenVirtualState.TransitionData in v_state.transitions:
			data.transitions.append(transition.get_save())

		# cnodes
		if HenGlobal.vc_list.has(v_state.route.id):
			for v_cnode: HenVirtualCNode in HenGlobal.vc_list.get(v_state.route.id):
				data.cnode_list.append(v_cnode.get_save())

		states.append(data)

	# for state: HenState in HenGlobal.STATE_CONTAINER.get_children():
	# 	var data: Dictionary = {
	# 		id = state.hash,
	# 		name = state.get_state_name(),
	# 		pos = var_to_str(state.position),
	# 		cnode_list = get_cnode_list(HenRouter.route_reference[state.route.id]),
	# 		events = [],
	# 		transitions = []
	# 	}

	# 	var state_route = state.route.duplicate()
	# 	state_route.erase('state_ref')

	# 	data['route'] = state_route

	# 	# ---------------------------------------------------------------------------- #
	# 	# transitions
	# 	for trans: HenStateTransition in state.get_node('%TransitionContainer').get_children():
	# 		var trans_data = {
	# 			name = trans.get_transition_name()
	# 		}

	# 		if trans.line:
	# 			if not trans.line.deleted:
	# 				trans_data['to_state_id'] = trans.line.to_state.hash

	# 		data['transitions'].append(trans_data)

	# 	var event_container = state.get_node('%EventContainer')

	# 	if event_container.get_child_count() > 0:
	# 		var event_list := event_container.get_child(0).get_node('%EventList')

	# 		for event in event_list.get_children():
	# 			data['events'].append(event.get_meta('config'))

	# 	states.append(data)

	script_data.states = states

	# ---------------------------------------------------------------------------- #
	# CONNECTIONS
	# var connections: Array[Dictionary] = []
	# var flow_connections: Array[Dictionary] = []

	# for line in HenRouter.line_route_reference.values().reduce(func(acc, c): return acc + c):
	# 	if line is HenConnectionLine:
	# 		connections.append({
	# 			from_cnode = line.from_cnode.hash,
	# 			to_cnode = line.to_cnode.hash,
	# 			input = line.input.owner.get_index(),
	# 			output = line.output.owner.get_index()
	# 		})
	# 	# its flow connection
	# 	else:
	# 		flow_connections.append({
	# 			from_cnode = line.from_connector.root.hash,
	# 			from_connector = line.from_connector.get_index(),
	# 			to_cnode = line.to_cnode.hash
	# 		})

	# script_data.connections = connections
	# script_data.flow_connections = flow_connections


	# ---------------------------------------------------------------------------- #
	# ---------------------------------------------------------------------------- #
	# ---------------------------------------------------------------------------- #
	# ---------------------------------------------------------------------------- #
	# Funcions
	var func_list: Array[Dictionary] = []

	for func_item in HenGlobal.ROUTE_REFERENCE_CONTAINER.get_children().filter(func(x: HenRouteReference): return x.type == HenRouteReference.TYPE.FUNC):
		func_list.append({
			hash = func_item.hash,
			props = func_item.props,
			ref_count = func_item.ref_count,
			cnode_list = get_cnode_list(HenRouter.route_reference[func_item.route.id]),
			pos = var_to_str(func_item.position)
		})

	script_data.func_list = func_list

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


	# print(code)

	script.source_code = code

	var reload_err: int = script.reload()

	if reload_err == OK:
		var err: int = ResourceSaver.save(script, 'res://hengo/testing.gd')
		# var err: int = ResourceSaver.save(script, HenGlobal.current_script_path)

		if err == OK:
			print('SAVED HENGO SCRIPT')
	else:
		pass


static func get_cnode_list(_cnode_list: Array, _ignore_list: Array = []) -> Array:
	var arr: Array = []

	for cnode: HenCnode in _cnode_list:

		# ignore cnode types
		if _ignore_list.has(cnode.sub_type):
			continue

		var cnode_data: Dictionary = {
			pos = var_to_str(cnode.position),
			name = cnode.get_cnode_name(),
			sub_type = cnode.sub_type,
			hash = cnode.hash,
			inputs = [],
			outputs = []
		}

		var fantasy_name: String = cnode.get_fantasy_name()

		if cnode_data.name != fantasy_name:
			cnode_data['fantasy_name'] = fantasy_name

		if cnode.type != HenCnode.TYPE.DEFAULT:
			cnode_data.type = cnode.type

		for input: HenCnodeInOut in cnode.get_node('%InputContainer').get_children():
			var input_data: Dictionary = {
				name = input.get_in_out_name(),
				type = input.connection_type,
			}

			if input.is_ref:
				input_data['ref'] = true

			if input.category:
				if ['state_transition'].has(input.category):
					input_data['sub_type'] = '@dropdown'

				input_data['category'] = input.category

			if input.custom_data:
				input_data['data'] = input.custom_data

			var cname_input = input.get_node('%CNameInput')

			if cname_input.get_child_count() > 2:
				var in_prop = cname_input.get_child(2)

				if in_prop is not Label:
					if in_prop is HenDropdown:
						input_data.sub_type = '@dropdown'

						match in_prop.type:
							'all_props':
								input_data['is_prop'] = true
								input_data['prop_idx'] = in_prop.custom_value
					
					var value = in_prop.get_value()

					input_data['in_prop'] = value if [TYPE_STRING, TYPE_INT, TYPE_FLOAT, TYPE_BOOL].has(typeof(value)) else var_to_str(value)

			cnode_data.inputs.append(input_data)

		for output: HenCnodeInOut in cnode.get_node('%OutputContainer').get_children():
			var output_data: Dictionary = {
				name = output.get_in_out_name(),
				type = output.connection_type
			}

			if output.category:
				output_data['category'] = output.category
			
			if output.sub_type:
				output_data.sub_type = output.sub_type

			var cname_output = output.get_node('%CNameOutput')

			if cname_output.get_child_count() > 2:
				var out_prop = cname_output.get_child(0)

				if out_prop is not Label:
					output_data['out_prop'] = out_prop.get_value()

			match cnode.sub_type:
				HenCnode.SUB_TYPE.VAR:
					output_data['group_idx'] = int(output.custom_data)

			cnode_data.outputs.append(output_data)

		if cnode.category:
			cnode_data['category'] = cnode.category

		match cnode.sub_type:
			HenCnode.SUB_TYPE.EXPRESSION:
				cnode_data['exp'] = cnode.get_node('%Container').get_child(1).get_child(0).raw_text
			HenCnode.SUB_TYPE.USER_FUNC, HenCnode.SUB_TYPE.FUNC_INPUT, HenCnode.SUB_TYPE.FUNC_OUTPUT:
				for group_name: String in HenGlobal.GROUP.get_group_list(cnode):
					if group_name.begins_with('f_'):
						cnode_data['group'] = group_name
					

		arr.append(cnode_data)

	return arr
