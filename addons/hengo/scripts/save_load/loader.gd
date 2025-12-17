@tool
class_name HenLoader extends Node


var loaded_virtual_cnode_list: Dictionary = {}
var from_flow_list: Array = []


class BaseRouteRef extends RefCounted:
	var virtual_cnode_list: Array = []


func reset_to_load(_id: StringName, _headless: bool) -> bool:
	var global: HenGlobal = Engine.get_singleton(&'Global')

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

	global.SIDE_BAR_LIST_CACHE.clear()
	global.SELECTED_VIRTUAL_CNODE.clear()
	global.RIGHT_SIDE_BAR.clear()

	# confirming queue free before check errors
	if not _headless: await global.CAM.get_tree().process_frame
	var router: HenRouter = Engine.get_singleton(&'Router')

	router.current_route = null
	router.comment_reference = {}
	global.history = UndoRedo.new()

	return true
 

func load_res(_res_id: StringName) -> HenSaveData:
	var save_data: HenSaveData
	var path: StringName = HenEnums.HENGO_SAVE_PATH.path_join(_res_id).path_join('save.tres')

	if FileAccess.file_exists(path):
		save_data = ResourceLoader.load(path)
	else:
		print('error loading save')
		# save_data = HenSaveData.new()
		# save_data.id = _res_id
		
		# var first_var: HenSaveVar = HenSaveVar.create()

		# first_var.name = 'variable name'
		# first_var.type = &'String'

		# var first_func: HenSaveFunc = HenSaveFunc.create()
		# first_func.name = 'my func'
		# var param1: HenSaveParam = HenSaveParam.create()
		# var param2: HenSaveParam = HenSaveParam.create()
		# var param3: HenSaveParam = HenSaveParam.create()

		# param1.name = 'one'
		# param2.name = 'two'
		# param3.name = 'three'

		# first_func.inputs.append(param1)
		# first_func.inputs.append(param2)
		# first_func.outputs.append(param3)

		# var first_signal_callback: HenSaveSignalCallback = HenSaveSignalCallback.create()

		# first_signal_callback.name = 'signal cb'
		# first_signal_callback.type = &'BaseButton'
		# first_signal_callback.signal_name = 'toggled'
		# first_signal_callback.signal_name_to_code = 'toggled'

		# var param4: HenSaveParam = HenSaveParam.create()

		# param4.name = 'four'

		# first_signal_callback.bind_params.append(param4)

		# var first_macro: HenSaveMacro = HenSaveMacro.create()

		# var param5: HenSaveParam = HenSaveParam.create()
		# var param6: HenSaveParam = HenSaveParam.create()

		# first_macro.inputs.append(param5)
		# first_macro.outputs.append(param6)
	
		# var param7: HenSaveParam = HenSaveParam.create()
		# var param8: HenSaveParam = HenSaveParam.create()

		# first_macro.flow_inputs.append(param7)
		# first_macro.flow_outputs.append(param8)

		# first_macro.name = 'my macro'

		# save_data.variables.append(first_var)
		# save_data.functions.append(first_func)
		# save_data.signals_callback.append(first_signal_callback)
		# save_data.macros.append(first_macro)
	
	return save_data


func load(_id: StringName, _headless: bool = false) -> bool:
	var start: int = Time.get_ticks_usec()
	var router: HenRouter = Engine.get_singleton(&'Router')
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var save_data: HenSaveData = load_res(_id)

	global.SAVE_DATA = save_data

	# loading hengo script data
	if save_data:
		if not await reset_to_load(_id, _headless):
			return false

		var base_route: HenRouteData = HenRouteData.new(
			'Base',
			HenRouter.ROUTE_TYPE.BASE,
			HenUtilsName.get_unique_name(),
		)

		global.BASE_ROUTE = base_route
		
		# loading v_cnodes
		base_route.virtual_cnode_list = parse_and_get_vc_list_dict(save_data.virtual_cnode_list, base_route)

		generate_item_with_routes(save_data.functions)
		generate_item_with_routes(save_data.macros)
		generate_item_with_routes(save_data.signals_callback)

		# adding in/out connections
		for input_data: Dictionary in save_data.connections:
			var to: HenVirtualCNode = loaded_virtual_cnode_list[int(input_data.to_vc_id)]
			var connection: HenVCConnectionReturn = to.get_new_input_connection_command(
				input_data.to_id,
				input_data.from_id,
				(loaded_virtual_cnode_list[int(input_data.from_vc_id)] as HenVirtualCNode)
			)

			if connection:
				connection.add()
			else:
				pass

		# adding flow connection
		for flow_data: Dictionary in save_data.flow_connections:
			var from: HenVirtualCNode = loaded_virtual_cnode_list[int(flow_data.from_vc_id)]
			var connection = from.add_flow_connection(flow_data.from_id, flow_data.to_id, loaded_virtual_cnode_list[int(flow_data.to_vc_id)])
		
			if connection:
				connection.add()
	
	# showing current type
	if not _headless:
		show_class_name()
		router.change_route(global.BASE_ROUTE)

	var end: int = Time.get_ticks_usec()
		
	print('LOADED SCRIPT IN ', (end - start) / 1000., 'ms')

	global.CAM.can_scroll = true
	global.DASHBOARD.hide_dashboard()

	return true


func generate_item_with_routes(_arr: Array) -> void:
	for item: HenSaveResTypeWithRoute in _arr:
		item.route.virtual_cnode_list = parse_and_get_vc_list_dict(item.virtual_cnode_list, item.route, item)


func show_class_name() -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	
	if not global.SAVE_DATA:
		return
	
	var cl_label: Button = global.HENGO_ROOT.get_node('%ClassName')
	var type = global.SAVE_DATA.identity.type
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


func parse_and_get_vc_list_dict(_cnode_list: Array, _route: HenRouteData, _item: HenSaveResTypeWithRoute = null) -> Array:
	var vc_list: Array[HenVirtualCNode] = []

	for _config: Dictionary in _cnode_list:
		_config.route = _route

		var is_circular: bool = HenUtils.is_circular_dependent(_config.get('sub_type'))

		# adding item reference here to prevent circular reference on saving
		if is_circular: _config.res = _item
		var vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode(_config)
		if is_circular: _config.erase('res')
		
		_config.erase('route')
		loaded_virtual_cnode_list[vc.identity.id] = vc

		if _config.has('from_vc_id'):
			from_flow_list.append({
				from = vc,
				to_id = _config.from_vc_id
			})
		
		# if has sub vcnodes (basically states and etc)
		if _config.has('virtual_cnode_list'):
			vc.route_info.route.virtual_cnode_list = parse_and_get_vc_list_dict(_config.virtual_cnode_list, vc.route_info.route, _item)

		vc_list.append(vc)

	return vc_list


func get_data_path(_id: int) -> StringName:
	return HenEnums.HENGO_SAVE_PATH.path_join(str(_id)).path_join('/save.tres')