@tool
class_name HenSaver extends Node


static func save() -> void:
	(Engine.get_singleton(&'SignalBus') as HenSignalBus).scripts_generation_started.emit()
	(Engine.get_singleton(&'ThreadHelper') as HenThreadHelper).add_task(start_generate.bind(true))


static func save_new() -> void:
	if not DirAccess.dir_exists_absolute('res://hengo'):
		DirAccess.make_dir_absolute('res://hengo')
	
	if not DirAccess.dir_exists_absolute(HenEnums.HENGO_SAVE_PATH):
		DirAccess.make_dir_absolute(HenEnums.HENGO_SAVE_PATH)
	
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var toast: HenToast = Engine.get_singleton(&'ToastContainer')
	var save_data: HenSaveData = global.SAVE_DATA
	var result: int = ResourceSaver.save(save_data)
	
	toast.notify.call_deferred(('Saved SAVE DATA: ' + str(save_data.identity.id)) if result == OK else 'Erro saving' + str(save_data.identity.id))


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
	
	# recalculate_dependencies(save_data)
	
	var identity_path: String = HenEnums.HENGO_SAVE_PATH.path_join(_id).path_join('identity.tres')
	ResourceSaver.save(save_data.identity, identity_path)
	
	var map_deps: HenMapDependencies = Engine.get_singleton(&'MapDependencies')
	map_deps.update_project_data(_id)
		
	var code_gen: HenCodeGeneration = Engine.get_singleton('CodeGeneration')
	var code: String = code_gen.get_code(save_data)
	
	if not DirAccess.dir_exists_absolute("res://hengo/scripts"):
		DirAccess.make_dir_absolute("res://hengo/scripts")
	
	var script_path: String = HenEnums.HENGO_SCRIPTS_PATH + str(_id) + ".gd"
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
	
	_process_cnodes_for_deps(save_data, save_data.base_route.virtual_cnode_list)
	
	for func_data: HenSaveFunc in save_data.functions:
		_process_cnodes_for_deps(save_data, func_data.route.virtual_cnode_list)
		
	for macro_data: HenSaveMacro in save_data.macros:
		_process_cnodes_for_deps(save_data, macro_data.route.virtual_cnode_list)
		
	for sc_data: HenSaveSignalCallback in save_data.signals_callback:
		_process_cnodes_for_deps(save_data, sc_data.route.virtual_cnode_list)


static func _process_cnodes_for_deps(save_data: HenSaveData, cnode_list: Array) -> void:
	for cnode: HenVirtualCNode in cnode_list:
		var res = cnode.get_res()
		if res:
			var parent_id: String = HenUtils.get_res_parent_id(res)
			save_data.add_dep(parent_id)
			
			var dep_hash: int = HenUtils.get_dependency_hash(res)
				
			if dep_hash != 0:
				save_data.add_detailed_dep(parent_id, {
					type = HenUtils.get_dependency_type(res),
					id = res.id,
					hash = dep_hash
				})
		
		if cnode.route and not cnode.route.virtual_cnode_list.is_empty():
			_process_cnodes_for_deps(save_data, cnode.route.virtual_cnode_list)
