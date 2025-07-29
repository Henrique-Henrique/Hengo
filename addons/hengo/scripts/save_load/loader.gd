@tool
class_name HenLoader extends Node


static var loaded_virtual_cnode_list: Dictionary = {}
static var connection_list: Array = []
static var flow_connection_list: Array = []
static var from_flow_list: Array = []
static var script_to_open_id: int = -1
static var script_to_open_reload_script_data: HenScriptData


class BaseRouteRef extends RefCounted:
	signal loaded_new_project

	var virtual_cnode_list: Array = []

	func _notification(what: int) -> void:
		if what == NOTIFICATION_PREDELETE:
			print('base route ref deleted')


static func load(_path: StringName) -> void:
	script_to_open_id = ResourceLoader.get_resource_uid(_path)
	HenGlobal.SIGNAL_BUS.scripts_generation_started.emit()

	if HenGlobal.script_config:
		if HenGlobal.script_config.id == script_to_open_id:
			HenGlobal.SIGNAL_BUS.scripts_generation_finished.emit([])
			return
		
		HenSaver.save()

		if HenEnums.get_script_cache_refs(HenGlobal.script_config.id).has(str(script_to_open_id)):
			script_to_open_reload_script_data = HenCodeGeneration.get_updated_script_data(script_to_open_id, HenGlobal.SIDE_BAR_LIST.get_save())
		else:
			script_to_open_reload_script_data = null
		
		load_data(_path)
		return
	
	load_data(_path)


