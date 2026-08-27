@tool
class_name HenSaver extends Node


static func save() -> void:
	(Engine.get_singleton(&'SignalBus') as HenSignalBus).scripts_generation_started.emit()
	(Engine.get_singleton(&'ThreadHelper') as HenThreadHelper).add_task(start_generate.bind(true))


static func save_new() -> void:
	if not DirAccess.dir_exists_absolute('res://hengo'):
		DirAccess.make_dir_absolute('res://hengo')

	if not DirAccess.dir_exists_absolute(HenEnums.HENGO_COLLECTION_PATH):
		DirAccess.make_dir_absolute(HenEnums.HENGO_COLLECTION_PATH)

	var global: HenGlobal = Engine.get_singleton(&'Global')
	var toast: HenToast = Engine.get_singleton(&'ToastContainer')

	# persist every open script of the collection
	for save_data: HenSaveData in global.OPEN_SCRIPTS:
		if not save_data:
			continue
		var result: int = ResourceSaver.save(save_data)
		if result != OK:
			toast.notify.call_deferred('Error saving ' + str(save_data.identity.id), HenToast.MessageType.ERROR)


static func start_generate(_regenerate: bool = false) -> void:
	var start_time: int = Time.get_ticks_msec()
	var toast: HenToast = Engine.get_singleton(&'ToastContainer')

	# check if save directory exists
	if not DirAccess.dir_exists_absolute('res://hengo'):
		DirAccess.make_dir_absolute('res://hengo')

	if not DirAccess.dir_exists_absolute(HenEnums.HENGO_COLLECTION_PATH):
		DirAccess.make_dir_absolute(HenEnums.HENGO_COLLECTION_PATH)

	var global: HenGlobal = Engine.get_singleton(&'Global')
	if global.OPEN_SCRIPTS.is_empty():
		(Engine.get_singleton(&'SignalBus') as HenSignalBus).scripts_generation_finished.emit.call_deferred()
		return

	save_new()

	# validates the active script graph (ui-based check)
	var hengo_root: HenHengoRoot = global.HENGO_ROOT
	if hengo_root and not hengo_root.check_errors(true):
		toast.notify.call_deferred("Compilation blocked due to errors.", HenToast.MessageType.ERROR)
		(Engine.get_singleton(&'SignalBus') as HenSignalBus).scripts_generation_finished.emit.call_deferred()
		return

	var map_deps: HenMapDependencies = Engine.get_singleton(&'MapDependencies')
	var compiled: Dictionary = {}

	# compile every open script of the collection
	for save_data: HenSaveData in global.OPEN_SCRIPTS:
		var script_id: StringName = StringName(str(save_data.identity.id))
		_compile_script(script_id)
		compiled[script_id] = true

	# recompile external dependents not already compiled
	var recompiled_count: int = 0
	for open_script: HenSaveData in global.OPEN_SCRIPTS:
		for dependent_id: StringName in map_deps.check_dependencies(open_script.identity.id):
			if not compiled.has(dependent_id):
				_compile_script(dependent_id)
				compiled[dependent_id] = true
				recompiled_count += 1

	var end_time: int = Time.get_ticks_msec()
	var compilation_time: float = (end_time - start_time)
	
	var msg: String = "Saved & Compiled in " + str(compilation_time) + "ms"
	if recompiled_count > 0:
		msg += " (" + str(recompiled_count) + " dependents recompiled)"
		
	toast.notify.call_deferred(msg, HenToast.MessageType.SUCCESS)
	
	if Engine.is_editor_hint():
		EditorInterface.get_resource_filesystem().scan()
		
	var signal_bus: HenSignalBus = Engine.get_singleton(&'SignalBus')
	signal_bus.scripts_generation_finished.emit.call_deferred()


static func _compile_script(_id: StringName) -> void:
	var save_dir: String = HenUtils.get_script_dir(_id)
	var save_path: String = save_dir.path_join(HenEnums.SAVE_FILE)
	if not FileAccess.file_exists(save_path):
		push_error("Cannot compile script, save data not found: " + save_path)
		return
		
	var save_data: HenSaveData = load(save_path)
	if not save_data:
		push_error("Failed to load save data for compilation: " + save_path)
		return
	
	recalculate_dependencies(save_data)
	
	var identity_path: String = save_dir.path_join(HenEnums.IDENTITY_FILE)
	ResourceSaver.save(save_data.identity, identity_path)
	
	var map_deps: HenMapDependencies = Engine.get_singleton('MapDependencies')
	map_deps.update_project_data(_id)
		
	var code_gen: HenCodeGeneration = Engine.get_singleton('CodeGeneration')
	var code: String = code_gen.get_code(save_data)
	
	# Determine where to write the compiled script
	var script_path: String = HenUtils.script_path_of(save_data.identity)
	if script_path.is_empty():
		script_path = HenEnums.HENGO_SCRIPTS_PATH + str(_id) + ".gd"

	var script_dir: String = script_path.get_base_dir()
	if not DirAccess.dir_exists_absolute(script_dir):
		DirAccess.make_dir_recursive_absolute(script_dir)

	var file: FileAccess = FileAccess.open(script_path, FileAccess.WRITE)
	if file:
		print('Compiled: ', _id, ' -> ', script_path)
		file.store_string(code)
		file.close()
	else:
		push_error('Failed to write compiled script: ' + script_path)


static func recalculate_dependencies(save_data: HenSaveData) -> void:
	# dependencies came from the cnodes a route held; actions declare theirs
	# through bindings, which the map rebuilds from the save data itself
	save_data.identity.deps.clear()
	save_data.identity.detailed_deps.clear()
	

