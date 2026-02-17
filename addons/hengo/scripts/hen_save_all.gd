@tool
class_name HenSaveAll
extends RefCounted

const COMPILE_ALL_REPORT_POPUP = preload('res://addons/hengo/scenes/utils/compile_all_report_popup.tscn')

var _is_compiling: bool = false
var _report: Dictionary = {}


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

	thread_helper.add_task(_compile_task, _on_finished)


# returns whether compilation is currently active
func is_compiling() -> bool:
	return _is_compiling


# internal task that runs on a separate thread
func _compile_task() -> void:
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
		report.success = false
		report.aborted = true
		report.items = [ {
			script_id = '-',
			script_name = '-',
			status = 'failed',
			message = 'Save folder not found: ' + str(HenEnums.HENGO_SAVE_PATH),
			errors = ['Missing save directory']
		}]
		report.total = 1
		report.failed_count = 1
		report.elapsed_ms = Time.get_ticks_msec() - started_at
		_report = report
		return

	var save_dirs: PackedStringArray = DirAccess.get_directories_at(HenEnums.HENGO_SAVE_PATH)
	save_dirs.sort()
	report.total = save_dirs.size()

	var staged_scripts: Dictionary = {}
	var staged_identity: Dictionary = {}
	var aborted: bool = false
	var abort_index: int = -1

	for idx: int in range(save_dirs.size()):
		var save_id: StringName = StringName(save_dirs[idx])
		var item: Dictionary = {
			script_id = str(save_id),
			script_name = str(save_id),
			status = 'pending',
			message = '',
			errors = []
		}

		var save_path: String = HenEnums.HENGO_SAVE_PATH.path_join(str(save_id)).path_join('save.tres')
		if not FileAccess.file_exists(save_path):
			item.status = 'failed'
			item.message = 'Missing save file.'
			item.errors = ['Expected file: ' + save_path]
			(report.items as Array).append(item)
			aborted = true
			abort_index = idx
			break

		var save_data: HenSaveData = ResourceLoader.load(save_path)
		if not save_data:
			item.status = 'failed'
			item.message = 'Could not load save resource.'
			item.errors = ['Failed to load: ' + save_path]
			(report.items as Array).append(item)
			aborted = true
			abort_index = idx
			break

		if save_data.identity:
			item.script_name = save_data.identity.name

		var graph_errors: Array[String] = _validate_save_data_errors(save_data)
		if not graph_errors.is_empty():
			item.status = 'failed'
			item.message = 'Graph validation failed.'
			item.errors = graph_errors
			(report.items as Array).append(item)
			aborted = true
			abort_index = idx
			break

		HenSaver.recalculate_dependencies(save_data)

		var code_gen: HenCodeGeneration = Engine.get_singleton(&'CodeGeneration')
		var code: String = code_gen.get_code(save_data)
		var flow_errors: Array = code_gen.flow_errors.duplicate(true)
		if not flow_errors.is_empty():
			item.status = 'failed'
			item.message = 'Code generation produced flow errors.'
			item.errors = ['Flow errors count: ' + str(flow_errors.size())]
			(report.items as Array).append(item)
			aborted = true
			abort_index = idx
			break

		var compile_check: Dictionary = _validate_generated_script(code)
		if int(compile_check.error) != OK:
			item.status = 'failed'
			item.message = 'Generated GDScript failed compile check.'
			item.errors = ['Error code: %s (%s)' % [str(compile_check.error), str(compile_check.error_text)]]
			(report.items as Array).append(item)
			aborted = true
			abort_index = idx
			break

		staged_scripts[save_id] = {
			path = HenEnums.HENGO_SCRIPTS_PATH + str(save_id) + '.gd',
			code = code
		}
		staged_identity[save_id] = {
			path = HenEnums.HENGO_SAVE_PATH.path_join(str(save_id)).path_join('identity.tres'),
			identity = save_data.identity
		}

		item.status = 'success'
		item.message = 'Compiled and validated in memory.'
		(report.items as Array).append(item)

	if aborted:
		report.aborted = true
		var start_skip: int = abort_index + 1
		for i: int in range(start_skip, save_dirs.size()):
			var skipped_id: StringName = StringName(save_dirs[i])
			(report.items as Array).append({
				script_id = str(skipped_id),
				script_name = str(skipped_id),
				status = 'skipped',
				message = 'Skipped because batch was aborted after a failure.',
				errors = []
			})
	else:
		var persist_result: Dictionary = _persist_compiled_batch(staged_scripts, staged_identity)
		report.success = bool(persist_result.success)
		report.aborted = not bool(persist_result.success)

		if bool(persist_result.success):
			var map_deps: HenMapDependencies = Engine.get_singleton(&'MapDependencies')
			for save_id: StringName in staged_scripts.keys():
				map_deps.update_project_data(save_id)
		else:
			var failed_id: String = str(persist_result.get('failed_id', ''))
			var reason: String = str(persist_result.get('reason', 'Unknown write error.'))
			for item_ref in report.items:
				var data: Dictionary = item_ref
				if data.status == 'success':
					if data.script_id == failed_id:
						data.status = 'failed'
						data.message = 'Failed to persist compiled output.'
						data.errors = [reason]
					else:
						data.status = 'skipped'
						data.message = 'Skipped because write phase failed.'
						data.errors = []

	if not report.has('success') or report.aborted:
		report.success = false

	for item_ref in report.items:
		var item_data: Dictionary = item_ref
		match str(item_data.get('status', '')):
			'success':
				report.success_count = int(report.success_count) + 1
			'failed':
				report.failed_count = int(report.failed_count) + 1
			'skipped':
				report.skipped_count = int(report.skipped_count) + 1

	report.elapsed_ms = Time.get_ticks_msec() - started_at
	_report = report


