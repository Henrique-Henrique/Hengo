class_name HenSaveScript extends Node


const TEMP_EXT: String = '.tmp'
const BACKUP_EXT: String = '.bkp'

# a transactional save process that ensures data integrity.
# if any step fails, it reverts all changes.
static func save_data(save_config: HenSaver.SaveConfig) -> void:
	if not _backup_existing_files(save_config):
		push_error("Save process failed during backup creation.")
		rollback(save_config)
		return

	if not _save_temporary_data(save_config):
		push_error("Save process failed while writing temporary files.")
		rollback(save_config)
		return

	if not _commit_saved_data(save_config):
		push_error("Save process failed while committing changes.")
		rollback(save_config)
		return

	_cleanup_backups(save_config)
	_save_gdscript_source(save_config)

	var script_list: PackedStringArray = []
	for config in save_config.script_list:
		script_list.append(ResourceUID.get_id_path(config.id))

	print("Successfully saved")
	HenGlobal.SIGNAL_BUS.scripts_generation_finished.emit.call_deferred(script_list)


# reverts changes by restoring backups and cleaning temporary files.
static func rollback(save_config: HenSaver.SaveConfig) -> void:
	for config in save_config.script_list:
		var path: StringName = HenLoader.get_data_path(config.id)
		var backup_path: StringName = path + BACKUP_EXT
		var temp_path: StringName = path + TEMP_EXT

		# restore the original file from the backup, if it exists
		if FileAccess.file_exists(backup_path):
			var result: int = DirAccess.rename_absolute(backup_path, path)
			if result != OK:
				push_error("Rollback failed to restore backup for: ", path)
		
		# remove any lingering temp files
		if FileAccess.file_exists(temp_path):
			DirAccess.remove_absolute(temp_path)


# creates a .bak file for each script data file.
static func _backup_existing_files(save_config: HenSaver.SaveConfig) -> bool:
	for config in save_config.script_list:
		var res_path: StringName = HenLoader.get_data_path(config.id)
		var backup_path: StringName = res_path + BACKUP_EXT

		# rename existing file to .bak, or create an empty .bak if no file exists.
		# this ensures the rollback can restore a non-existent state if needed.
		if FileAccess.file_exists(res_path):
			var result: int = DirAccess.rename_absolute(res_path, backup_path)
			if result != OK:
				return false
		else:
			var file: FileAccess = FileAccess.open(backup_path, FileAccess.WRITE)
			if not file:
				return false
			file.close()
			
	return true


# saves the new data to temporary .tmp files.
static func _save_temporary_data(save_config: HenSaver.SaveConfig) -> bool:
	for config in save_config.script_list:
		var temp_path: StringName = HenLoader.get_data_path(config.id) + TEMP_EXT
		var is_success: bool = HenScriptData.save(config.script_data, temp_path)
		if not is_success:
			return false
			
	return true


# renames all .tmp files to their final names, committing the changes.
static func _commit_saved_data(save_config: HenSaver.SaveConfig) -> bool:
	for config in save_config.script_list:
		var final_path: StringName = HenLoader.get_data_path(config.id)
		var temp_path: StringName = final_path + TEMP_EXT
		
		var result: int = DirAccess.rename_absolute(temp_path, final_path)
		if result != OK:
			return false
			
	return true


# removes all the .bak files after a successful save.
static func _cleanup_backups(save_config: HenSaver.SaveConfig) -> void:
	for config in save_config.script_list:
		var backup_path: StringName = HenLoader.get_data_path(config.id) + BACKUP_EXT
		if FileAccess.file_exists(backup_path):
			DirAccess.remove_absolute(backup_path)


# saves the final gdscript source code files.
static func _save_gdscript_source(save_config: HenSaver.SaveConfig) -> void:
	for config in save_config.script_list:
		HenScriptData.save_code(config.script_data, config.id)