@tool
class_name HenLoader extends Node


static var loaded_virtual_cnode_list: Dictionary = {}
static var from_flow_list: Array = []
static var script_to_open_id: int = -1


class BaseRouteRef extends RefCounted:
	signal loaded_new_project
	var virtual_cnode_list: Array = []


static func load(_path: StringName) -> void:
	var start: int = Time.get_ticks_usec()
	var compile_bt: Button = HenGlobal.CAM.get_parent().get_node('%Compile')

	script_to_open_id = ResourceLoader.get_resource_uid(_path)

	# cache the current script's state before switching, ensuring any updates
	# are propagated to the target script when it's analyzed
	if HenGlobal.script_config:
		var current_script_data: HenScriptData = HenSaver.generate_script_data()
		HenScriptDataCache.add_script_data(str(HenGlobal.script_config.id), current_script_data)
		
		# the generation logic handles cases where the target is not yet cached
		var target_cached: HenScriptData = HenScriptDataCache.try_get_script_data(str(script_to_open_id))
		var updated_target: HenScriptData = HenCodeGeneration.get_updated_script_data(
			script_to_open_id,
			current_script_data.side_bar_list,
			target_cached
		)

		if updated_target:
			HenScriptDataCache.add_script_data(str(script_to_open_id), updated_target)

	compile_bt.disabled = false

	# ---------------------------------------------------------------------------- #
	loaded_virtual_cnode_list.clear()
	from_flow_list.clear()

	# hide all virtuals
	for cnode: HenCnode in HenGlobal.cnode_pool:
		for signal_data: Dictionary in cnode.get_signal_connection_list('on_move'):
			cnode.disconnect('on_move', signal_data.callable)

		cnode.visible = false

	for connection: HenConnectionLine in HenGlobal.connection_line_pool:
		connection.visible = false

	for flow_connection: HenFlowConnectionLine in HenGlobal.flow_connection_line_pool:
		flow_connection.visible = false

	HenGlobal.BASE_ROUTE_REF = null
	HenGlobal.SIDE_BAR_LIST.clear()
	HenGlobal.SIDE_BAR_LIST_CACHE.clear()
	HenGlobal.SELECTED_VIRTUAL_CNODE.clear()
	HenGlobal.script_config = HenGlobal.ScriptData.new()

	# confirming queue free before check errors
	await HenGlobal.CAM.get_tree().process_frame
	HenGlobal.current_script_path = _path
	HenRouter.current_route = null
	HenRouter.line_route_reference = {}
	HenRouter.comment_reference = {}
	HenGlobal.history = UndoRedo.new()
	HenGlobal.BASE_ROUTE_REF = BaseRouteRef.new()
	
	var base_route: HenRouteData = HenRouteData.new(
		'Base',
		HenRouter.ROUTE_TYPE.BASE,
		HenUtilsName.get_unique_name(),
		weakref(HenGlobal.BASE_ROUTE_REF)
	)

	HenGlobal.BASE_ROUTE = base_route

	var resource_id: int = ResourceLoader.get_resource_uid(_path)
	var is_resource: bool = _path.begins_with('res://hengo/save/') and _path.get_extension() == 'hengo'
	var path: StringName = get_data_path(resource_id) if not is_resource else _path

	HenGlobal.script_config.path = _path
	HenGlobal.script_config.id = resource_id
	HenGlobal.TABS.add_script_tab(resource_id)

	var script_data: HenScriptData

	# loading hengo script data from cache
	if HenScriptDataCache.has_script_data(str(resource_id)):
		script_data = HenScriptDataCache.try_get_script_data(str(resource_id))

	# loading hengo script data
	if script_data or (is_resource or FileAccess.file_exists(get_data_path(resource_id))):
		if not script_data:
			script_data = HenScriptData.load_from_file(path)
			HenScriptDataCache.add_script_data(str(resource_id), HenScriptData.load(script_data.get_save().duplicate(true)))

		# setting script configs
		HenGlobal.script_config.type = script_data.type
		HenGlobal.node_counter = script_data.node_counter

		# loading side bar list
		HenGlobal.SIDE_BAR_LIST.load_save(script_data.side_bar_list)

		# loading v_cnodes
		parse_and_get_vc_list_dict(script_data.virtual_cnode_list, base_route)

		# adding in/out connections
		for input_data: Dictionary in script_data.connections:
			var to: HenVirtualCNode = loaded_virtual_cnode_list[int(input_data.to_vc_id)]
			var connection: HenVCConnectionReturn = to.get_new_input_connection_command(
				input_data.to_id,
				input_data.from_id,
				(loaded_virtual_cnode_list[int(input_data.from_vc_id)] as HenVirtualCNode)
			)

			if connection:
				connection.add()

		# adding flow connection
		for flow_data: Dictionary in script_data.flow_connections:
			var from: HenVirtualCNode = loaded_virtual_cnode_list[int(flow_data.from_vc_id)]
			var connection = from.add_flow_connection(flow_data.from_id, flow_data.to_id, loaded_virtual_cnode_list[int(flow_data.to_vc_id)])
		
			if connection:
				connection.add()
	else:
		var reg: RegEx = RegEx.new()
		reg.compile("extends ([a-zA-Z0-9]+)[\\s]*")

		# setting script type
		var script: GDScript = load(_path)
		var type: String = reg.search(script.source_code).get_string(1)


		if type.begins_with('res://hengo/save'):
			HenGlobal.SIGNAL_BUS.set_terminal_text.emit.call_deferred(HenUtils.get_error_text("You're trying to open a script with a save file, but the data couldn't be found. Save File: " + type))
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


static func parse_and_get_vc_list_dict(_cnode_list: Array, _route: HenRouteData) -> Array:
	var vc_list: Array = []

	for _config: Dictionary in _cnode_list:
		_config.route = _route

		var vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode(_config)
		_config.erase('route')
		loaded_virtual_cnode_list[vc.identity.id] = vc

		if _config.has('from_vc_id'):
			from_flow_list.append({
				from = vc,
				to_id = _config.from_vc_id
			})
		
		# if has sub vcnodes (basically states and etc)
		if _config.has('virtual_cnode_list'):
			vc.children.virtual_cnode_list = parse_and_get_vc_list_dict(_config.virtual_cnode_list, vc.route_info.route)

		vc_list.append(vc)

	return vc_list


static func get_data_path(_id: int) -> StringName:
	return 'res://hengo/save/' + str(_id) + HenScriptData.HENGO_EXT