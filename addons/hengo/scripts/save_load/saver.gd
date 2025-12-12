@tool
class_name HenSaver extends Node

enum SideBarItem {
	VARIABLES,
	FUNCTIONS,
	SIGNALS,
	SIGNALS_CALLBACK,
	MACROS
}


static func save() -> void:
	(Engine.get_singleton(&'SignalBus') as HenSignalBus).scripts_generation_started.emit()
	(Engine.get_singleton(&'ThreadHelper') as HenThreadHelper).add_task(start_generate.bind(true))


# returns the specific path based on the provided enum type
static func get_side_bar_item_path(_id: StringName, type: SideBarItem) -> StringName:
	var base_path: StringName = HenEnums.HENGO_SAVE_PATH + str(_id)
	var suffix: String = ''

	match type:
		SideBarItem.VARIABLES:
			suffix = '/variables/'
		SideBarItem.FUNCTIONS:
			suffix = '/functions/'
		SideBarItem.SIGNALS:
			suffix = '/signals/'
		SideBarItem.SIGNALS_CALLBACK:
			suffix = '/signals_callback/'
		SideBarItem.MACROS:
			suffix = '/macros/'

	return base_path + suffix


static func save_new() -> void:
	if not DirAccess.dir_exists_absolute('res://hengo'):
		DirAccess.make_dir_absolute('res://hengo')
	
	if not DirAccess.dir_exists_absolute(HenEnums.HENGO_SAVE_PATH):
		DirAccess.make_dir_absolute(HenEnums.HENGO_SAVE_PATH)
	
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var toast: HenToast = Engine.get_singleton(&'ToastContainer')

	var save_data: HenSaveData = get_current_save_data(global)
	var script_id: StringName = str(save_data.identity.id)
	var script_path: StringName = HenEnums.HENGO_SAVE_PATH + script_id

	save_side_bar_item(save_data.variables, get_side_bar_item_path(script_id, SideBarItem.VARIABLES))
	save_side_bar_item(save_data.functions, get_side_bar_item_path(script_id, SideBarItem.FUNCTIONS))
	save_side_bar_item(save_data.signals, get_side_bar_item_path(script_id, SideBarItem.SIGNALS))
	save_side_bar_item(save_data.signals_callback, get_side_bar_item_path(script_id, SideBarItem.SIGNALS_CALLBACK))
	save_side_bar_item(save_data.macros, get_side_bar_item_path(script_id, SideBarItem.MACROS))

	save_data.take_over_path(script_path + '/save.tres')
	var result: int = ResourceSaver.save(save_data)
	toast.notify.call_deferred(('Saved SAVE DATA: ' + str(save_data.identity.id)) if result == OK else 'Erro saving' + str(save_data.identity.id))


static func get_current_save_data(_global: HenGlobal) -> HenSaveData:
	var save_data: HenSaveData = _global.SAVE_DATA
	build_current_virtual_cnode_list(_global)
	return save_data


static func build_current_virtual_cnode_list(_global: HenGlobal) -> void:
	var save_data: HenSaveData = _global.SAVE_DATA

	save_data.virtual_cnode_list.clear()
	save_data.connections.clear()
	save_data.flow_connections.clear()
	save_data.identity.deps.clear()

	for v_cnode: HenVirtualCNode in _global.BASE_ROUTE.virtual_cnode_list:
		save_data.virtual_cnode_list.append(v_cnode.get_save(save_data))

		if v_cnode.identity.type == HenVirtualCNode.Type.STATE_EVENT:
			save_data.state_event_list.append(v_cnode.identity.name)

	generate_vc_list(save_data, save_data.functions)
	generate_vc_list(save_data, save_data.macros)
	generate_vc_list(save_data, save_data.signals_callback)


static func generate_vc_list(_save_data: HenSaveData, _arr: Array) -> void:
	for item: HenSaveResTypeWithRoute in _arr:
		item.virtual_cnode_list.clear()

		for vc: HenVirtualCNode in item.route.virtual_cnode_list:
			item.virtual_cnode_list.append(vc.get_save(_save_data))


static func save_side_bar_item(_arr: Array, _path: StringName) -> void:
	var toast: HenToast = Engine.get_singleton(&'ToastContainer')

	if not DirAccess.dir_exists_absolute(_path):
		DirAccess.make_dir_absolute(_path)

	for item: HenSaveResType in _arr:
		item.take_over_path(_path + str(item.id) + '.tres')
		var result: int = ResourceSaver.save(item)
		toast.notify.call_deferred(
			('Saved: ' + _path) if result == OK else 'Erro saving' + str(item.id),
			HenToast.MessageType.SUCCESS if result == OK else HenToast.MessageType.ERROR
		)


