@tool
class_name HenLoader extends Node


class BaseRouteRef extends RefCounted:
	var virtual_cnode_list: Array = []


func reset_to_load(_id: StringName, _headless: bool) -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')

	if not _headless:
		var compile_bt: Button = global.CAM.get_parent().get_node_or_null('%Compile')
		compile_bt.disabled = false

	# hide all virtuals
	for cnode: HenCnode in global.cnode_pool:
		for signal_data: Dictionary in cnode.get_signal_connection_list('on_move'):
			cnode.disconnect('on_move', signal_data.callable)

		cnode.visible = false

	for connection: HenConnectionLine in global.connection_line_pool:
		connection.visible = false

	for flow_connection: HenFlowConnectionLine in global.flow_connection_line_pool:
		flow_connection.visible = false

	global.SELECTED_VIRTUAL_CNODE.clear()
	global.RIGHT_SIDE_BAR.clear()

	# confirming queue free before check errors
	if not _headless: await global.CAM.get_tree().process_frame

	global.history = UndoRedo.new()
 

func load_res(_res_id: StringName) -> HenSaveData:
	var save_data: HenSaveData
	var path: StringName = HenEnums.HENGO_SAVE_PATH.path_join(_res_id).path_join('save.tres')

	if FileAccess.file_exists(path):
		save_data = ResourceLoader.load(path)
	else:
		print('error loading save')
	
	return save_data


func load(_id: StringName, _headless: bool = false) -> bool:
	var start: int = Time.get_ticks_usec()
	var router: HenRouter = Engine.get_singleton(&'Router')
	var global: HenGlobal = Engine.get_singleton(&'Global')

	var save_data: HenSaveData = load_res(_id)

	# loading hengo script data
	if save_data:
		global.SAVE_DATA = save_data
		reset_to_load(_id, _headless)
	else:
		return false
	
	# showing current type
	if not _headless:
		show_class_name()
		router.change_route(global.SAVE_DATA.get_base_route())

	var end: int = Time.get_ticks_usec()
		
	print('LOADED SCRIPT IN ', (end - start) / 1000., 'ms')

	global.CAM.can_scroll = true
	global.DASHBOARD.hide_dashboard()

	return true


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


func get_data_path(_id: int) -> StringName:
	return HenEnums.HENGO_SAVE_PATH.path_join(str(_id)).path_join('/save.tres')