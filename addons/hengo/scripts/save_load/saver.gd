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
	var global: HenGlobal = Engine.get_singleton(&'Global')
	script_data.path = global.script_config.path
	script_data.type = global.script_config.type
	script_data.node_counter = global.node_counter

	# ---------------------------------------------------------------------------- #
	# Side Bar List
	script_data.side_bar_list = global.SIDE_BAR_LIST.get_save(script_data)

	# ---------------------------------------------------------------------------- #
	var v_cnode_list: Array[Dictionary] = []

	for v_cnode: HenVirtualCNode in global.BASE_ROUTE.get_ref().virtual_cnode_list:
		v_cnode_list.append(v_cnode.get_save(script_data))

		if v_cnode.identity.type == HenVirtualCNode.Type.STATE_EVENT:
			script_data.state_event_list.append(v_cnode.identity.name)
			
	script_data.virtual_cnode_list = v_cnode_list

	return script_data


static func save() -> void:
	(Engine.get_singleton(&'SignalBus') as HenSignalBus).scripts_generation_started.emit()
	(Engine.get_singleton(&'ThreadHelper') as HenThreadHelper).add_task(start_generate.bind(true))


static func save_new() -> void:
	var SAVE_PATH: String = 'res://hengo/save_2/'

	if not DirAccess.dir_exists_absolute('res://hengo'):
		DirAccess.make_dir_absolute('res://hengo')
	
	if not DirAccess.dir_exists_absolute(SAVE_PATH):
		DirAccess.make_dir_absolute(SAVE_PATH)
	
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var toast: HenToast = Engine.get_singleton(&'ToastContainer')
	var script_id: StringName = str(global.script_config.id)
	var script_path: StringName = SAVE_PATH + script_id
	var variables_path: StringName = script_path + '/variables/'

	if not DirAccess.dir_exists_absolute(script_path):
		DirAccess.make_dir_absolute(script_path)
	
	if not DirAccess.dir_exists_absolute(variables_path):
		DirAccess.make_dir_absolute(variables_path)
	
	var save_data: HenSaveData = global.SAVE_DATA
	print(save_data.variables.size())

	for variable: HenSaveVar in save_data.variables:
		variable.take_over_path(variables_path + str(variable.id) + '.tres')
		var var_result: int = ResourceSaver.save(variable)
		toast.notify.call_deferred(('Saved VAR: ' + str(variable.id)) if var_result == OK else 'Erro saving' + str(variable.id))

	save_data.take_over_path(script_path + '/save' + '.tres')
	var result: int = ResourceSaver.save(save_data)
	toast.notify.call_deferred(('Saved SAVE DATA: ' + str(save_data.id)) if result == OK else 'Erro saving' + str(save_data.id))


static func start_generate(_regenerate: bool = false) -> void:
	var start_time: int = Time.get_ticks_msec()
	var all_generated_scripts: Array[String] = []
	var script_data_cache: HenScriptDataCache = Engine.get_singleton(&'ScriptDataCache')
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var signal_bus: HenSignalBus = Engine.get_singleton(&'SignalBus')
	var toast: HenToast = Engine.get_singleton(&'ToastContainer')

	# check if save dierctory exists
	if not DirAccess.dir_exists_absolute('res://hengo'):
		DirAccess.make_dir_absolute('res://hengo')

	if not DirAccess.dir_exists_absolute('res://hengo/save'):
		DirAccess.make_dir_absolute('res://hengo/save')
		FileAccess.open('res://hengo/save/.gdignore', FileAccess.WRITE).close()

	save_new()

	# update current script data
	if not script_data_cache.add_script_data(str(global.script_config.id), generate_script_data()):
		signal_bus.scripts_generation_finished.emit.call_deferred([])
		return

	for script_in_cache: HenScriptData in script_data_cache.SCRIPT_DATA_CACHE.values():
		var script_id: int = ResourceLoader.get_resource_uid(script_in_cache.path)
		var generated_scripts: Array[String] = generate(script_in_cache, script_id, _regenerate)
		for script_name in generated_scripts:
			if not all_generated_scripts.has(script_name):
				all_generated_scripts.append(script_name)
	
	var end_time: int = Time.get_ticks_msec()
	var compilation_time: float = (end_time - start_time)
	
	toast.notify.call_deferred("Generated " + str(all_generated_scripts.size()) + " scripts in " + str(compilation_time) + "ms", HenToast.MessageType.SUCCESS)

	if all_generated_scripts.size() > 0:
		_display_generated_scripts_stats(all_generated_scripts)


static func _display_generated_scripts_stats(_all_generated_scripts: Array[String]) -> void:
	var toast: HenToast = Engine.get_singleton(&'ToastContainer')
	for script: String in _all_generated_scripts:
		toast.notify.call_deferred('Generated: ' + script.get_basename(), HenToast.MessageType.SUCCESS)

	
static func generate(_script_data: HenScriptData, _script_id: int, _regenerate: bool = false) -> Array[String]:
	var generated_scripts: Array[String] = []
	
	if not HenCheckerScriptData.is_script_data_valid(_script_data):
		return generated_scripts

	(Engine.get_singleton(&'ToastContainer') as HenToast).notify.call_deferred('Saving: ' + ResourceUID.get_id_path(_script_id).get_basename())
	var _save_data: SaveData = SaveData.new(_script_id, _script_data)
	var _save_config: SaveConfig = SaveConfig.new()
	var code_generation: HenCodeGeneration = Engine.get_singleton(&'CodeGeneration')

	_save_config.add_script(_save_data)

	if _regenerate:
		if not code_generation.regenerate(_save_config, _script_id, _script_data.side_bar_list):
			return generated_scripts

	code_generation.get_code(_script_data)
	HenSaveScript.save_data(_save_config)
	
	# collect all scripts that were processed in the save_config
	for config in _save_config.script_list:
		generated_scripts.append(ResourceUID.get_id_path(config.id))
	
	return generated_scripts