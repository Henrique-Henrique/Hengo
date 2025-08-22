class_name HenSaveScript extends RefCounted

const BACKUP_EXT: String = ".bak"
const TEMP_EXT: String = ".tmp"

static func save_data(save_config: HenSaver.SaveConfig) -> void:
	# orchestrates a transactional save process.
	# if any critical step fails, it logs the error and triggers a rollback.
	if not _create_backups(save_config):
		push_error("Save process failed: could not create backups. Rolling back.")
		rollback(save_config)
		return

	if not _save_temporary_files(save_config):
		push_error("Save process failed: could not save temporary files. Rolling back.")
		rollback(save_config)
		return

	if not _commit_changes(save_config):
		push_error("Save process failed: could not commit changes. Rolling back.")
		rollback(save_config)
		return

	_finalize_save_process(save_config)
	print("Successfully saved")


static func rollback(save_config: HenSaver.SaveConfig) -> void:
	for config in save_config.script_list:
		var paths: Dictionary = _get_resource_paths(config.id)

		# attempt to restore the original file from its backup
		if FileAccess.file_exists(paths.backup):
			var result: int = DirAccess.rename_absolute(paths.backup, paths.base)
			if result != OK:
				push_error("Rollback failed to restore backup for: ", paths.base)
		
		# ensure any temporary file is removed
		if FileAccess.file_exists(paths.temp):
			DirAccess.remove_absolute(paths.temp)


# returns a dictionary with base, backup, and temp paths for a given resource id
static func _get_resource_paths(id: int) -> Dictionary:
	var base_path: StringName = HenLoader.get_data_path(id)
	return {
		"base": base_path,
		"backup": base_path + BACKUP_EXT,
		"temp": base_path + TEMP_EXT,
	}


# creates a backup of each existing file
static func _create_backups(save_config: HenSaver.SaveConfig) -> bool:
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
			return false
			
	return true


# saves the new data to temporary files
static func _save_temporary_files(save_config: HenSaver.SaveConfig) -> bool:
	for config in save_config.script_list:
		var paths: Dictionary = _get_resource_paths(config.id)
		if not HenScriptData.save(config.script_data, paths.temp):
			return false
			
	return true


# renames temporary files to their final names, committing the changes
static func _commit_changes(save_config: HenSaver.SaveConfig) -> bool:
	for config in save_config.script_list:
		var paths: Dictionary = _get_resource_paths(config.id)
		var result: int = DirAccess.rename_absolute(paths.temp, paths.base)

		if result != OK:
			return false
			
	return true


# cleans up backup files, saves final gdscript code, and emits the completion signal
static func _finalize_save_process(save_config: HenSaver.SaveConfig) -> void:
	var script_list: PackedStringArray = []
	for config in save_config.script_list:
		var paths: Dictionary = _get_resource_paths(config.id)

		if FileAccess.file_exists(paths.backup):
			DirAccess.remove_absolute(paths.backup)

		script_list.append(ResourceUID.get_id_path(config.id))

	for config in save_config.script_list:
		HenScriptData.save_code(config.script_data, config.id)
		
	HenGlobal.SIGNAL_BUS.scripts_generation_finished.emit.call_deferred(script_list)