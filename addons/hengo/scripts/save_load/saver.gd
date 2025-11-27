@tool
class_name HenSaver extends Node


static func save() -> void:
	(Engine.get_singleton(&'SignalBus') as HenSignalBus).scripts_generation_started.emit()
	(Engine.get_singleton(&'ThreadHelper') as HenThreadHelper).add_task(start_generate.bind(true))


static func save_new() -> void:
	if not DirAccess.dir_exists_absolute('res://hengo'):
		DirAccess.make_dir_absolute('res://hengo')
	
	if not DirAccess.dir_exists_absolute(HenEnums.HENGO_SAVE_PATH):
		DirAccess.make_dir_absolute(HenEnums.HENGO_SAVE_PATH)
	
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var toast: HenToast = Engine.get_singleton(&'ToastContainer')

	var script_id: StringName = str(global.script_config.id)
	var script_path: StringName = HenEnums.HENGO_SAVE_PATH + script_id
	
	var variables_path: StringName = script_path + '/variables/'
	var functions_path: StringName = script_path + '/functions/'
	var signals_path: StringName = script_path + '/signals/'
	var signals_callback_path: StringName = script_path + '/signals_callback/'
	var macros_path: StringName = script_path + '/macros/'

	var save_data: HenSaveData = global.SAVE_DATA

	save_data.virtual_cnode_list.clear()

	for v_cnode: HenVirtualCNode in global.BASE_ROUTE.get_ref().virtual_cnode_list:
		save_data.virtual_cnode_list.append(v_cnode.get_save(save_data))

		if v_cnode.identity.type == HenVirtualCNode.Type.STATE_EVENT:
			save_data.state_event_list.append(v_cnode.identity.name)

	save_side_bar_item(save_data.variables, variables_path)
	save_side_bar_item(save_data.functions, functions_path)
	save_side_bar_item(save_data.signals, signals_path)
	save_side_bar_item(save_data.signals_callback, signals_callback_path)
	save_side_bar_item(save_data.macros, macros_path)

	save_data.take_over_path(script_path + '/save.tres')
	var result: int = ResourceSaver.save(save_data)
	toast.notify.call_deferred(('Saved SAVE DATA: ' + str(save_data.id)) if result == OK else 'Erro saving' + str(save_data.id))


static func save_side_bar_item(_arr: Array, _path: StringName) -> void:
	var toast: HenToast = Engine.get_singleton(&'ToastContainer')

	if not DirAccess.dir_exists_absolute(_path):
		DirAccess.make_dir_absolute(_path)

	for item: HenSaveResType in _arr:
		item.take_over_path(_path + str(item.id) + '.tres')
		var result: int = ResourceSaver.save(item)
		toast.notify.call_deferred(
			('Saved FUNC: ' + str(item.id)) if result == OK else 'Erro saving' + str(item.id),
			HenToast.MessageType.SUCCESS if result == OK else HenToast.MessageType.ERROR
		)


static func start_generate(_regenerate: bool = false) -> void:
	var start_time: int = Time.get_ticks_msec()
	var toast: HenToast = Engine.get_singleton(&'ToastContainer')

	# check if save dierctory exists
	if not DirAccess.dir_exists_absolute('res://hengo'):
		DirAccess.make_dir_absolute('res://hengo')

	if not DirAccess.dir_exists_absolute(HenEnums.HENGO_SAVE_PATH):
		DirAccess.make_dir_absolute(HenEnums.HENGO_SAVE_PATH)

	save_new()
	
	var end_time: int = Time.get_ticks_msec()
	var compilation_time: float = (end_time - start_time)
	
	toast.notify.call_deferred("Saved in " + str(compilation_time) + "ms", HenToast.MessageType.SUCCESS)


static func generate(_script_data: HenSaveData, _script_id: int, _regenerate: bool = false) -> Array[String]:
	var generated_scripts: Array[String] = []
	
	
	return generated_scripts