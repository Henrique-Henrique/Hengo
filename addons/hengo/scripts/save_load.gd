@tool
class_name HenSaveLoad extends Node

# ---------------------------------------------------------------------------- #
#                                    saving                                    #
# ---------------------------------------------------------------------------- #

static func save(_code: String, _debug_symbols: Dictionary) -> void:
	var script_data: Dictionary = {
		type = HenGlobal.script_config.type,
		node_counter = HenGlobal.node_counter,
		debug_symbols = _debug_symbols,
		state_name_counter = HenState._name_counter
	}

	# ---------------------------------------------------------------------------- #
	# Props
	script_data['props'] = HenGlobal.PROPS_CONTAINER.get_all_values()

	# ---------------------------------------------------------------------------- #
	# Generals
	var generals: Array[Dictionary] = []

	for general in HenGlobal.GENERAL_CONTAINER.get_children():
		var data: Dictionary = general.custom_data

		data.pos = var_to_str(general.position)
		data.id = general.id

		for cnode in general.virtual_cnode_list:
			data.cnode_list = get_cnode_list(HenRouter.route_reference[general.route.id])

		generals.append(data)

	script_data['generals'] = generals

	# ---------------------------------------------------------------------------- #
	# STATES
	var states: Array[Dictionary] = []

	for state in HenGlobal.STATE_CONTAINER.get_children():
		var data: Dictionary = {
			id = state.hash,
			name = state.get_state_name(),
			pos = var_to_str(state.position),
			cnode_list = get_cnode_list(HenRouter.route_reference[state.route.id]),
			events = [],
			transitions = []
		}

		var state_route = state.route.duplicate()
		state_route.erase('state_ref')

		data['route'] = state_route

		# ---------------------------------------------------------------------------- #
		# transitions
		for trans in state.get_node('%TransitionContainer').get_children():
			var trans_data = {
				name = trans.get_transition_name()
			}

			if trans.line:
				trans_data['to_state_id'] = trans.line.to_state.hash

			data['transitions'].append(trans_data)

		var event_container = state.get_node('%EventContainer')

		if event_container.get_child_count() > 0:
			var event_list := event_container.get_child(0).get_node('%EventList')

			for event in event_list.get_children():
				data['events'].append(event.get_meta('config'))

		states.append(data)

	script_data['states'] = states

	# ---------------------------------------------------------------------------- #
	# CONNECTIONS
	var connections: Array[Dictionary] = []
	var flow_connections: Array[Dictionary] = []

	for line in HenRouter.line_route_reference.values().reduce(func(acc, c): return acc + c):
		if line is HenConnectionLine:
			connections.append({
				from_cnode = line.from_cnode.hash,
				to_cnode = line.to_cnode.hash,
				input = line.input.owner.get_index(),
				output = line.output.owner.get_index()
			})
		# its flow connection
		else:
			flow_connections.append({
				from_cnode = line.from_connector.root.hash,
				from_connector = line.from_connector.get_index(),
				to_cnode = line.to_cnode.hash
			})

	script_data['connections'] = connections
	script_data['flow_connections'] = flow_connections


	# ---------------------------------------------------------------------------- #
	# ---------------------------------------------------------------------------- #
	# ---------------------------------------------------------------------------- #
	# ---------------------------------------------------------------------------- #
	# Funcions
	var func_list: Array[Dictionary] = []

	for func_item in HenGlobal.ROUTE_REFERENCE_CONTAINER.get_children().filter(func(x): return x.type == StringName('func')):
		func_list.append({
			hash = func_item.hash,
			props = func_item.props,
			ref_count = func_item.ref_count,
			cnode_list = get_cnode_list(HenRouter.route_reference[func_item.route.id]),
			pos = var_to_str(func_item.position)
		})

	script_data['func_list'] = func_list

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

	script_data['comments'] = comment_list


	# ---------------------------------------------------------------------------- #
	var code = '#[hengo] ' + JSON.stringify(script_data) + '\n\n' + _code
	var script: GDScript = GDScript.new()

	print(code)

	script.source_code = code

	var reload_err: int = script.reload()

	if reload_err == OK:
		var err: int = ResourceSaver.save(script, HenGlobal.current_script_path)

		if err == OK:
			print('SAVED HENGO SCRIPT')
	else:
		pass

