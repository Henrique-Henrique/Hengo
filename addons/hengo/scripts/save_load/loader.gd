@tool
class_name HenLoader extends Node


static var loaded_virtual_cnode_list: Dictionary = {}
static var connection_list: Array = []
static var flow_connection_list: Array = []
static var from_flow_list: Array = []


class BaseRouteRef:
	var virtual_cnode_list: Array = []

static func load(_path: StringName) -> void:
	var start: int = Time.get_ticks_usec()

	var compile_bt: Button = HenGlobal.CAM.get_parent().get_node('%Compile')
	compile_bt.disabled = false
	# ---------------------------------------------------------------------------- #
	loaded_virtual_cnode_list.clear()
	connection_list.clear()
	flow_connection_list.clear()
	from_flow_list.clear()

	var cnode_msg: PanelContainer = HenGlobal.CAM.get_parent().get_node_or_null('StartMessage')
	
	if cnode_msg:
		cnode_msg.get_parent().remove_child(cnode_msg)

	for cnode in HenGlobal.COMMENT_CONTAINER.get_children():
		cnode.queue_free()


	HenGlobal.vs_list.clear()
	HenGlobal.SIDE_BAR_LIST.clear()
	HenGlobal.SIDE_BAR_LIST_CACHE.clear()

	# hide all virtuals
	for cnode: HenCnode in HenGlobal.cnode_pool:
		for signal_data: Dictionary in cnode.get_signal_connection_list('on_move'):
			cnode.disconnect('on_move', signal_data.callable)

		cnode.visible = false

	for connection: HenConnectionLine in HenGlobal.connection_line_pool:
		connection.visible = false

	for flow_connection: HenFlowConnectionLine in HenGlobal.flow_connection_line_pool:
		flow_connection.visible = false

	# ---------------------------------------------------------------------------- #

	# confirming queue free before check errors
	await HenGlobal.CAM.get_tree().process_frame

	HenGlobal.current_script_path = _path
	HenRouter.current_route = {}
	HenRouter.line_route_reference = {}
	HenRouter.comment_reference = {}
	HenGlobal.history = UndoRedo.new()

	var script: GDScript = ResourceLoader.load(_path, '', ResourceLoader.CACHE_MODE_IGNORE)
	var base_route: Dictionary = {
		name = 'Base',
		type = HenRouter.ROUTE_TYPE.BASE,
		id = HenUtilsName.get_unique_name(),
		ref = BaseRouteRef.new()
	}

	HenGlobal.BASE_ROUTE = base_route
	HenGlobal.script_config.name = _path.get_file().get_basename()

	# create new graph
	if script.source_code.begins_with('extends '):
		# setting script type
		var type: String = script.source_code.split('\n').slice(0, 1)[0].split(' ')[1]

		HenGlobal.script_config.type = type
		HenGlobal.node_counter = 0

		HenVirtualCNode.instantiate_virtual_cnode({
			name = 'State',
			type = HenVirtualCNode.Type.STATE_START,
			sub_type = HenVirtualCNode.SubType.STATE_START,
			route = base_route,
			position = Vector2(0, 0)
		})

		HenRouter.current_route = base_route

	#   
	#
	# loading hengo script data
	elif script.source_code.begins_with('#[hengo] '):
		var data: HenSaver.ScriptData = parse_hengo_json(script.source_code)

		# setting script configs
		HenGlobal.script_config.type = data.type
		HenGlobal.node_counter = data.node_counter
		HenGlobal.prop_counter = data.prop_counter
		HenGlobal.current_script_debug_symbols = data.debug_symbols

		# loading side bar list
		HenGlobal.SIDE_BAR_LIST.load_save(data.side_bar_list)

		# loading v_cnodes
		_load_vc(data.virtual_cnode_list, base_route)

		# adding in/out connections
		for input_data: Dictionary in connection_list:
			(input_data.from as HenVirtualCNode).add_connection(
				input_data.idx,
				input_data.from_idx,
				(loaded_virtual_cnode_list[int(input_data.from_vc_id)] as HenVirtualCNode)
			)

		# adding flow connection
		for flow_data: Dictionary in flow_connection_list:
			(flow_data.from as HenVirtualCNode).add_flow_connection(flow_data.idx, flow_data.to_idx, loaded_virtual_cnode_list[int(flow_data.to_id)]).add()

	# checking if debugging
	# change debugger script path
	if HenGlobal.HENGO_DEBUGGER_PLUGIN:
		HenGlobal.HENGO_DEBUGGER_PLUGIN.reload_script()
	
	# showing current type
	show_class_name()
	HenRouter.change_route(HenGlobal.BASE_ROUTE)
	HenGlobal.SIDE_BAR._on_list_changed()

	# ---------------------------------------------------------------------------- #
	# setting other scripts config
	var dir: DirAccess = DirAccess.open('res://hengo')
	HenGlobal.SCRIPTS_INFO.clear()
	parse_other_scripts_data(dir)

	var end: int = Time.get_ticks_usec()
	print('LOADED SCRIPT IN ', (end - start) / 1000., 'ms')


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
	script_data.props = hengo_json.props
	script_data.generals = hengo_json.generals
	script_data.virtual_cnode_list = hengo_json.virtual_cnode_list
	script_data.connections = hengo_json.connections
	script_data.flow_connections = hengo_json.flow_connections
	script_data.func_list = hengo_json.func_list
	script_data.comments = hengo_json.comments
	script_data.state_event_list = hengo_json.state_event_list
	script_data.side_bar_list = hengo_json.side_bar_list

	return script_data