static func load_data(_path: StringName) -> void:
	var start: int = Time.get_ticks_usec()
	var compile_bt: Button = HenGlobal.CAM.get_parent().get_node('%Compile')

	HenGlobal.TABS.add_script_tab(_path)

	compile_bt.disabled = false
	# ---------------------------------------------------------------------------- #
	loaded_virtual_cnode_list.clear()
	connection_list.clear()
	flow_connection_list.clear()
	from_flow_list.clear()

	HenGlobal.SIDE_BAR_LIST.clear()
	HenGlobal.SIDE_BAR_LIST_CACHE.clear()
	HenGlobal.script_config = HenGlobal.ScriptData.new()

	# hide all virtuals
	for cnode: HenCnode in HenGlobal.cnode_pool:
		for signal_data: Dictionary in cnode.get_signal_connection_list('on_move'):
			cnode.disconnect('on_move', signal_data.callable)

		cnode.visible = false

	for connection: HenConnectionLine in HenGlobal.connection_line_pool:
		connection.visible = false

	for flow_connection: HenFlowConnectionLine in HenGlobal.flow_connection_line_pool:
		flow_connection.visible = false

	var _ref
	# cleaning instances
	if HenGlobal.BASE_ROUTE.has('ref'):
		for v_cnode: HenVirtualCNode in HenGlobal.BASE_ROUTE.ref.virtual_cnode_list:
			v_cnode.clean()

			# TODO: get from clean
		
		HenGlobal.BASE_ROUTE.ref.virtual_cnode_list.clear()


		for cnode: HenCnode in HenGlobal.CNODE_CONTAINER.get_children():
			if cnode.virtual_ref:
				cnode.virtual_ref.clean()
				cnode.virtual_ref = null


		# TODO: SIDE BAR clean

		HenGlobal.BASE_ROUTE.ref = null
 
	# ---------------------------------------------------------------------------- #

	# confirming queue free before check errors
	await HenGlobal.CAM.get_tree().process_frame

	HenGlobal.current_script_path = _path
	HenRouter.current_route = {}
	HenRouter.line_route_reference = {}
	HenRouter.comment_reference = {}
	HenGlobal.history = UndoRedo.new()

	
	var base_route: Dictionary = {
		name = 'Base',
		type = HenRouter.ROUTE_TYPE.BASE,
		id = HenUtilsName.get_unique_name(),
		ref = BaseRouteRef.new()
	}

	HenGlobal.BASE_ROUTE = base_route

	var resource_id: int = ResourceLoader.get_resource_uid(_path)
	var is_resource: bool = _path.begins_with('res://hengo/save/') and _path.get_extension() == 'hengo'
	var path: StringName = get_data_path(resource_id) if not is_resource else _path

	HenGlobal.script_config.path = _path
	HenGlobal.script_config.id = resource_id


	# loading hengo script data
	if script_to_open_reload_script_data or (is_resource or FileAccess.file_exists(get_data_path(resource_id))):
		var data: HenScriptData
		
		if script_to_open_reload_script_data:
			data = script_to_open_reload_script_data
		else:
			data = HenScriptData.load_from_file(path)

		# setting script configs
		HenGlobal.script_config.type = data.type
		HenGlobal.node_counter = data.node_counter
		HenGlobal.prop_counter = data.prop_counter

		# loading side bar list
		HenGlobal.SIDE_BAR_LIST.load_save(data.side_bar_list)

		# loading v_cnodes
		_load_vc(data.virtual_cnode_list, base_route)

		# adding in/out connections
		for input_data: Dictionary in connection_list:
			(input_data.from as HenVirtualCNode).add_input_connection(
				input_data.to_id,
				input_data.from_id,
				(loaded_virtual_cnode_list[int(input_data.from_vc_id)] as HenVirtualCNode)
			)

		# adding flow connection
		for flow_data: Dictionary in flow_connection_list:
			var connection = (flow_data.from as HenVirtualCNode).add_flow_connection(flow_data.from_id, flow_data.to_id, loaded_virtual_cnode_list[int(flow_data.to_vc_id)])
		
			if connection:
				connection.add()
			
		# auto re-save
		if script_to_open_reload_script_data:
			if HenGlobal.HENGO_SAVER:
				HenGlobal.HENGO_SAVER.task_id_list.append(WorkerThreadPool.add_task(HenSaver.generate.bind(script_to_open_reload_script_data, resource_id)))
			else:
				push_error('Error: HENGO_SAVER is not set')
	else:
		var reg: RegEx = RegEx.new()
		reg.compile("extends ([a-zA-Z0-9]+)[\\s]*")

		# setting script type
		var script: GDScript = load(_path)
		var type: String = reg.search(script.source_code).get_string(1)


		if type.begins_with('res://hengo/save'):
			push_error("You're trying to open a script with a save file, but the data couldn't be found. Save File: " + type)
			return

		HenGlobal.script_config.type = type
		HenGlobal.node_counter = 0

		HenVirtualCNode.instantiate_virtual_cnode({
			name = 'Stat State',
			type = HenVirtualCNode.Type.STATE_START,
			sub_type = HenVirtualCNode.SubType.STATE_START,
			route = base_route,
			position = Vector2(0, 0),
			can_delete = false
		})

		HenRouter.current_route = base_route
		HenGlobal.CAM._check_virtual_cnodes()


	# checking if debugging
	# change debugger script path
	if HenGlobal.HENGO_DEBUGGER_PLUGIN:
		HenGlobal.HENGO_DEBUGGER_PLUGIN.reload_script()
	
	# showing current type
	show_class_name()
	HenRouter.change_route(HenGlobal.BASE_ROUTE)

	var end: int = Time.get_ticks_usec()

	# hide msg
	(HenGlobal.HENGO_ROOT.get_node('%ScriptMsgContainer') as PanelContainer).visible = false

	print('LOADED SCRIPT IN ', (end - start) / 1000., 'ms')


static func show_class_name() -> void:
	var cl_label: Label = HenGlobal.HENGO_ROOT.get_node('%ClassName')
	var type = HenGlobal.script_config.type
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


static func _load_vc(_cnode_list: Array, _route: Dictionary) -> Array:
	var vc_list: Array = []

	for _config: Dictionary in _cnode_list:
		_config.route = _route

		var vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode(_config)
		loaded_virtual_cnode_list[vc.id] = vc

		if _config.has('from_vc_id'):
			from_flow_list.append({
				from = vc,
				to_id = _config.from_vc_id
			})

		if _config.has('input_connections'):
			for input: Dictionary in _config.input_connections:
				input.from = vc
				connection_list.append(input)
		
		if _config.has('flow_connections'):
			var idx: int = 0
			for flow_connection: Dictionary in _config.flow_connections:
				flow_connection_list.append({
					from = vc,
					from_id = flow_connection.from_id,
					to_id = flow_connection.to_id,
					to_vc_id = flow_connection.to_vc_id
				})
				idx += 1
		
		# if has sub vcnodes (basically states and etc)
		if _config.has('virtual_cnode_list'):
			vc.virtual_cnode_list = _load_vc(_config.virtual_cnode_list, vc.route)

		vc_list.append(vc)

	return vc_list


static func get_data_path(_id: int) -> StringName:
	return 'res://hengo/save/' + str(_id) + HenScriptData.HENGO_EXT