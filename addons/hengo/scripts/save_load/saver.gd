@tool
class_name HenSaver extends Node

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

	# ---------------------------------------------------------------------------- #
	# Side Bar List
	script_data.side_bar_list = HenGlobal.SIDE_BAR_LIST.get_save(script_data)

	# ---------------------------------------------------------------------------- #
	var v_cnode_list: Array[Dictionary] = []

	for v_cnode: HenVirtualCNode in HenGlobal.BASE_ROUTE.get_ref().virtual_cnode_list:
		v_cnode_list.append(v_cnode.get_save(script_data))

		if v_cnode.identity.type == HenVirtualCNode.Type.STATE_EVENT:
			script_data.state_event_list.append(v_cnode.identity.name)
			
	script_data.virtual_cnode_list = v_cnode_list

	return script_data


static func save() -> void:
	# HenGlobal.SIGNAL_BUS.scripts_generation_started.emit()
	HenThreadHelper.add_task(start_generate.bind(true))


static func start_generate(_regenerate: bool = false) -> void:
	# check if save dierctory exists
	if not DirAccess.dir_exists_absolute('res://hengo'):
		DirAccess.make_dir_absolute('res://hengo')

	if not DirAccess.dir_exists_absolute('res://hengo/save'):
		DirAccess.make_dir_absolute('res://hengo/save')
		FileAccess.open('res://hengo/save/.gdignore', FileAccess.WRITE).close()

	# update current script data
	HenScriptDataCache.add_script_data(str(HenGlobal.script_config.id), generate_script_data())

	for script_in_cache: HenScriptData in HenScriptDataCache.SCRIPT_DATA_CACHE.values():
		generate(script_in_cache, ResourceLoader.get_resource_uid(script_in_cache.path), _regenerate)


static func generate(_script_data: HenScriptData, _script_id: int, _regenerate: bool = false) -> void:
	if not HenCheckerScriptData.is_script_data_valid(_script_data):
		return

	var _save_data: SaveData = SaveData.new(_script_id, _script_data)
	var _save_config: SaveConfig = SaveConfig.new()
	_save_config.add_script(_save_data)

	if _regenerate:
		HenCodeGeneration.regenerate(_save_config, _script_id, _script_data.side_bar_list)

	HenCodeGeneration.get_code(_script_data)
	HenSaveScript.save_data(_save_config)
	HenGlobal.SIGNAL_BUS.scripts_generation_finished.emit.call_deferred([])
