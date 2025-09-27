@tool
class_name HenSideBarList extends RefCounted

var type: HenSideBar.AddType
var id: int
var signal_list: Array
var var_list: Array
var func_list: Array
var signal_callback_list: Array
var macro_list: Array
var inspecting: bool = false

signal list_changed

func clear() -> void:
	signal_list.clear()
	var_list.clear()
	func_list.clear()
	signal_callback_list.clear()
	macro_list.clear()

	change(HenSideBar.AddType.VAR)
	list_changed.emit()

func add() -> void:
	match type:
		HenSideBar.AddType.VAR:
			var_list.append(HenVarData.new())
		HenSideBar.AddType.FUNC:
			func_list.append(HenFuncData.new())
		HenSideBar.AddType.SIGNAL_CALLBACK:
			signal_callback_list.append(HenSignalCallbackData.new())
		HenSideBar.AddType.MACRO:
			macro_list.append(HenMacroData.new())
		HenSideBar.AddType.LOCAL_VAR:
			if HenRouter.current_route.get_ref().get(&'local_vars') is Array:
				var var_data: HenVarData = HenVarData.new()
				var_data.local_ref = HenRouter.current_route.get_ref()
				
				(HenRouter.current_route.get_ref().local_vars as Array).append(var_data)
		HenSideBar.AddType.SIGNAL:
			signal_list.append(HenSignalData.new())

	list_changed.emit()

func change(_type: HenSideBar.AddType) -> void:
	type = _type

func get_list_to_draw() -> Array:
	match type:
		HenSideBar.AddType.VAR:
			return var_list.map(func(x: HenVarData): return {name = x.name})
		HenSideBar.AddType.FUNC:
			return func_list.map(func(x: HenFuncData): return {name = x.name})
		HenSideBar.AddType.SIGNAL_CALLBACK:
			return signal_callback_list.map(func(x: HenSignalCallbackData): return {name = x.name})
		HenSideBar.AddType.MACRO:
			return macro_list.map(func(x: HenMacroData): return {name = x.name})
		HenSideBar.AddType.LOCAL_VAR:
			if HenRouter.current_route.get_ref().get(&'local_vars') is Array:
				return (HenRouter.current_route.get_ref().local_vars as Array).map(func(x: HenVarData): return {name = x.name})
		HenSideBar.AddType.SIGNAL:
			return signal_list.map(func(x: HenSignalData): return {name = x.name})

	return []

func on_click(_item, _mouse_pos: Vector2) -> void:
	var pos: Vector2 = HenGlobal.SIDE_BAR.global_position
	
	pos.x = HenGlobal.SIDE_PANEL.global_position.x
	pos.y += _mouse_pos.y

	var popup: HenPopupContainer = HenGlobal.GENERAL_POPUP.get_parent().show_content(
		HenPropEditor.mount(_item),
		'Testing',
		pos,
		1.5
	)

	if not popup.closed.is_connected(_on_inspector_close): popup.closed.connect(_on_inspector_close)
	inspecting = true


func _on_inspector_close() -> void:
	inspecting = false


func get_save(_script_data: HenScriptData) -> Dictionary:
	return {
		id = id,
		var_list = var_list.map(func(x: HenVarData): return x.get_save()),
		func_list = func_list.map(func(x: HenFuncData): return x.get_save(_script_data)),
		signal_callback_list = signal_callback_list.map(func(x: HenSignalCallbackData): return x.get_save(_script_data)),
		macro_list = macro_list.map(func(x: HenMacroData): return x.get_save(_script_data)),
		signal_list = signal_list.map(func(x: HenSignalData): return x.get_save())
	}

func load_save(_data: Dictionary) -> void:
	id = HenGlobal.get_new_node_counter() if not _data.has('id') else _data.id

	for item_data: Dictionary in _data.var_list:
		var item: HenVarData = HenVarData.new()
		item.load_save(item_data)
		var_list.append(item)

	for item_data: Dictionary in _data.func_list:
		var item: HenFuncData = HenFuncData.new(false)
		item.load_save(item_data)
		func_list.append(item)
	
	for item_data: Dictionary in _data.signal_callback_list:
		var item: HenSignalCallbackData = HenSignalCallbackData.new(false)
		item.load_save(item_data)
		signal_callback_list.append(item)

	for item_data: Dictionary in _data.macro_list:
		var item: HenMacroData = HenMacroData.new(false)
		item.load_save(item_data)
		macro_list.append(item)
	
	for item_data: Dictionary in _data.signal_list:
		var item: HenSignalData = HenSignalData.new()
		item.load_save(item_data)
		signal_list.append(item)

	# loading cnodes
	for item in HenGlobal.SIDE_BAR_LIST_CACHE.values():
		@warning_ignore('unsafe_method_access')
		if item.get('cnode_list_to_load') is Array:
			HenLoader.parse_and_get_vc_list_dict(item.cnode_list_to_load, item.route)
			(item.cnode_list_to_load as Array).clear()

	list_changed.emit()