#
#
#
#
#
#
#
#
#
#
#
# ---------------------------------------------------------------------------- #
static func get_cnode_list(_cnode_list: Array, _ignore_list: Array = []) -> Array:
	var arr: Array = []

	for cnode in _cnode_list:
		# ignore cnode types
		if _ignore_list.has(cnode.type):
			continue

		var cnode_data: Dictionary = {
			# id = cnode.get_instance_id(),
			pos = var_to_str(cnode.position),
			name = cnode.get_cnode_name(),
			sub_type = cnode.type,
			hash = cnode.hash,
			inputs = [],
			outputs = []
		}

		var fantasy_name: String = cnode.get_fantasy_name()

		if cnode_data.name != fantasy_name:
			cnode_data['fantasy_name'] = fantasy_name

		if cnode.cnode_type != 'default':
			cnode_data['type'] = cnode.cnode_type

		for input in cnode.get_node('%InputContainer').get_children():
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

		for output in cnode.get_node('%OutputContainer').get_children():
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

			match cnode.type:
				'var':
					output_data['group_idx'] = int(output.custom_data)

			cnode_data.outputs.append(output_data)

		if cnode.category:
			cnode_data['category'] = cnode.category

		match cnode.type:
			'expression':
				cnode_data['exp'] = cnode.get_node('%Container').get_child(1).get_child(0).raw_text
			'user_func', 'func_input', 'func_output':
				for group_name: String in HenGlobal.GROUP.get_group_list(cnode):
					if group_name.begins_with('f_'):
						cnode_data['group'] = group_name
					

		arr.append(cnode_data)

	return arr

# ---------------------------------------------------------------------------- #

static func _get_cnode_route_instance(_cnode: HenCnode) -> Dictionary:
	var cnode_data: Dictionary = {
		id = _cnode.get_instance_id(),
		pos = var_to_str(_cnode.position),
		route_inst_id = get_inst_id_by_route(_cnode.route_ref),
		sub_type = _cnode.type,
		hash = _cnode.hash
	}

	var in_prop_values: Dictionary = {}
	
	for input in _cnode.get_node('%InputContainer').get_children():
		var cname_input = input.get_node('%CNameInput')

		if cname_input.get_child_count() > 2:
			var in_prop = cname_input.get_child(2)

			if in_prop is not Label:
				in_prop_values[input.get_index()] = in_prop.get_generated_code()

	if not in_prop_values.is_empty():
		cnode_data['in_prop_data'] = in_prop_values

	return cnode_data

# ---------------------------------------------------------------------------- #

static func _load_cnode(_cnode_list: Array, _route, _inst_id_refs) -> void:
	for cnode: Dictionary in _cnode_list:
		var cnode_data: Dictionary = {
			pos = cnode.pos,
			name = cnode.name,
			sub_type = cnode.sub_type,
			inputs = cnode.inputs,
			outputs = cnode.outputs,
			hash = cnode.hash,
			route = _route,
		}

		if cnode.has('fantasy_name'):
			cnode_data['fantasy_name'] = cnode.get('fantasy_name')

		if cnode.has('type'):
			cnode_data['type'] = cnode.type

		if cnode.has('category'):
			cnode_data['category'] = cnode.get('category')

		if cnode.has('exp'):
			cnode_data['exp'] = cnode.get('exp')

		if cnode.has('group'):
			cnode_data['group'] = cnode.group
		
		var cnode_inst = HenCnode.instantiate_cnode(cnode_data)

		_inst_id_refs[cnode.hash] = cnode_inst

# ---------------------------------------------------------------------------- #
#                                 load and edit                                #
# ---------------------------------------------------------------------------- #