# handles the cleanup and callback when the task finishes
func _on_finished() -> void:
	_is_compiling = false

	var popup: HenCompileAllReportPopup = COMPILE_ALL_REPORT_POPUP.instantiate()
	popup.report = _report
	(Engine.get_singleton(&'GeneralPopup') as HenGeneralPopup).show_content(popup, 'Compile All Saves')

	var toast: HenToast = Engine.get_singleton(&'ToastContainer')
	if toast:
		if bool(_report.get('success', false)):
			toast.notify.call_deferred('Batch compilation completed successfully.', HenToast.MessageType.SUCCESS)
		else:
			toast.notify.call_deferred('Batch compilation failed. See report for details.', HenToast.MessageType.ERROR)


# writes the compiled scripts to disk
func _persist_compiled_batch(staged_scripts: Dictionary, staged_identity: Dictionary) -> Dictionary:
	if not DirAccess.dir_exists_absolute(HenEnums.HENGO_SCRIPTS_PATH):
		DirAccess.make_dir_absolute(HenEnums.HENGO_SCRIPTS_PATH)

	var temp_paths: Array[String] = []
	for save_id in staged_scripts.keys():
		var dt: Dictionary = staged_scripts[save_id]
		var final_path: String = str(dt.path)
		var temp_path: String = final_path + '.tmp_hengo_compile'
		var file: FileAccess = FileAccess.open(temp_path, FileAccess.WRITE)
		if not file:
			_cleanup_temp_files(temp_paths)
			return {
				success = false,
				failed_id = str(save_id),
				reason = 'Failed to create temporary file: ' + temp_path
			}
		file.store_string(str(dt.code))
		file.close()
		temp_paths.append(temp_path)

	for save_id in staged_scripts.keys():
		var dt: Dictionary = staged_scripts[save_id]
		var final_path: String = str(dt.path)
		var temp_path: String = final_path + '.tmp_hengo_compile'
		var move_result: int = DirAccess.rename_absolute(temp_path, final_path)
		if move_result != OK:
			_cleanup_temp_files(temp_paths)
			return {
				success = false,
				failed_id = str(save_id),
				reason = 'Failed to replace script file: ' + final_path
			}

	for save_id in staged_identity.keys():
		var identity_dt: Dictionary = staged_identity[save_id]
		var identity_res: Resource = identity_dt.identity
		var identity_path: String = str(identity_dt.path)
		var save_result: int = ResourceSaver.save(identity_res, identity_path)
		if save_result != OK:
			return {
				success = false,
				failed_id = str(save_id),
				reason = 'Failed to save identity resource: ' + identity_path
			}

	return {
		success = true
	}


# removes temporary files in case of failure
func _cleanup_temp_files(temp_paths: Array[String]) -> void:
	for temp_path: String in temp_paths:
		if FileAccess.file_exists(temp_path):
			DirAccess.remove_absolute(temp_path)


# validates that the generated gdscript code is valid
func _validate_generated_script(code: String) -> Dictionary:
	var script := GDScript.new()
	script.source_code = code
	var error: int = script.reload()
	return {
		error = error,
		error_text = error_string(error)
	}


# validates that the save data is correct
func _validate_save_data_errors(save_data: HenSaveData) -> Array[String]:
	var errors: Array[String] = []
	var routes: Array = [save_data.get_base_route()]

	for state: HenSaveState in save_data.states:
		routes.append(state.get_route(save_data))
	for func_data: HenSaveFunc in save_data.functions:
		routes.append(func_data.get_route(save_data))
	for macro: HenSaveMacro in save_data.macros:
		routes.append(macro.get_route(save_data))
	for callback_data: HenSaveSignalCallback in save_data.signals_callback:
		routes.append(callback_data.get_route(save_data))

	for route in routes:
		if not route:
			continue
		for vc: HenVirtualCNode in route.virtual_cnode_list:
			var node_errors: Array = vc.validate_errors(save_data)
			for err in node_errors:
				errors.append(str(err.get('description', 'Unknown graph error')))

	return errors
