@tool
class_name HenLoader extends Node


var loaded_virtual_cnode_list: Dictionary = {}
var from_flow_list: Array = []


class BaseRouteRef extends RefCounted:
	signal loaded_new_project
	var virtual_cnode_list: Array = []


func reset_to_load(_resource_id: int, _headless: bool, _path: StringName) -> bool:
	var script_data_cache: HenScriptDataCache = Engine.get_singleton(&'ScriptDataCache')
	var global: HenGlobal = Engine.get_singleton(&'Global')

	# cache the current script's state before switching, ensuring any updates
	# are propagated to the target script when it's analyzed
	if global.script_config:
		var current_script_data: HenScriptData = HenSaver.generate_script_data()
		if not script_data_cache.add_script_data(str(global.script_config.id), current_script_data):
			return false
		
		# the generation logic handles cases where the target is not yet cached
		var target_cached: HenScriptData = script_data_cache.try_get_script_data(str(_resource_id))
		var updated_target: HenScriptData = (Engine.get_singleton(&'CodeGeneration') as HenCodeGeneration).get_updated_script_data(
			_resource_id,
			current_script_data.side_bar_list,
			target_cached
		)

		if updated_target:
			if not script_data_cache.add_script_data(str(_resource_id), updated_target):
				return false

	if not _headless:
		var compile_bt: Button = global.CAM.get_parent().get_node_or_null('%Compile')
		compile_bt.disabled = false

	# ---------------------------------------------------------------------------- #
	loaded_virtual_cnode_list.clear()
	from_flow_list.clear()

	# hide all virtuals
	for cnode: HenCnode in global.cnode_pool:
		for signal_data: Dictionary in cnode.get_signal_connection_list('on_move'):
			cnode.disconnect('on_move', signal_data.callable)

		cnode.visible = false

	for connection: HenConnectionLine in global.connection_line_pool:
		connection.visible = false

	for flow_connection: HenFlowConnectionLine in global.flow_connection_line_pool:
		flow_connection.visible = false

	global.BASE_ROUTE_REF = null
	global.SIDE_BAR_LIST.clear()
	global.SIDE_BAR_LIST_CACHE.clear()
	global.SELECTED_VIRTUAL_CNODE.clear()
	global.script_config = global.ScriptData.new()
	global.script_config.path = _path
	global.script_config.id = _resource_id

	# confirming queue free before check errors
	if not _headless: await global.CAM.get_tree().process_frame
	var router: HenRouter = Engine.get_singleton(&'Router')

	global.current_script_path = _path
	router.current_route = null
	router.comment_reference = {}
	global.history = UndoRedo.new()
	global.BASE_ROUTE_REF = BaseRouteRef.new()

	return true


func load(_path: StringName, _headless: bool = false) -> bool:
	var start: int = Time.get_ticks_usec()
	var resource_id: int = _path.get_file().get_basename().to_int() if _path.get_extension() == 'hengo' else ResourceLoader.get_resource_uid(_path)
	var script_data_cache: HenScriptDataCache = Engine.get_singleton(&'ScriptDataCache')
	var is_resource: bool = _path.begins_with('res://hengo/save/') and _path.get_extension() == 'hengo'
	var path: StringName = get_data_path(resource_id) if not is_resource else _path
	var router: HenRouter = Engine.get_singleton(&'Router')
	var global: HenGlobal = Engine.get_singleton(&'Global')

	var script_data: HenScriptData

	# loading hengo script data from cache
	if script_data_cache.has_script_data(str(resource_id)):
		script_data = script_data_cache.try_get_script_data(str(resource_id))

	# loading hengo script data
	if script_data or (is_resource or FileAccess.file_exists(get_data_path(resource_id))):
		if not script_data:
			script_data = HenScriptData.load_from_file(path)

		if not script_data:
			return false

		if not await reset_to_load(resource_id, _headless, _path):
			return false

		var base_route: HenRouteData = HenRouteData.new(
			'Base',
			HenRouter.ROUTE_TYPE.BASE,
			HenUtilsName.get_unique_name(),
			weakref(global.BASE_ROUTE_REF)
		)

		global.BASE_ROUTE = base_route

		if not script_data_cache.add_script_data(str(resource_id), HenScriptData.load(script_data.get_save().duplicate(true))):
			return false

		if not _headless: global.TABS.add_script_tab(resource_id)

		# setting script configs
		global.script_config.type = script_data.type
		global.node_counter = script_data.node_counter

		# loading side bar list
		global.SIDE_BAR_LIST.load_save(script_data.side_bar_list)
		
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
			(Engine.get_singleton(&'ToastContainer') as HenToast).notify.call_deferred("You're trying to open a script with a save file, but the data couldn't be found. Save File: " + type, HenToast.MessageType.ERROR)
			return false

		if not await reset_to_load(resource_id, _headless, _path):
			return false

		var base_route: HenRouteData = HenRouteData.new(
			'Base',
			HenRouter.ROUTE_TYPE.BASE,
			HenUtilsName.get_unique_name(),
			weakref(global.BASE_ROUTE_REF)
		)

		global.BASE_ROUTE = base_route
		global.script_config.type = type
		global.node_counter = 0

		HenVirtualCNode.instantiate_virtual_cnode({
			name = 'Stat State',
			type = HenVirtualCNode.Type.STATE_START,
			sub_type = HenVirtualCNode.SubType.STATE_START,
			route = base_route,
			position = Vector2(0, 0),
			can_delete = false
		})
		router.current_route = base_route
		global.CAM._check_virtual_cnodes()
	
	# showing current type
	if not _headless:
		show_class_name()
		router.change_route(global.BASE_ROUTE)

	var end: int = Time.get_ticks_usec()
		
	print('LOADED SCRIPT IN ', (end - start) / 1000., 'ms')

	global.CAM.can_scroll = true
	global.DASHBOARD.hide_dashboard()
	return true


func show_class_name() -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var cl_label: Button = global.HENGO_ROOT.get_node('%ClassName')
	var type = global.script_config.type
	var sb: StyleBoxFlat = cl_label.get_theme_stylebox('normal')

	cl_label.visible = true
	cl_label.text = type
	cl_label.icon = HenUtils.get_icon_texture(type)

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


func parse_and_get_vc_list_dict(_cnode_list: Array, _route: HenRouteData) -> Array:
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


func get_data_path(_id: int) -> StringName:
	return 'res://hengo/save/' + str(_id) + HenScriptData.HENGO_EXT