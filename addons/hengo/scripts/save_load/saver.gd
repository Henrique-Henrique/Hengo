@tool
class_name HenSaver extends Node

const TEMP_EXT: String = '.tmp'
const BACKUP_EXT: String = '.bkp'


class Saver:
	var task_id_list: Array[int] = []


class SaveData:
	var id: int
	var script_data: HenScriptData

	func _init(_id: int, _script_data: HenScriptData):
		id = _id
		script_data = _script_data


class SaveConfig:
	var script_list: Array[SaveData] = []

	func add_script(_save_data: SaveData) -> void:
		script_list.append(_save_data)


static func generate_script_data() -> HenScriptData:
	var script_data: HenScriptData = HenScriptData.new()

	script_data.path = HenGlobal.script_config.path
	script_data.type = HenGlobal.script_config.type
	script_data.node_counter = HenGlobal.node_counter
	script_data.prop_counter = HenGlobal.prop_counter

	# ---------------------------------------------------------------------------- #
	# Side Bar List
	script_data.side_bar_list = HenGlobal.SIDE_BAR_LIST.get_save()

	# ---------------------------------------------------------------------------- #
	var v_cnode_list: Array[Dictionary] = []

	for v_cnode: HenVirtualCNode in HenGlobal.BASE_ROUTE.ref.virtual_cnode_list:
		v_cnode_list.append(v_cnode.get_save())

		if v_cnode.type == HenVirtualCNode.Type.STATE_EVENT:
			script_data.state_event_list.append(v_cnode.name)
			
	script_data.virtual_cnode_list = v_cnode_list

	return script_data


static func save() -> void:
	HenGlobal.HENGO_SAVER = Saver.new()
	HenGlobal.SIGNAL_BUS.scripts_generation_started.emit()

	var script_data: HenScriptData = generate_script_data()
	var script_id: int = HenGlobal.script_config.id

	# check if save dierctory exists
	if not DirAccess.dir_exists_absolute('res://hengo'):
		DirAccess.make_dir_absolute('res://hengo')

	if not DirAccess.dir_exists_absolute('res://hengo/save'):
		DirAccess.make_dir_absolute('res://hengo/save')
		FileAccess.open('res://hengo/save/.gdignore', FileAccess.WRITE).close()

	HenGlobal.HENGO_SAVER.task_id_list.append(WorkerThreadPool.add_task(generate.bind(script_data, script_id, true)))


static func generate(_script_data: HenScriptData, _script_id: int, _regenerate: bool = false) -> void:
	var script_data: SaveData = SaveData.new(_script_id, _script_data)
	var save_config: SaveConfig = SaveConfig.new()
	save_config.add_script(script_data)

	if _regenerate:
		HenCodeGeneration.regenerate(save_config, _script_id, _script_data.side_bar_list)

	save_data(save_config)


static func save_data(_save_config: SaveConfig) -> void:
	# creating backup files
	for config in _save_config.script_list:
		var res_path: StringName = HenLoader.get_data_path(config.id)
		var result: int = OK

		if FileAccess.file_exists(res_path):
			result = DirAccess.rename_absolute(res_path, res_path + BACKUP_EXT)
		else:
			var file: FileAccess = FileAccess.open(res_path + BACKUP_EXT, FileAccess.WRITE)
			
			if file: file.close()
			else: result = false

		if result != OK:
			rollback(_save_config)
			return

	# saving temp files
	for config in _save_config.script_list:
		var valid: bool = HenScriptData.save(config.script_data, HenLoader.get_data_path(config.id) + TEMP_EXT)
		
		if not valid:
			rollback(_save_config)
			return

	# checking if all temp files are created
	for config in _save_config.script_list:
		if not FileAccess.file_exists(HenLoader.get_data_path(config.id) + TEMP_EXT):
			rollback(_save_config)
			return

	# renaming temp files to original files
	for config in _save_config.script_list:
		var result: int = DirAccess.rename_absolute(
			HenLoader.get_data_path(config.id) + TEMP_EXT,
			HenLoader.get_data_path(config.id)
		)

		print('saving -> ', HenLoader.get_data_path(config.id))

		if result != OK:
			rollback(_save_config)
			return

	var script_list: PackedStringArray = []

	# removing backup files
	for config in _save_config.script_list:
		var path: StringName = HenLoader.get_data_path(config.id)

		# remove backup
		if FileAccess.file_exists(path + BACKUP_EXT):
			DirAccess.remove_absolute(path + BACKUP_EXT)

		script_list.append(ResourceUID.get_id_path(config.id))

	# saving gdscript files
	for config in _save_config.script_list:
		HenScriptData.save_code(config.script_data, config.id)

	print('Successfully saved')
	HenGlobal.SIGNAL_BUS.scripts_generation_finished.emit.call_deferred(script_list)


static func rollback(_save_config: SaveConfig) -> void:
	for config in _save_config.script_list:
		var path: StringName = HenLoader.get_data_path(config.id)

		# renaming backup files to original files
		if FileAccess.file_exists(path + BACKUP_EXT):
			var result: int = DirAccess.rename_absolute(
				path + BACKUP_EXT,
				path
			)

			if result != OK:
				push_error('Rollback failed -> ', path)
			
		# removing temp files
		if FileAccess.file_exists(path + TEMP_EXT):
			DirAccess.remove_absolute(path + TEMP_EXT)