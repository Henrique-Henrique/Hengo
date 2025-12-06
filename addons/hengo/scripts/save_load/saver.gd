@tool
class_name HenSaver extends Node

enum SideBarItem {
	VARIABLES,
	FUNCTIONS,
	SIGNALS,
	SIGNALS_CALLBACK,
	MACROS
}


static func save() -> void:
	(Engine.get_singleton(&'SignalBus') as HenSignalBus).scripts_generation_started.emit()
	(Engine.get_singleton(&'ThreadHelper') as HenThreadHelper).add_task(start_generate.bind(true))


# returns the specific path based on the provided enum type
static func get_side_bar_item_path(_id: StringName, type: SideBarItem) -> StringName:
	var base_path: StringName = HenEnums.HENGO_SAVE_PATH + str(_id)
	var suffix: String = ''

	match type:
		SideBarItem.VARIABLES:
			suffix = '/variables/'
		SideBarItem.FUNCTIONS:
			suffix = '/functions/'
		SideBarItem.SIGNALS:
			suffix = '/signals/'
		SideBarItem.SIGNALS_CALLBACK:
			suffix = '/signals_callback/'
		SideBarItem.MACROS:
			suffix = '/macros/'

	return base_path + suffix


static func save_new() -> void:
	if not DirAccess.dir_exists_absolute('res://hengo'):
		DirAccess.make_dir_absolute('res://hengo')
	
	if not DirAccess.dir_exists_absolute(HenEnums.HENGO_SAVE_PATH):
		DirAccess.make_dir_absolute(HenEnums.HENGO_SAVE_PATH)
	
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var toast: HenToast = Engine.get_singleton(&'ToastContainer')

	var save_data: HenSaveData = get_current_save_data(global)
	var script_id: StringName = str(save_data.identity.id)
	var script_path: StringName = HenEnums.HENGO_SAVE_PATH + script_id

	save_side_bar_item(save_data.variables, get_side_bar_item_path(script_id, SideBarItem.VARIABLES))
	save_side_bar_item(save_data.functions, get_side_bar_item_path(script_id, SideBarItem.FUNCTIONS))
	save_side_bar_item(save_data.signals, get_side_bar_item_path(script_id, SideBarItem.SIGNALS))
	save_side_bar_item(save_data.signals_callback, get_side_bar_item_path(script_id, SideBarItem.SIGNALS_CALLBACK))
	save_side_bar_item(save_data.macros, get_side_bar_item_path(script_id, SideBarItem.MACROS))

	save_data.take_over_path(script_path + '/save.tres')
	var result: int = ResourceSaver.save(save_data)
	toast.notify.call_deferred(('Saved SAVE DATA: ' + str(save_data.identity.id)) if result == OK else 'Erro saving' + str(save_data.identity.id))


static func get_current_save_data(_global: HenGlobal) -> HenSaveData:
	var save_data: HenSaveData = _global.SAVE_DATA
	build_current_virtual_cnode_list(_global)
	return save_data


static func build_current_virtual_cnode_list(_global: HenGlobal) -> void:
	var save_data: HenSaveData = _global.SAVE_DATA

	save_data.virtual_cnode_list.clear()
	save_data.connections.clear()
	save_data.flow_connections.clear()

	for v_cnode: HenVirtualCNode in _global.BASE_ROUTE.virtual_cnode_list:
		save_data.virtual_cnode_list.append(v_cnode.get_save(save_data))

		if v_cnode.identity.type == HenVirtualCNode.Type.STATE_EVENT:
			save_data.state_event_list.append(v_cnode.identity.name)

	generate_vc_list(save_data, save_data.functions)
	generate_vc_list(save_data, save_data.macros)
	generate_vc_list(save_data, save_data.signals_callback)


static func generate_vc_list(_save_data: HenSaveData, _arr: Array) -> void:
	for item: HenSaveResTypeWithRoute in _arr:
		item.virtual_cnode_list.clear()

		for vc: HenVirtualCNode in item.route.virtual_cnode_list:
			item.virtual_cnode_list.append(vc.get_save(_save_data))


static func save_side_bar_item(_arr: Array, _path: StringName) -> void:
	var toast: HenToast = Engine.get_singleton(&'ToastContainer')

	if not DirAccess.dir_exists_absolute(_path):
		DirAccess.make_dir_absolute(_path)

	for item: HenSaveResType in _arr:
		item.take_over_path(_path + str(item.id) + '.tres')
		var result: int = ResourceSaver.save(item)
		toast.notify.call_deferred(
			('Saved: ' + _path) if result == OK else 'Erro saving' + str(item.id),
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
	var signal_bus: HenSignalBus = Engine.get_singleton(&'SignalBus')
	signal_bus.scripts_generation_finished.emit.call_deferred()


static func generate(_script_data: HenSaveData, _script_id: int, _regenerate: bool = false) -> Array[String]:
	var generated_scripts: Array[String] = []
	
	
	return generated_scripts