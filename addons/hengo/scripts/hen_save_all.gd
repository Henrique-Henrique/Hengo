@tool
class_name HenSaveAll
extends RefCounted

const COMPILE_ALL_REPORT_POPUP = preload('res://addons/hengo/scenes/utils/compile_all_report_popup.tscn')

var _is_compiling: bool = false
var _report: Dictionary = {}

signal batch_started
signal batch_finished


# starts the batch compilation process
func start() -> void:
	if _is_compiling:
		var running_toast: HenToast = Engine.get_singleton(&'ToastContainer')
		if running_toast:
			running_toast.notify.call_deferred('Batch compilation already running.', HenToast.MessageType.INFO)
		return

	var thread_helper: HenThreadHelper = Engine.get_singleton(&'ThreadHelper')
	if not thread_helper:
		push_error('ThreadHelper singleton not found.')
		return

	_is_compiling = true
	_report = {}

	var toast: HenToast = Engine.get_singleton(&'ToastContainer')
	if toast:
		toast.notify.call_deferred('Starting batch compilation...', HenToast.MessageType.INFO)

	batch_started.emit()

	thread_helper.add_task(_compile_task, _on_finished)


# returns whether compilation is currently active
func is_compiling() -> bool:
	return _is_compiling


# internal task that runs on a separate thread
func _compile_task() -> void:
	var signal_bus: HenSignalBus = Engine.get_singleton(&'SignalBus')
	if signal_bus:
		signal_bus.is_batch_loading = true

	var started_at: int = Time.get_ticks_msec()
	var report: Dictionary = {
		success = false,
		items = [],
		total = 0,
		success_count = 0,
		failed_count = 0,
		skipped_count = 0,
		aborted = false,
		elapsed_ms = 0
	}

	if not DirAccess.dir_exists_absolute(HenEnums.HENGO_SAVE_PATH):
		report.items.append({
			script_id = '-',
			script_name = '-',
			status = 'failed',
			message = 'Save folder not found: ' + str(HenEnums.HENGO_SAVE_PATH),
			errors = ['Missing save directory']
		})
		report.total = 1
		report.failed_count = 1
		report.aborted = true
		report.elapsed_ms = Time.get_ticks_msec() - started_at
		_report = report
		if signal_bus:
			signal_bus.is_batch_loading = false
		return

	var save_dirs: PackedStringArray = DirAccess.get_directories_at(HenEnums.HENGO_SAVE_PATH)
	save_dirs.sort()
	report.total = save_dirs.size()

	var aborted: bool = false
	var abort_index: int = -1

	# dispatch all resource loads in parallel
	var save_paths: Array[String] = []
	var script_paths: Array[String] = []
	var identity_paths: Array[String] = []
	var save_exists: Array[bool] = []
	var up_to_date: Array[bool] = []
	var dirty_ids: Array[String] = []

	for idx: int in range(save_dirs.size()):
		var save_id: String = save_dirs[idx]
		var save_path: String = HenEnums.HENGO_SAVE_PATH.path_join(save_dirs[idx]).path_join('save' + HenEnums.SAVE_EXTENSION)
		var identity_path: String = HenEnums.HENGO_SAVE_PATH.path_join(save_id).path_join('identity' + HenEnums.SAVE_EXTENSION)
		var exists: bool = FileAccess.file_exists(save_path)

		save_paths.append(save_path)
		identity_paths.append(identity_path)
		save_exists.append(exists)

	var identities_info: Dictionary = _collect_identities_info(save_dirs, identity_paths)
	var dep_to_dependents: Dictionary = identities_info.get('dep_to_dependents', {})
	var script_display_names: Dictionary = identities_info.get('display_names', {})
	var identity_script_paths: Dictionary = identities_info.get('script_paths', {})

	_fill_missing_display_names_from_saves(save_dirs, save_paths, script_display_names)

	for idx: int in range(save_dirs.size()):
		var save_id: String = save_dirs[idx]
		var custom_path: String = str(identity_script_paths.get(save_id, ''))
		var script_path: String = custom_path if not custom_path.is_empty() else HenEnums.HENGO_SCRIPTS_PATH + save_id + '.gd'
		script_paths.append(script_path)

		var exists: bool = save_exists[idx]
		var is_up_to_date: bool = false
		if exists and _is_script_up_to_date(save_paths[idx], script_path):
			is_up_to_date = true

		up_to_date.append(is_up_to_date)
		if exists and not is_up_to_date:
			dirty_ids.append(save_id)

	var force_compile: Dictionary = {}
	var queue: Array[String] = dirty_ids.duplicate()
	var preloaded_saves: Dictionary = {}
	var map_deps: HenMapDependencies = Engine.get_singleton(&'MapDependencies')

	while not queue.is_empty():
		var current_id: String = queue.pop_front()
		if bool(force_compile.get(current_id, false)):
			continue

		force_compile[current_id] = true
		if not dep_to_dependents.has(current_id):
			continue

		var dependents: Array = dep_to_dependents[current_id]
		for dependent in dependents:
			var dependent_id: String = str(dependent)
			if bool(force_compile.get(dependent_id, false)):
				continue
			
			if not preloaded_saves.has(current_id):
				var idx: int = Array(save_dirs).find(current_id)
				if idx != -1 and save_exists[idx]:
					var temp_save: HenSaveData = ResourceLoader.load_threaded_get(save_paths[idx])
					if not temp_save:
						temp_save = ResourceLoader.load(save_paths[idx])
					if temp_save:
						var temp_ast: HenMapDependencies.ProjectAST = HenMapDependencies.ProjectAST.new()
						temp_ast.identity = temp_save.identity
						temp_ast.variables = temp_save.variables
						temp_ast.functions = temp_save.functions
						temp_ast.signals = temp_save.signals
						temp_ast.macros = temp_save.macros
						preloaded_saves[current_id] = temp_ast
					
			if not preloaded_saves.has(current_id):
				# fallback to full recompilation if we can't build a temporary AST
				queue.append(dependent_id)
				continue

			var dependent_ast: HenMapDependencies.ProjectAST = map_deps.ast_list.get(StringName(dependent_id))
			if not dependent_ast or not dependent_ast.identity:
				queue.append(dependent_id)
				continue
				
			var detailed_deps: Dictionary = dependent_ast.identity.detailed_deps
			if not detailed_deps.has(StringName(current_id)):
				queue.append(dependent_id)
				continue
				
			var deps: Array = detailed_deps[StringName(current_id)]
			var changed_ast: HenMapDependencies.ProjectAST = preloaded_saves[current_id]
			
			if map_deps._has_dependency_changed(deps, changed_ast):
				queue.append(dependent_id)

	# request threaded loads for saves that need compilation
	var requested_paths: Array[String] = []
	for idx: int in range(save_dirs.size()):
		if not save_exists[idx]:
			continue
		var save_id: String = save_dirs[idx]
		if not up_to_date[idx] or bool(force_compile.get(save_id, false)):
			ResourceLoader.load_threaded_request(save_paths[idx])
			requested_paths.append(save_paths[idx])

	if not DirAccess.dir_exists_absolute(HenEnums.HENGO_SCRIPTS_PATH):
		DirAccess.make_dir_absolute(HenEnums.HENGO_SCRIPTS_PATH)

	var code_gen: HenCodeGeneration = Engine.get_singleton(&'CodeGeneration')
	var compiled_saves: Array[Dictionary] = []
	var consumed_paths: Array[String] = []

	for idx: int in range(save_dirs.size()):
		var save_id: String = save_dirs[idx]
		var save_path: String = save_paths[idx]
		var script_path: String = script_paths[idx]
		var item: Dictionary = {
			script_id = save_id,
			script_name = str(script_display_names.get(save_id, save_id)),
			status = 'pending',
			message = '',
			errors = []
		}

		if not save_exists[idx]:
			item.status = 'failed'
			item.message = 'Missing save file.'
			item.errors = ['Expected file: ' + save_path]
			report.items.append(item)
			report.failed_count += 1
			aborted = true
			abort_index = idx
			break

		var needs_compile: bool = (not up_to_date[idx]) or bool(force_compile.get(save_id, false))
		if not needs_compile:
			item.status = 'skipped'
			item.message = 'Skipped (up to date).'
			report.items.append(item)
			report.skipped_count += 1
			continue

		var save_data: HenSaveData = ResourceLoader.load_threaded_get(save_path)
		consumed_paths.append(save_path)

		if not save_data:
			item.status = 'failed'
			item.message = 'Could not load save resource.'
			item.errors = ['Failed to load: ' + save_path]
			report.items.append(item)
			report.failed_count += 1
			aborted = true
			abort_index = idx
			break

		if save_data.identity:
			item.script_name = save_data.identity.name

		# collect all routes once and reuse for both validation and deps
		var routes: Array = _collect_routes(save_data)

		# validate using check_errors (no UI side-effects)
		var graph_errors: Array[String] = _validate_routes(save_data, routes)
		if not graph_errors.is_empty():
			item.status = 'failed'
			item.message = 'Graph validation failed.'
			item.errors = graph_errors
			report.items.append(item)
			report.failed_count += 1
			aborted = true
			abort_index = idx
			break

		# recalculate deps using the same routes
		_recalculate_deps_from_routes(save_data, routes)

		code_gen.reset()
		var code: String = code_gen.get_code(save_data)
		var flow_error_count: int = code_gen.flow_errors.size()
		if flow_error_count > 0:
			item.status = 'failed'
			item.message = 'Code generation produced flow errors.'
			item.errors = ['Flow errors count: ' + str(flow_error_count)]
			report.items.append(item)
			report.failed_count += 1
			aborted = true
			abort_index = idx
			break

		# write script directly
		var script_dir: String = script_path.get_base_dir()
		if not DirAccess.dir_exists_absolute(script_dir):
			DirAccess.make_dir_recursive_absolute(script_dir)
		var file: FileAccess = FileAccess.open(script_path, FileAccess.WRITE)
		if not file:
			item.status = 'failed'
			item.message = 'Failed to write script file.'
			item.errors = ['Could not open: ' + script_path]
			report.items.append(item)
			report.failed_count += 1
			aborted = true
			abort_index = idx
			break

		file.store_string(code)
		file.close()

		# keep reference for in-memory ast update
		compiled_saves.append({id = save_id, save_data = save_data})

		item.status = 'success'
		item.message = 'Compiled successfully.'
		report.items.append(item)
		report.success_count += 1

	if aborted:
		report.aborted = true
		var start_skip: int = abort_index + 1
		for i: int in range(start_skip, save_dirs.size()):
			var pending_id: String = save_dirs[i]
			report.items.append({
				script_id = pending_id,
				script_name = str(script_display_names.get(pending_id, pending_id)),
				status = 'skipped',
				message = 'Skipped because batch was aborted after a failure.',
				errors = []
			})
			report.skipped_count += 1

		# consume pending threaded requests to avoid leaks
		for path: String in requested_paths:
			if not consumed_paths.has(path):
				ResourceLoader.load_threaded_get(path)
	else:
		# update ast directly from memory, no disk I/O
		for entry: Dictionary in compiled_saves:
			map_deps.update_project_data_from_save(StringName(entry.id), entry.save_data)

	report.success = not aborted
	report.elapsed_ms = Time.get_ticks_msec() - started_at
	_report = report

	if signal_bus:
		signal_bus.is_batch_loading = false


