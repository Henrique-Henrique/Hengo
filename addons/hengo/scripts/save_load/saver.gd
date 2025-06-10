@tool
class_name HenSaver extends Node

const LOAD_ICON = preload('res://addons/hengo/assets/icons/loader-circle.svg')
const BUILD_ICON = preload('res://addons/hengo/assets/icons/menu/compile.svg')

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
	start_load()
	show_msg()

	# check if save dierctory exists
	if not DirAccess.dir_exists_absolute('res://hengo'):
		DirAccess.make_dir_absolute('res://hengo')

	if not DirAccess.dir_exists_absolute('res://hengo/save'):
		DirAccess.make_dir_absolute('res://hengo/save')
		FileAccess.open('res://hengo/save/.gdignore', FileAccess.WRITE).close()
	
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


static func code_generated(_save_data: SaveData, _thread: Thread) -> void:
	_save_data.save_script()
	_thread.wait_to_finish.call_deferred()
	hide_msg()
	generate_msgs.call_deferred('Generated')
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


static func generate(_script_data: HenScriptData, _data_path: String, _path: StringName, _first_time: bool = false) -> SaveData:
	generate_msgs.call_deferred('Generating [b]{0}[/b]'.format([_path]))
	var code: String = HenCodeGeneration.get_code(_script_data)

	# TODO
	if HenCodeGeneration.flow_errors.size() > 0:
		# TODO errors msg
		generate_msgs.call_deferred('[b][color=#c91a1a]Errors found: {0}[/color][/b]'.format([HenCodeGeneration.flow_errors.size()]))

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