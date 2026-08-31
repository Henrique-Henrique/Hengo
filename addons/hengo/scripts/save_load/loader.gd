@tool
class_name HenLoader extends Node



func reset_to_load(_id: StringName, _headless: bool) -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	

	if not _headless:
		var compile_bt: Button = global.HENGO_ROOT.get_node_or_null('%Compile')
		compile_bt.disabled = false

	# hide all virtuals





	# confirming queue free before check errors
	if not _headless: await get_tree().process_frame

 

func load_res(_res_id: StringName, _migrate_base: bool = false) -> HenSaveData:
	var save_data: HenSaveData
	var path: String = HenUtils.get_script_dir(_res_id).path_join(HenEnums.SAVE_FILE)

	if FileAccess.file_exists(path):
		# guard the deserialization so state setters don't mutate sibling start flags
		var signal_bus: HenSignalBus = Engine.get_singleton(&'SignalBus')
		var prev_batch: bool = signal_bus.is_batch_loading if signal_bus else false
		if signal_bus:
			signal_bus.is_batch_loading = true
		save_data = ResourceLoader.load(path)
		_ensure_base_state(save_data, _migrate_base)
		if signal_bus:
			signal_bus.is_batch_loading = prev_batch
	else:
		print('error loading save: ', path)

	return save_data


# scripts written before the base state existed get theirs on the way in. writing
# it back is left to the paths that open a script, because the dependency scan
# reaches this from the codegen worker thread
func _ensure_base_state(_save_data: HenSaveData, _migrate: bool) -> void:
	if not _save_data or not _save_data.identity or _save_data.get_base_state():
		return

	var base: HenSaveState = _save_data.ensure_base_state()
	var global: HenGlobal = Engine.get_singleton(&'Global')

	if not _migrate or not base or (global and global.IS_HEADLESS):
		return

	HenUtils.save_side_bar_item(base, _save_data.identity.id, HenSideBar.SideBarItem.STATES)
	ResourceSaver.save(_save_data)


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
		var save_data: HenSaveData = load_res(script_id, true)
		if save_data:
			global.OPEN_SCRIPTS.append(save_data)

	# refresh the dependency map from in-memory data so cross-script resolution
	# (states, vars, funcs) works for every open script — disk mapping omits states
	var map_deps: HenMapDependencies = Engine.get_singleton(&'MapDependencies')
	for save_data: HenSaveData in global.OPEN_SCRIPTS:
		map_deps.update_project_data_from_save(save_data.identity.id, save_data)

	if global.OPEN_SCRIPTS.is_empty():
		global.SAVE_DATA = null
		reset_to_load(&'', _headless)
		HenCam.set_all_can_scroll(get_tree(), true)
		global.DASHBOARD.hide_dashboard()
		if global.HENGO_ROOT:
			global.HENGO_ROOT.refresh_script_state()
		(Engine.get_singleton(&'SignalBus') as HenSignalBus).request_list_update.emit()
		return true

	var active: HenSaveData = _resolve_active(collection)

	global.SAVE_DATA = active
	reset_to_load(active.identity.id, _headless)
	_apply_active(active, _headless)
	_migrate_open_scripts()

	HenCam.set_all_can_scroll(get_tree(), true)
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


# runs after the macro pool: the macro is what names the branch an older body moves
# to, and what tells an older action clone which input it is missing
func _migrate_open_scripts() -> void:
	for save_data: HenSaveData in (Engine.get_singleton(&'Global') as HenGlobal).OPEN_SCRIPTS:
		HenSaveAction.migrate_retired_macros(save_data)
		HenSaveAction.migrate_branch_bodies(save_data)
		HenSaveAction.sync_macro_inputs(save_data)


# wires the active script into the ui (route, sidebar, class name)
func _apply_active(_save_data: HenSaveData, _headless: bool) -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')

	HenScriptMacroLoader.load_script_macros()
	HenScriptMacroLoader.load_native_actions()
	HenRoute.sync_to_script(String(_save_data.identity.id) if _save_data.identity else '')

	if not _headless:
		show_class_name()

	if global.HENGO_ROOT:
		global.HENGO_ROOT.refresh_script_state()




func load(_id: StringName, _headless: bool = false, _override_data: HenSaveData = null) -> bool:
	var start: int = Time.get_ticks_usec()
	var global: HenGlobal = Engine.get_singleton(&'Global')

	var save_data: HenSaveData

	if _override_data:
		save_data = _override_data
	else:
		save_data = load_res(_id, true)

	# loading hengo script data
	if save_data:
		global.SAVE_DATA = save_data
		global.OPEN_SCRIPTS = [save_data]

		# load script macros
		HenScriptMacroLoader.load_script_macros()
		HenScriptMacroLoader.load_native_actions()
		HenRoute.sync_to_script(String(save_data.identity.id) if save_data.identity else '')

		_migrate_open_scripts()

		reset_to_load(_id, _headless)
	else:
		return false

	# showing current type
	if not _headless:
		show_class_name()

	var end: int = Time.get_ticks_usec()

	print('LOADED SCRIPT IN ', (end - start) / 1000., 'ms')

	HenCam.set_all_can_scroll(get_tree(), true)
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