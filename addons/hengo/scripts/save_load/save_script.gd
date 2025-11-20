class_name HenSaveScript extends RefCounted

const BACKUP_EXT: String = ".bak"
const TEMP_EXT: String = ".tmp"

static func save_data(save_config: HenSaver.SaveConfig) -> void:
	var toast: HenToast = Engine.get_singleton(&'ToastContainer')

	if not _create_backups(save_config):
		toast.notify.call_deferred("Save failed: unable to create backups", HenToast.MessageType.ERROR)
		rollback(save_config)
		return

	if not _save_temporary_files(save_config):
		toast.notify.call_deferred("Save failed: unable to write temporary files", HenToast.MessageType.ERROR)
		rollback(save_config)
		return

	if not _commit_changes(save_config):
		toast.notify.call_deferred("Save failed: unable to commit changes", HenToast.MessageType.ERROR)
		rollback(save_config)
		return

	_finalize_save_process(save_config)


static func rollback(save_config: HenSaver.SaveConfig) -> void:
	var toast: HenToast = Engine.get_singleton(&'ToastContainer')
	toast.notify.call_deferred("Rolling back save process", HenToast.MessageType.ERROR)
	
	for config in save_config.script_list:
		var paths: Dictionary = _get_resource_paths(config.id)

		# attempt to restore the original file from its backup
		if FileAccess.file_exists(paths.backup):
			var result: int = DirAccess.rename_absolute(paths.backup, paths.base)
			if result != OK:
				toast.notify.call_deferred("Rollback failed: cannot restore backup for " + paths.base, HenToast.MessageType.ERROR)
		
		# ensure any temporary file is removed
		if FileAccess.file_exists(paths.temp):
			DirAccess.remove_absolute(paths.temp)


# returns a dictionary with base, backup, and temp paths for a given resource id
static func _get_resource_paths(id: int) -> Dictionary:
	var base_path: StringName = (Engine.get_singleton(&'Loader') as HenLoader).get_data_path(id)
	return {
		"base": base_path,
		"backup": base_path + BACKUP_EXT,
		"temp": base_path + TEMP_EXT,
	}


# creates a backup of each existing file
static func _create_backups(save_config: HenSaver.SaveConfig) -> bool:
	var loader: HenLoader = Engine.get_singleton(&'Loader')

	for config in save_config.script_list:
		var paths: Dictionary = _get_resource_paths(config.id)
		var result: int = OK

		if FileAccess.file_exists(paths.base):
			result = DirAccess.rename_absolute(paths.base, paths.backup)
		else:
			# if the original file doesn't exist, create an empty backup
			# this simplifies rollback logic, as it can assume a backup always exists
			var file: FileAccess = FileAccess.open(paths.backup, FileAccess.WRITE)
			if file:
				file.close()
			else:
				result = FAILED

		if result != OK:
			(Engine.get_singleton(&'ToastContainer') as HenToast).notify.call_deferred("Failed to create backup for: " + loader.get_data_path(config.id), HenToast.MessageType.ERROR)
			return false
	
	return true


# saves the new data to temporary files
static func _save_temporary_files(save_config: HenSaver.SaveConfig) -> bool:
	for config in save_config.script_list:
		var paths: Dictionary = _get_resource_paths(config.id)
		
		if not HenScriptData.save(config.script_data, paths.temp):
			(Engine.get_singleton(&'ToastContainer') as HenToast).notify.call_deferred("Failed to write temp file: " + paths.temp, HenToast.MessageType.ERROR)
			return false
		
	return true


# renames temporary files to their final names, committing the changes
static func _commit_changes(save_config: HenSaver.SaveConfig) -> bool:
	for config in save_config.script_list:
		var paths: Dictionary = _get_resource_paths(config.id)
		var result: int = DirAccess.rename_absolute(paths.temp, paths.base)

		if result != OK:
			(Engine.get_singleton(&'ToastContainer') as HenToast).notify.call_deferred("Failed to commit changes for: " + paths.base, HenToast.MessageType.ERROR)
			return false
	
	return true


# cleans up backup files, saves final gdscript code, and emits the completion signal
static func _finalize_save_process(save_config: HenSaver.SaveConfig) -> void:
	var script_list: PackedStringArray = []
	
	# clean up backup files
	for config in save_config.script_list:
		var paths: Dictionary = _get_resource_paths(config.id)

		if FileAccess.file_exists(paths.backup):
			DirAccess.remove_absolute(paths.backup)

		if ResourceUID.has_id(config.id):
			script_list.append(ResourceUID.get_id_path(config.id))

	# generate gdscript code
	for config in save_config.script_list:
		HenScriptData.save_code(config.script_data, config.id)
	
	
	var signal_bus: HenSignalBus = Engine.get_singleton(&'SignalBus')
	var toast: HenToast = Engine.get_singleton(&'ToastContainer')
	signal_bus.scripts_generation_finished.emit.call_deferred(script_list)
	toast.notify.call_deferred("Scripts saved successfully", HenToast.MessageType.SUCCESS)