static func start_generate(_regenerate: bool = false) -> void:
	var start_time: int = Time.get_ticks_msec()
	var toast: HenToast = Engine.get_singleton(&'ToastContainer')

	# check if save dierctory exists
	if not DirAccess.dir_exists_absolute('res://hengo'):
		DirAccess.make_dir_absolute('res://hengo')

	if not DirAccess.dir_exists_absolute(HenEnums.HENGO_SAVE_PATH):
		DirAccess.make_dir_absolute(HenEnums.HENGO_SAVE_PATH)

	save_new()
	
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var current_save_data: HenSaveData = global.SAVE_DATA
	var current_id: StringName = str(current_save_data.identity.id)
	
	var map_deps: HenMapDependencies = Engine.get_singleton(&'MapDependencies')
	map_deps.update_project_data(current_id)
	
	_compile_script(current_id)
	
	var scripts_to_recompile: Array[StringName] = map_deps.check_dependencies(current_id)
	var recompiled_count: int = 0
	
	for script_id: StringName in scripts_to_recompile:
		_compile_script(script_id)
		recompiled_count += 1
	
	var end_time: int = Time.get_ticks_msec()
	var compilation_time: float = (end_time - start_time)
	
	var msg: String = "Saved & Compiled in " + str(compilation_time) + "ms"
	if recompiled_count > 0:
		msg += " (" + str(recompiled_count) + " dependents recompiled)"
		
	toast.notify.call_deferred(msg, HenToast.MessageType.SUCCESS)
	var signal_bus: HenSignalBus = Engine.get_singleton(&'SignalBus')
	signal_bus.scripts_generation_finished.emit.call_deferred()


static func _compile_script(_id: StringName) -> void:
	var save_path: String = HenEnums.HENGO_SAVE_PATH.path_join(_id).path_join('save.tres')
	if not FileAccess.file_exists(save_path):
		push_error("Cannot compile script, save data not found: " + save_path)
		return
		
	var save_data: HenSaveData = load(save_path)
	if not save_data:
		push_error("Failed to load save data for compilation: " + save_path)
		return
	
	recalculate_dependencies(save_data)
	
	var identity_path: String = HenEnums.HENGO_SAVE_PATH.path_join(_id).path_join('identity.tres')
	ResourceSaver.save(save_data.identity, identity_path)
	
	var map_deps: HenMapDependencies = Engine.get_singleton(&'MapDependencies')
	map_deps.update_project_data(_id)
		
	var code_gen: HenCodeGeneration = Engine.get_singleton('CodeGeneration')
	var code: String = code_gen.get_code(save_data)
	
	if not DirAccess.dir_exists_absolute("res://hengo/scripts"):
		DirAccess.make_dir_absolute("res://hengo/scripts")
	
	var script_path: String = "res://hengo/scripts/" + str(_id) + ".gd"
	var file: FileAccess = FileAccess.open(script_path, FileAccess.WRITE)
	if file:
		print('Compiled: ', _id)
		file.store_string(code)
		file.close()
	else:
		push_error("Failed to write compiled script: " + script_path)


static func recalculate_dependencies(save_data: HenSaveData) -> void:
	save_data.identity.deps.clear()
	save_data.identity.detailed_deps.clear()
	
	_process_cnodes_for_deps(save_data, save_data.virtual_cnode_list)
	
	for func_data: HenSaveFunc in save_data.functions:
		_process_cnodes_for_deps(save_data, func_data.get_data().virtual_cnode_list)
		
	for macro_data: HenSaveMacro in save_data.macros:
		_process_cnodes_for_deps(save_data, macro_data.get_data().virtual_cnode_list)
		
	for sc_data: HenSaveSignalCallback in save_data.signals_callback:
		_process_cnodes_for_deps(save_data, sc_data.get_data().virtual_cnode_list)


static func _process_cnodes_for_deps(save_data: HenSaveData, cnode_list: Array) -> void:
	for cnode_data: Dictionary in cnode_list:
		if cnode_data.has('res') and cnode_data.res:
			var res = cnode_data.res
			var parent_id: String = HenUtils.get_res_parent_id(res)
			save_data.add_dep(parent_id)
			
			var dep_hash: int = HenUtils.get_dependency_hash(res)
				
			if dep_hash != 0:
				save_data.add_detailed_dep(parent_id, {
					type = HenUtils.get_dependency_type(res),
					name = res.name,
					hash = dep_hash
				})
		
		if cnode_data.has('virtual_cnode_list'):
			_process_cnodes_for_deps(save_data, cnode_data.virtual_cnode_list)