static func load_and_edit(_path: StringName) -> void:
	# ---------------------------------------------------------------------------- #
	# remove start message
	var state_msg: PanelContainer = HenGlobal.STATE_CAM.get_parent().get_node_or_null('StartMessage')
	var cnode_msg: PanelContainer = HenGlobal.CNODE_CAM.get_parent().get_node_or_null('StartMessage')
	var compile_bt: Button = HenGlobal.STATE_CAM.get_parent().get_node('%Compile')

	if state_msg:
		state_msg.get_parent().remove_child(state_msg)
	
	if cnode_msg:
		cnode_msg.get_parent().remove_child(cnode_msg)

	compile_bt.disabled = false

	# reseting plugin
	# HenGlobal.ERROR_BT.reset()

	for state in HenGlobal.STATE_CONTAINER.get_children():
		state.queue_free()

	for state in HenGlobal.GENERAL_CONTAINER.get_children():
		state.queue_free()

	for state in HenGlobal.ROUTE_REFERENCE_CONTAINER.get_children():
		state.queue_free()
	
	for cnode in HenGlobal.CNODE_CONTAINER.get_children():
		cnode.queue_free()

	for cnode in HenGlobal.COMMENT_CONTAINER.get_children():
		cnode.queue_free()
	
	for cnode_line in HenGlobal.CNODE_CAM.get_node('Lines').get_children():
		cnode_line.queue_free()
	
	for state_line in HenGlobal.STATE_CAM.get_node('Lines').get_children():
		state_line.queue_free()

	for prop in HenGlobal.PROPS_CONTAINER.get_node('%List').get_children():
		prop.queue_free()

	HenGlobal.GROUP.group.clear()

	# ---------------------------------------------------------------------------- #
	# setting other scripts config
	var dir: DirAccess = DirAccess.open('res://hengo')
	HenGlobal.SCRIPTS_INFO = []
	parse_other_scripts_data(dir)

	# ---------------------------------------------------------------------------- #

	# confirming queue free before check errors
	await HenGlobal.CNODE_CAM.get_tree().process_frame

	HenGlobal.current_script_path = _path
	HenRouter.current_route = {}
	HenRouter.route_reference = {}
	HenRouter.line_route_reference = {}
	HenRouter.comment_reference = {}
	HenGlobal.history = UndoRedo.new()

	var script: GDScript = ResourceLoader.load(_path, '', ResourceLoader.CACHE_MODE_IGNORE)

	if script.source_code.begins_with('extends '):
		# setting script type
		var type: String = script.source_code.split('\n').slice(0, 1)[0].split(' ')[1]
	
		HenGlobal.script_config['type'] = type
		HenGlobal.node_counter = 0
		HenState._name_counter = 0

		if ClassDB.is_parent_class(type, 'Node'):
			var spacing: Vector2 = Vector2(-150, -200)

			# creating inputs
			for general_data in [
				{
					name = 'Input',
					cnode_name = '_input',
				},
				# {
				#     name = 'Shortcut Input',
				#     cnode_name = '_shortcut_input',
				#     color = '#1e3033'
				# },
				# {
				#     name = 'Unhandled Input',
				#     cnode_name = '_unhandled_input',
				#     color = '#352b19'
				# },
				# {
				#     name = 'Unhandled Key Input',
				#     cnode_name = '_unhandled_key_input',
				#     color = '#44201e'
				# },
				{
					name = 'Process',
					cnode_name = '_process',
					color = '#401d3f',
					param = {
						name = 'delta',
						type = 'float'
					}
				},
				{
					name = 'Physics Process',
					cnode_name = '_physics_process',
					color = '#1f2950',
					param = {
						name = 'delta',
						type = 'float'
					}
				},
			]:
				var data: Dictionary = {
					route = {
						name = general_data.name,
						type = HenRouter.ROUTE_TYPE.INPUT,
						id = HenUtilsName.get_unique_name()
					},
					custom_data = general_data,
					type = 'input',
					icon = 'res://addons/hengo/assets/icons/mouse.svg'
				}

				if general_data.has('color'):
					data.color = general_data.color

				var general := HenGeneralRoute.instantiate_general(data)

				general.position = spacing + Vector2(30, 0)

				HenCnode.instantiate_and_add({
					name = general_data.cnode_name,
					sub_type = 'virtual',
					outputs = [ {
						name = 'event',
						type = 'InputEvent'
					} if not general_data.has('param') else general_data.param],
					route = general.route,
					position = Vector2.ZERO
				})

				spacing = Vector2(general.position.x + general.size.x, general.position.y)

		# It's a new project
		var state := HenState.instantiate_and_add_to_scene()
		state.add_event({
			name = 'Start',
			type = 'start'
		})

		state.select()

	#   
	#
	# loading hengo script data
	elif script.source_code.begins_with('#[hengo] '):
		var data: Dictionary = parse_hengo_json(script.source_code)

		var inst_id_refs: Dictionary = {}
		var state_trans_connections: Array = []
	
		# setting script configs
		HenGlobal.script_config['type'] = data.type
		HenGlobal.node_counter = data.node_counter
		HenGlobal.current_script_debug_symbols = data.debug_symbols
		HenState._name_counter = data.state_name_counter

		# generating generals (like inputs)
		for general_config: Dictionary in data['generals']:
			var dt: Dictionary = general_config.duplicate()

			dt.route = {
				name = general_config.name,
				type = HenRouter.ROUTE_TYPE.INPUT,
				id = HenUtilsName.get_unique_name()
			}

			dt.type = 'input'
			dt.icon = 'res://addons/hengo/assets/icons/mouse.svg'
			dt.custom_data = general_config

			var general := HenGeneralRoute.instantiate_general(dt)

			_load_cnode(general_config.cnode_list, general.route, inst_id_refs)

			inst_id_refs[float(general.id)] = general
		
		# functions
		for func_config: Dictionary in data['func_list']:
			var dt: Dictionary = {
				hash = func_config.hash,
				props = func_config.props,
				name = 'Function Name',
				pos = func_config.pos,
				type = 'func',
				route = {
					name = '',
					type = HenRouter.ROUTE_TYPE.FUNC,
					id = HenUtilsName.get_unique_name()
				},
			}

			var func_ref = HenRouteReference.instantiate_and_add(dt)

			func_ref.set_ref_count(func_config.ref_count)

			_load_cnode(func_config.cnode_list, func_ref.route, inst_id_refs)
			
			inst_id_refs[float(func_ref.hash)] = func_ref
		
		# states
		for state: Dictionary in data['states']:
			var state_inst = HenState.instantiate_and_add_to_scene({
				name = state.name,
				pos = state.pos,
				hash = state.id
			})

			# transition
			for trans: Dictionary in state['transitions']:
				var trans_inst = state_inst.add_transition(trans.name)

				if trans.has('to_state_id'):
					state_trans_connections.append({
						to_state_id = trans.get('to_state_id'),
						ref = trans_inst
					})

			# cnodes
			_load_cnode(state.cnode_list, state_inst.route, inst_id_refs)
			
			for event_config: Dictionary in state['events']:
				state_inst.add_event(event_config)
			
			inst_id_refs[state.id] = state_inst

		# creating state transitions connection
		for trans_config: Dictionary in state_trans_connections:
			trans_config.ref.add_connection({
				state_from = inst_id_refs[trans_config.to_state_id]
			})

		# creating props
		print(data['props'])
		for prop: Dictionary in data['props']:
			match prop.prop_type:
				StringName('VARIABLE'):
					var prop_scene = load('res://addons/hengo/scenes/prop_variable.tscn').instantiate()
					HenGlobal.PROPS_CONTAINER.get_node('%List').add_child(prop_scene)
					prop_scene.set_value(prop)

		# ---------------------------------------------------------------------------- #
		# creating comments
		var comment_scene = load('res://addons/hengo/scenes/utils/comment.tscn')
		for comment_config: Dictionary in data['comments']:
			var comment = comment_scene.instantiate()
			var router = inst_id_refs[comment_config.router_ref_id].route_ref

			comment.route_ref = router
			HenRouter.comment_reference[router.id].append(comment)

			comment.is_pinned = comment_config.is_pinned
			comment.position = str_to_var(comment_config.pos)
			comment.size = str_to_var(comment_config.size)
			comment.cnode_inside = comment_config.cnode_inside_ids.map(
				func(x: int) -> Variant:
					return inst_id_refs[float(x)]
			)
			HenGlobal.COMMENT_CONTAINER.add_child(comment)
			comment.check_pin.button_pressed = comment_config.is_pinned
			comment._on_color(str_to_var(comment_config.color as String) as Color)
			comment.get_node('%ColorButton').color = str_to_var(comment_config.color as String) as Color
			comment.set_comment(comment_config.comment)

		# ---------------------------------------------------------------------------- #
		# creating connections
		for connection: Dictionary in data['connections']:
			var from_in_out = (inst_id_refs[connection.from_cnode] as HenCnode).get_node('%OutputContainer').get_child(connection.input)
			var to_cnode = (inst_id_refs[connection.to_cnode] as HenCnode)
			var to_in_out

			match to_cnode.type:
				'if':
					to_in_out = to_cnode.get_node('%TitleContainer').get_child(0).get_child(connection.output)
				_:
					to_in_out = to_cnode.get_node('%InputContainer').get_child(connection.output)

			from_in_out.create_connection_and_instance({
				from = to_in_out,
				type = to_in_out.type,
				conn_type = to_in_out.connection_type,
			})
		
		# flow connections
		for flow_connection: Dictionary in data['flow_connections']:
			var cnode = inst_id_refs[flow_connection.from_cnode] as HenCnode

			match cnode.cnode_type:
				'default':
					var connector = cnode.get_node('%Container').get_children()[-1].get_child(0)

					connector.create_connection_line_and_instance({
						from_cnode = (inst_id_refs[flow_connection.to_cnode] as HenCnode)
					})
				'if':
					var connector = cnode.get_node('%Container').get_child(2).get_node('%FlowContainer').get_child(flow_connection.from_connector)
					
					connector.create_connection_line_and_instance({
						from_cnode = (inst_id_refs[flow_connection.to_cnode] as HenCnode)
					})

		HenRouter.change_route(HenGlobal.start_state.route)

		# folding comments after add to scene
		for comment in HenGlobal.COMMENT_CONTAINER.get_children():
			comment.pin_to_cnodes(true)

	# checking errors
	for state: HenState in HenGlobal.STATE_CONTAINER.get_children():
		HenCodeGeneration.check_state_errors(state)

	# checking if debugging
	# change debugger script path
	if HenGlobal.HENGO_DEBUGGER_PLUGIN:
		HenGlobal.HENGO_DEBUGGER_PLUGIN.reload_script()
	
	# showing current type
	show_class_name()