# handles the cleanup and callback when the task finishes
func _on_finished() -> void:
	_is_compiling = false
	batch_finished.emit()

	var popup: HenCompileAllReportPopup = COMPILE_ALL_REPORT_POPUP.instantiate()
	popup.report = _report
	(Engine.get_singleton(&'GeneralPopup') as HenGeneralPopup).show_content(popup, 'Compile All Saves')

	if Engine.is_editor_hint():
		EditorInterface.get_resource_filesystem().scan()

	var toast: HenToast = Engine.get_singleton(&'ToastContainer')
	if toast:
		if bool(_report.get('success', false)):
			toast.notify.call_deferred('Batch compilation completed successfully.', HenToast.MessageType.SUCCESS)
		else:
			toast.notify.call_deferred('Batch compilation failed. See report for details.', HenToast.MessageType.ERROR)


# collects all routes from save data in a single pass
func _collect_routes(save_data: HenSaveData) -> Array:
	var routes: Array = [save_data.get_base_route()]

	for state: HenSaveState in save_data.states:
		routes.append(state.get_route(save_data))
	for func_data: HenSaveFunc in save_data.functions:
		routes.append(func_data.get_route(save_data))
	for macro: HenSaveMacro in save_data.macros:
		routes.append(macro.get_route(save_data))
	for callback_data: HenSaveSignalCallback in save_data.signals_callback:
		routes.append(callback_data.get_route(save_data))

	return routes