static func parse_other_scripts_data(_dir: DirAccess) -> void:
	if not _dir:
		printerr('Hengo dir not found!')
		return
	
	_dir.list_dir_begin()

	var file_name: String = _dir.get_next()

	# TODO cache script that don't changed
	while file_name != '':
		# not parse the current file
		if HenGlobal.script_config.name == file_name.get_basename() or file_name.get_extension() != 'gd':
			file_name = _dir.get_next()
			continue
		
		if _dir.current_is_dir():
			parse_other_scripts_data(DirAccess.open('res://hengo/' + file_name))
		else:
			# print("-> ", file_name, ' = ', HenGlobal.script_config.name)
			var script: GDScript = ResourceLoader.load(_dir.get_current_dir() + '/' + file_name, '', ResourceLoader.CACHE_MODE_IGNORE)

			if script.source_code.begins_with('#[hengo] '):
				var data: HenSaver.ScriptData = parse_hengo_json(script.source_code)

				var script_data: Dictionary = {
					name = file_name.get_basename(),
					type = data.type,
					state_event_list = data.state_event_list
				}

				HenGlobal.SCRIPTS_INFO[file_name.get_basename()] = script_data
		
		file_name = _dir.get_next()

	_dir.list_dir_end()


static func _load_vc(_cnode_list: Array, _route: Dictionary) -> Array:
	var vc_list: Array = []

	for _config: Dictionary in _cnode_list:
		_config.route = _route

		var vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode(_config)
		loaded_virtual_cnode_list[vc.id] = vc

		if _config.has('from_vc_id'):
			from_flow_list.append({
				from = vc,
				to_idx = int(_config.from_vc_id)
			})

		if _config.has('input_connections'):
			for input: Dictionary in _config.input_connections:
				input.from = vc
				connection_list.append(input)
		
		if _config.has('flow_connections'):
			var idx: int = 0
			for flow_connection: Dictionary in _config.flow_connections:
				flow_connection_list.append({
					idx = idx,
					from = vc,
					to_id = int(flow_connection.to_id),
					to_idx = flow_connection.to_idx
				})
				idx += 1
		
		# if has sub vcnodes (basically states and etc)
		if _config.has('virtual_cnode_list'):
			vc.virtual_cnode_list = _load_vc(_config.virtual_cnode_list, vc.route)

		vc_list.append(vc)

	return vc_list