static func get_inst_id_by_route(_route: Dictionary) -> int:
	if _route.has('state_ref'):
		return _route.state_ref.hash
	elif _route.has('item_ref'):
		return _route.item_ref.get_instance_id()
	elif _route.has('general_ref'):
		return _route.general_ref.id

	return -1


static func parse_hengo_json(_source: String) -> Dictionary:
	var hengo_json: String = _source.split('\n').slice(0, 1)[0].split('#[hengo] ')[1]
	return JSON.parse_string(hengo_json)


static func parse_other_scripts_data(_dir: DirAccess) -> void:
	_dir.list_dir_begin()

	var file_name: String = _dir.get_next()

	# TODO cache script that don't changed
	while file_name != '':
		if _dir.current_is_dir():
			parse_other_scripts_data(DirAccess.open('res://hengo/' + file_name))
		else:
			var script: GDScript = ResourceLoader.load(_dir.get_current_dir() + '/' + file_name, '', ResourceLoader.CACHE_MODE_IGNORE)

			if script.source_code.begins_with('#[hengo] '):
				var data: Dictionary = parse_hengo_json(script.source_code)

				HenGlobal.SCRIPTS_STATES[file_name.get_basename()] = []

				for state_dict: Dictionary in data['states'] as Array:
					(HenGlobal.SCRIPTS_STATES[file_name.get_basename()] as Array).append({name = state_dict.name})
				
				HenGlobal.SCRIPTS_INFO.append({
					name = 'Go to \'' + file_name.get_basename() + '\' state',
					data = {
						name = 'go_to_event',
						fantasy_name = 'Go to \'' + file_name.get_basename() + '\' state',
						sub_type = 'go_to_void',
						inputs = [
							{
								name = 'hengo',
								type = 'Node',
							},
							{
								name = 'state',
								sub_type = '@dropdown',
								category = 'hengo_states',
								data = file_name.get_basename()
							}
						]
					}
				})
		
		file_name = _dir.get_next()

	_dir.list_dir_end()


