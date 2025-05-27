@tool
class_name HenSaver extends Node

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


static func save(_debug_symbols: Dictionary, _generate_code: bool = false) -> void:
	# check if save dierctory exists
	if not DirAccess.dir_exists_absolute('res://hengo'):
		DirAccess.make_dir_absolute('res://hengo')

	if not DirAccess.dir_exists_absolute('res://hengo/save'):
		DirAccess.make_dir_absolute('res://hengo/save')
	
	if not FileAccess.file_exists('res://hengo/save/references.res'):
		ResourceSaver.save(HenSideBarReferences.new(), 'res://hengo/save/references.res')

	var side_bar_refs: HenSideBarReferences = ResourceLoader.load('res://hengo/save/references.res')

	HenGlobal.FROM_REFERENCES = side_bar_refs

	var script_data: HenScriptData = HenScriptData.new()

	script_data.path = HenGlobal.script_config.path
	script_data.type = HenGlobal.script_config.type
	script_data.node_counter = HenGlobal.node_counter
	script_data.prop_counter = HenGlobal.prop_counter
	script_data.debug_symbols = _debug_symbols

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

	var data_path: StringName = 'res://hengo/save/' + str(HenGlobal.script_config.id) + '.res'

	# saving data
	var error: int = ResourceSaver.save(script_data, data_path)

	if error != OK:
		printerr('Error saving script data.')
		return

	if not HenGlobal.FROM_REFERENCES.references.is_empty():
		ResourceSaver.save(HenGlobal.FROM_REFERENCES)

	# ---------------------------------------------------------------------------- #
	if _generate_code:
		var thread: Thread = Thread.new()
		thread.start(generate_thread.bind(
			generate.bind(script_data, data_path, ResourceUID.get_id_path(HenGlobal.script_config.id), true),
			code_generated.bind(thread)
		))


static func code_generated(_save_data: SaveData, _thread: Thread) -> void:
	_save_data.save_script()
	_thread.wait_to_finish.call_deferred()
	print('FINISHED')


static func generate_thread(_generate: Callable, _callback: Callable) -> void:
	_callback.call_deferred(_generate.call())


static func generate(_script_data: HenScriptData, _data_path: String, _path: StringName, _first_time: bool = false) -> SaveData:
	var code: String = HenCodeGeneration.get_code(_script_data)

	# TODO
	push_warning('Error List: ', HenCodeGeneration.flow_errors)

	var script: GDScript = GDScript.new()
	script.source_code = '#[hengo] ' + _data_path + '\n\n' + code

	var reload_err: int = script.reload()

	if reload_err == OK:
		return SaveData.new(
			script,
			_path,
			true,
			HenCodeGeneration.regenerate() if _first_time else []
		)
	
	return SaveData.new(script, _path, false)