# validates all cnodes in the given routes using check_errors (no UI updates)
func _validate_routes(save_data: HenSaveData, routes: Array) -> Array[String]:
	var errors: Array[String] = []

	for route in routes:
		if not route:
			continue
		for vc: HenVirtualCNode in route.virtual_cnode_list:
			var node_errors: Array = vc.check_errors(save_data)
			for err in node_errors:
				errors.append(str(err.get('description', 'Unknown graph error')))

	return errors


# recalculates deps from pre-collected routes
func _recalculate_deps_from_routes(save_data: HenSaveData, routes: Array) -> void:
	save_data.identity.deps.clear()
	save_data.identity.detailed_deps.clear()

	for route in routes:
		if not route:
			continue
		HenSaver._process_cnodes_for_deps(save_data, route.virtual_cnode_list)


func _is_script_up_to_date(save_path: String, script_path: String) -> bool:
	if not FileAccess.file_exists(script_path):
		return false

	var save_mtime: int = int(FileAccess.get_modified_time(save_path))
	if save_mtime <= 0:
		return false

	var script_mtime: int = int(FileAccess.get_modified_time(script_path))
	if script_mtime <= 0:
		return false

	return script_mtime >= save_mtime


func _collect_identities_info(save_dirs: PackedStringArray, identity_paths: Array[String]) -> Dictionary:
	# request threaded loads for all existing identity files
	var valid_indices: Array[int] = []
	var script_display_names: Dictionary = {}
	var identity_script_paths: Dictionary = {}
	for idx: int in range(save_dirs.size()):
		var save_id: String = str(save_dirs[idx])
		script_display_names[save_id] = save_id
		if FileAccess.file_exists(identity_paths[idx]):
			ResourceLoader.load_threaded_request(identity_paths[idx])
			valid_indices.append(idx)

	var dep_to_dependents: Dictionary = {}

	for idx: int in valid_indices:
		var identity: HenSaveDataIdentity = ResourceLoader.load_threaded_get(identity_paths[idx])
		if not identity:
			continue
		var current_id: String = str(save_dirs[idx])
		var identity_name: String = str(identity.name)
		if not identity_name.is_empty():
			script_display_names[current_id] = identity_name

		# store custom script path if set
		if not identity.script_path.is_empty():
			identity_script_paths[current_id] = identity.script_path

		for dep in identity.deps:
			var dep_id: String = str(dep)
			if dep_id.is_empty():
				continue
			if not dep_to_dependents.has(dep_id):
				dep_to_dependents[dep_id] = []
			(dep_to_dependents[dep_id] as Array).append(str(save_dirs[idx]))

	return {
		dep_to_dependents = dep_to_dependents,
		display_names = script_display_names,
		script_paths = identity_script_paths
	}


func _fill_missing_display_names_from_saves(save_dirs: PackedStringArray, save_paths: Array[String], script_display_names: Dictionary) -> void:
	for idx: int in range(save_dirs.size()):
		var save_id: String = str(save_dirs[idx])
		var display_name: String = str(script_display_names.get(save_id, save_id))
		if display_name != save_id:
			continue
		if not FileAccess.file_exists(save_paths[idx]):
			continue

		var save_data: HenSaveData = ResourceLoader.load(save_paths[idx])
		if not save_data or not save_data.identity:
			continue

		var resolved_name: String = str(save_data.identity.name)
		if not resolved_name.is_empty():
			script_display_names[save_id] = resolved_name