static func script_has_state(_script_name: String, _state_name: String) -> bool:
	var has_state: bool = false

	var script: GDScript = ResourceLoader.load('res://hengo/' + _script_name + '.gd', '', ResourceLoader.CACHE_MODE_IGNORE)

	if script.source_code.begins_with('#[hengo] '):
		var data: Dictionary = parse_hengo_json(script.source_code)
	
		return data['states'].map(func(x: Dictionary) -> String: return x.name.to_lower()).has(_state_name)
	
	return has_state


static func show_class_name() -> void:
	var cl_label: Label = HenGlobal.HENGO_ROOT.get_node('%ClassName')
	var type = HenGlobal.script_config['type']
	var sb: StyleBoxFlat = cl_label.get_theme_stylebox('normal')

	cl_label.visible = true
	cl_label.text = type

	if ClassDB.is_parent_class(type, 'Node2D'):
		sb.bg_color = Color('#6E90E7', .2)
	elif ClassDB.is_parent_class(type, 'Node3D'):
		sb.bg_color = Color('#E96266', .2)
	elif ClassDB.is_parent_class(type, 'Control'):
		sb.bg_color = Color('#67DE7A', .2)
	elif ClassDB.is_parent_class(type, 'AnimationMixer'):
		sb.bg_color = Color('#AC76E5', .2)
	else:
		sb.bg_color = Color('#0000004a')
