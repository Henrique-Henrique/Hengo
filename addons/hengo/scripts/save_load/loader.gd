@tool
class_name HenLoader extends Node


class BaseRouteRef extends RefCounted:
	var virtual_cnode_list: Array = []


func reset_to_load(_id: StringName, _headless: bool) -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var router: HenRouter = Engine.get_singleton(&'Router')
	
	if router.current_route:
		for v_cnode: HenVirtualCNode in router.get_current_route_v_cnodes():
			v_cnode.hide()
		router.current_route = null

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

	# confirming queue free before check errors
	if not _headless: await global.CAM.get_tree().process_frame

	global.history = UndoRedo.new()
 

func load_res(_res_id: StringName) -> HenSaveData:
	var save_data: HenSaveData
	var path: String = HenUtils.get_script_dir(_res_id).path_join(HenEnums.SAVE_FILE)

	if FileAccess.file_exists(path):
		save_data = ResourceLoader.load(path)
	else:
		print('error loading save: ', path)

	return save_data


func load_collection_res(_collection_id: StringName) -> HenSaveCollection:
	var path: String = HenEnums.HENGO_COLLECTION_PATH.path_join(_collection_id).path_join(HenEnums.COLLECTION_FILE)

	if FileAccess.file_exists(path):
		return ResourceLoader.load(path)

	print('error loading collection: ', path)
	return null


# loads every script of a collection into memory with a single ui reset
func load_collection(_collection_id: StringName, _headless: bool = false) -> bool:
	var start: int = Time.get_ticks_usec()
	var global: HenGlobal = Engine.get_singleton(&'Global')

	var collection: HenSaveCollection = load_collection_res(_collection_id)
	if not collection:
		return false

	global.ACTIVE_COLLECTION = collection
	global.OPEN_SCRIPTS.clear()

	for script_id: StringName in collection.script_ids:
		var save_data: HenSaveData = load_res(script_id)
		if save_data:
			_strip_script_macros(save_data)
			global.OPEN_SCRIPTS.append(save_data)

	if global.OPEN_SCRIPTS.is_empty():
		global.SAVE_DATA = null
		reset_to_load(&'', _headless)
		global.CAM.can_scroll = true
		global.DASHBOARD.hide_dashboard()
		if global.HENGO_ROOT:
			global.HENGO_ROOT.refresh_script_state()
		(Engine.get_singleton(&'SignalBus') as HenSignalBus).request_list_update.emit()
		return true

	var active: HenSaveData = _resolve_active(collection)

	global.SAVE_DATA = active
	reset_to_load(active.identity.id, _headless)
	_apply_active(active, _headless)

	global.CAM.can_scroll = true
	global.DASHBOARD.hide_dashboard()

	var end: int = Time.get_ticks_usec()
	print('LOADED COLLECTION (', global.OPEN_SCRIPTS.size(), ' scripts) IN ', (end - start) / 1000., 'ms')

	(Engine.get_singleton(&'SignalBus') as HenSignalBus).request_list_update.emit()
	return true


# switches the active script without touching disk
func set_active_script(_save_data: HenSaveData) -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')

	if not _save_data or global.SAVE_DATA == _save_data:
		return

	global.SAVE_DATA = _save_data
	if global.ACTIVE_COLLECTION:
		global.ACTIVE_COLLECTION.last_active_id = _save_data.identity.id

	_apply_active(_save_data, false)

	(Engine.get_singleton(&'SignalBus') as HenSignalBus).request_list_update.emit()


# finds the active script of a collection, falling back to the first one
func _resolve_active(_collection: HenSaveCollection) -> HenSaveData:
	var global: HenGlobal = Engine.get_singleton(&'Global')

	if not String(_collection.last_active_id).is_empty():
		for save_data: HenSaveData in global.OPEN_SCRIPTS:
			if save_data.identity.id == _collection.last_active_id:
				return save_data

	return global.OPEN_SCRIPTS[0]


# wires the active script into the ui (route, sidebar, class name)
func _apply_active(_save_data: HenSaveData, _headless: bool) -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var router: HenRouter = Engine.get_singleton(&'Router')

	HenScriptMacroLoader.load_script_macros()

	if not _headless:
		show_class_name()
		router.change_route(_save_data.get_base_route())

	if global.HENGO_ROOT:
		global.HENGO_ROOT.refresh_script_state()


# removes script-macros baked into the save data (re-added from the macros folder)
func _strip_script_macros(_save_data: HenSaveData) -> void:
	for i: int in range(_save_data.macros.size() - 1, -1, -1):
		if _save_data.macros[i].is_script_macro:
			_save_data.macros.remove_at(i)


func load(_id: StringName, _headless: bool = false, _override_data: HenSaveData = null) -> bool:
	var start: int = Time.get_ticks_usec()
	var router: HenRouter = Engine.get_singleton(&'Router')
	var global: HenGlobal = Engine.get_singleton(&'Global')

	var save_data: HenSaveData

	if _override_data:
		save_data = _override_data
	else:
		save_data = load_res(_id)

	# loading hengo script data
	if save_data:
		global.SAVE_DATA = save_data
		global.OPEN_SCRIPTS = [save_data]

		_strip_script_macros(save_data)

		# load script macros
		HenScriptMacroLoader.load_script_macros()

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

	if global.HENGO_ROOT:
		global.HENGO_ROOT.refresh_script_state()

	(Engine.get_singleton(&'SignalBus') as HenSignalBus).request_list_update.emit()
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
	sb.bg_color = HenUtils.get_type_parent_color(type, .2)


func get_data_path(_id: int) -> StringName:
	return HenUtils.get_script_dir(StringName(str(_id))).path_join(HenEnums.SAVE_FILE)