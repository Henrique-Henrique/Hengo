@tool
class_name HenSaver extends Node

const LOAD_ICON = preload('res://addons/hengo/assets/icons/loader-circle.svg')
const BUILD_ICON = preload('res://addons/hengo/assets/icons/menu/compile.svg')

static var task_id_list: Array[int] = []

class SaveData:
	var script_ref: GDScript
	var path: StringName
	var valid: bool = false
	var saves: Array

	func _init(_script: GDScript, _path: StringName, _valid: bool, _save_dep: Array = []) -> void:
		script_ref = _script
		path = _path
		valid = _valid
		saves = _save_dep
	

	func save_script() -> void:
		if valid:
			var err: int = ResourceSaver.save(script_ref, path)

			if err == OK:
				for save: SaveDependency in saves:
					save.save()
				
				print('SAVED HENGO SCRIPT')


class SaveDependency:
	var data: HenScriptData
	var script_data: SaveData

	func _init(_data: HenScriptData, _script_data: SaveData) -> void:
		data = _data
		script_data = _script_data

	func save() -> void:
		var res_error: int = ResourceSaver.save(data)
		
		if res_error == OK:
			script_data.save_script()


class Task:
	var task_id: int
	var callback: Callable

	signal finished

	func _init(_callback: Callable) -> void:
		task_id = WorkerThreadPool.add_task(_callback)

	func wait_for_completion() -> void:
		WorkerThreadPool.wait_for_task_completion(task_id)


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


static func save(_debug_symbols: Dictionary, _generate_code: bool = false) -> void:
	var script_data: HenScriptData = generate_script_data()
	var script_id: int = HenGlobal.script_config.id
	var data_path: StringName = 'res://hengo/save/' + str(script_id) + '.res'

	start_load()
	show_msg()

	# check if save dierctory exists
	if not DirAccess.dir_exists_absolute('res://hengo'):
		DirAccess.make_dir_absolute('res://hengo')

	if not DirAccess.dir_exists_absolute('res://hengo/save'):
		DirAccess.make_dir_absolute('res://hengo/save')
		FileAccess.open('res://hengo/save/.gdignore', FileAccess.WRITE).close()


	HenSaver.task_id_list.append(WorkerThreadPool.add_task(save_data_files.bind(script_data, data_path)))
	HenSaver.task_id_list.append(WorkerThreadPool.add_task(generate.bind(script_data, data_path, ResourceUID.get_id_path(script_id), script_id)))


static func show_msg() -> void:
	var msg: RichTextLabel = (HenGlobal.HENGO_ROOT.get_node('%ScriptInfoMsg') as RichTextLabel)

	msg.text = ''

	if msg.has_meta(&'tween'):
		(msg.get_meta(&'tween') as Tween).kill()
	
	msg.modulate = Color.WHITE
	msg.visible = true


static func hide_msg() -> void:
	var tween: Tween = HenGlobal.CAM.get_tree().create_tween()
	var msg: RichTextLabel = HenGlobal.HENGO_ROOT.get_node('%ScriptInfoMsg')

	msg.set_meta(&'tween', tween)
	tween.tween_property(msg, 'modulate', Color.TRANSPARENT, 10.)
	tween.finished.connect(func(): msg.visible = false)


static func save_data_files(_script_data: HenScriptData, _data_path: String) -> void:
	ResourceSaver.save(_script_data, _data_path)
	
	# var ref_file: FileAccess = FileAccess.open(HenEnums.SCRIPT_REF_PATH, FileAccess.WRITE)
	# ref_file.store_string(JSON.stringify(HenGlobal.SCRIPT_REF_CACHE))
	# ref_file.close()


static func code_generated(_save_data: SaveData) -> void:
	_save_data.save_script()
	# _thread.wait_to_finish.call_deferred()
	hide_msg()
	generate_msgs.call_deferred('Generated')
	HenGlobal.SIGNAL_BUS.script_generated.emit()
	reset_load()


static func start_load() -> void:
	var container: HenCompile = HenGlobal.HENGO_ROOT.get_node('%CompileContainer')
	
	container.icon.texture = LOAD_ICON
	container.icon.pivot_offset = container.icon.size / 2
	container.set_process(true)
	container.icon.modulate = Color.SKY_BLUE


static func reset_load() -> void:
	var container: HenCompile = HenGlobal.HENGO_ROOT.get_node('%CompileContainer')
	
	container.icon.texture = BUILD_ICON
	container.set_process(false)
	container.icon.rotation = 0
	container.icon.modulate = Color.WHITE


static func generate_msgs(_text: String) -> void:
	(HenGlobal.HENGO_ROOT.get_node('%ScriptInfoMsg') as RichTextLabel).text += _text + '\n'


static func generate_thread(_generate: Callable, _callback: Callable) -> void:
	_callback.call_deferred(_generate.call())


static func generate(_script_data: HenScriptData, _data_path: String, _path: StringName, _script_id: int) -> void:
	# generate_msgs.call_deferred('Generating [b]{0}[/b]'.format([_path]))
	var code: String = HenCodeGeneration.get_code(_script_data)

	# TODO
	# if HenCodeGeneration.flow_errors.size() > 0:
	# 	# TODO errors msg
	# 	generate_msgs.call_deferred('[b][color=#c91a1a]Errors found: {0}[/color][/b]'.format([HenCodeGeneration.flow_errors.size()]))
	# 	return SaveData.new(null, '', false)

	var script: GDScript = GDScript.new()
	script.source_code = '#[hengo] ' + _data_path + '\n\n' + code
	var reload_err: int = script.reload()

	if reload_err == OK:
		var ref_file: FileAccess = FileAccess.open(_path, FileAccess.WRITE)
		ref_file.store_string(script.source_code)
		ref_file.close()
	
	HenCodeGeneration.regenerate(_script_id, _script_data.side_bar_list)