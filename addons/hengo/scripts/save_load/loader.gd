@tool
class_name HenLoader extends Node

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

	# for state in HenGlobal.STATE_CONTAINER.get_children():
	# 	state.queue_free()

	for state in HenGlobal.GENERAL_CONTAINER.get_children():
		state.queue_free()

	for state in HenGlobal.ROUTE_REFERENCE_CONTAINER.get_children():
		state.queue_free()
	
	# for cnode: HenCnode in HenGlobal.CNODE_CONTAINER.get_children():
	# 	if cnode.is_pool:
	# 		continue
		
	# 	cnode.queue_free()

	for cnode in HenGlobal.COMMENT_CONTAINER.get_children():
		cnode.queue_free()
	
	# for cnode_line in HenGlobal.CNODE_CAM.get_node('Lines').get_children():
	# 	cnode_line.queue_free()
	
	for state_line in HenGlobal.STATE_CAM.get_node('Lines').get_children():
		state_line.queue_free()


	for prop in HenGlobal.PROPS_CONTAINER.get_node('%List').get_children():
		prop.queue_free()


	HenGlobal.GROUP.group.clear()
	HenGlobal.vc_list.clear()
	HenGlobal.vs_list.clear()

	# reset state pool
	for state in HenGlobal.state_pool:
		state.visible = false

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
					sub_type = HenCnode.SUB_TYPE.VIRTUAL,
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
		var data: HenSaver.ScriptData = parse_hengo_json(script.source_code)

		var inst_id_refs: Dictionary = {}
		var state_trans_connections: Array = []
	
		# setting script configs
		HenGlobal.script_config['type'] = data.type
		HenGlobal.node_counter = data.node_counter
		HenGlobal.prop_counter = data.prop_counter
		HenGlobal.current_script_debug_symbols = data.debug_symbols
		HenState._name_counter = data.state_name_counter

		# generating generals (like inputs)
		for general_config: Dictionary in data.generals:
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
		for func_config: Dictionary in data.func_list:
			var dt: Dictionary = {
				hash = func_config.hash,
				props = func_config.props,
				name = 'Function Name',
				pos = func_config.pos,
				type = HenCnode.SUB_TYPE.FUNC,
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
		for state: Dictionary in data.states:
			# var state_inst = HenState.instantiate_and_add_to_scene({
			# 	name = state.name,
			# 	pos = state.pos,
			# 	hash = state.id
			# })
			var v_state: HenVirtualState = HenVirtualState.instantiate_virtual_state(state)

			# transition
			for trans: Dictionary in state.transitions:
				v_state.add_transition(trans)

				# var trans_inst = state_inst.add_transition(trans.name)

			# 	if trans.has('to_state_id'):
			# 		state_trans_connections.append({
			# 			to_state_id = trans.get('to_state_id'),
			# 			ref = trans_inst
			# 		})

			# cnodes
			# _load_cnode(state.cnode_list, state_inst.route, inst_id_refs)
			_load_vc(state.cnode_list, v_state.route)

			# for event_config: Dictionary in state['events']:
			# 	state_inst.add_event(event_config)
			
			# inst_id_refs[state.id] = state_inst

		
		# creating state transitions connection
		# for trans_config: Dictionary in state_trans_connections:
		# 	trans_config.ref.add_connection({
		# 		state_from = inst_id_refs[trans_config.to_state_id]
		# 	})

		# creating props
		for prop: Dictionary in data.props:
			match prop.prop_type:
				StringName('VARIABLE'):
					var prop_scene = preload('res://addons/hengo/scenes/prop_variable.tscn').instantiate()
					HenGlobal.PROPS_CONTAINER.get_node('%List').add_child(prop_scene)
					prop_scene.set_value(prop)

		# ---------------------------------------------------------------------------- #
		# creating comments
		var comment_scene = preload('res://addons/hengo/scenes/utils/comment.tscn')
		for comment_config: Dictionary in data.comments:
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

		# # ---------------------------------------------------------------------------- #
		# # creating connections
		# for connection: Dictionary in data.connections:
		# 	var from_in_out = (inst_id_refs[connection.from_cnode] as HenCnode).get_node('%OutputContainer').get_child(connection.input)
		# 	var to_cnode = (inst_id_refs[connection.to_cnode] as HenCnode)
		# 	var to_in_out = to_cnode.get_node('%InputContainer').get_child(connection.output)

		# 	from_in_out.create_connection_and_instance({
		# 		from = to_in_out,
		# 		type = to_in_out.type,
		# 		conn_type = to_in_out.connection_type,
		# 	})
		
		# # flow connections
		# for flow_connection: Dictionary in data.flow_connections:
		# 	var cnode := inst_id_refs[flow_connection.from_cnode] as HenCnode

		# 	match cnode.type:
		# 		HenCnode.TYPE.DEFAULT:
		# 			var connector = cnode.get_node('%Container').get_children()[-1].get_child(0)

		# 			connector.create_connection_line_and_instance({
		# 				from_cnode = (inst_id_refs[flow_connection.to_cnode] as HenCnode)
		# 			})
		# 		HenCnode.TYPE.IF:
		# 			var connector = cnode.get_node('%Container').get_child(2).get_node('%FlowContainer').get_child(flow_connection.from_connector)
					
		# 			connector.create_connection_line_and_instance({
		# 				from_cnode = (inst_id_refs[flow_connection.to_cnode] as HenCnode)
		# 			})

		# HenRouter.change_route(HenGlobal.start_state.route)

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


static func parse_hengo_json(_source: String) -> HenSaver.ScriptData:
	var hengo_json: Dictionary = JSON.parse_string(_source.split('\n').slice(0, 1)[0].split('#[hengo] ')[1])
	var script_data := HenSaver.ScriptData.new()

	script_data.type = hengo_json.type
	script_data.node_counter = hengo_json.node_counter
	script_data.prop_counter = hengo_json.prop_counter
	script_data.debug_symbols = hengo_json.debug_symbols
	script_data.state_name_counter = hengo_json.state_name_counter
	script_data.props = hengo_json.props
	script_data.generals = hengo_json.generals
	script_data.states = hengo_json.states
	script_data.connections = hengo_json.connections
	script_data.flow_connections = hengo_json.flow_connections
	script_data.func_list = hengo_json.func_list
	script_data.comments = hengo_json.comments

	return script_data


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
				var data: HenSaver.ScriptData = parse_hengo_json(script.source_code)

				HenGlobal.SCRIPTS_STATES[file_name.get_basename()] = []

				for state_dict: Dictionary in data.states as Array:
					(HenGlobal.SCRIPTS_STATES[file_name.get_basename()] as Array).append({name = state_dict.name})
				
				HenGlobal.SCRIPTS_INFO.append({
					name = 'Go to \'' + file_name.get_basename() + '\' state',
					data = {
						name = 'go_to_event',
						fantasy_name = 'Go to \'' + file_name.get_basename() + '\' state',
						sub_type = HenCnode.SUB_TYPE.GO_TO_VOID,
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
		var data: HenSaver.ScriptData = parse_hengo_json(script.source_code)
	
		return data.states.map(func(x: Dictionary) -> String: return x.name.to_lower()).has(_state_name)
	
	return has_state


static func _load_vc(_cnode_list: Array, _route: Dictionary) -> void:
	for _config: Dictionary in _cnode_list:
		_config.route = _route
		HenVirtualCNode.instantiate_virtual_cnode(_config)