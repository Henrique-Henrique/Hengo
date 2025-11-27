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
	var router: HenRouter = Engine.get_singleton(&'Router')

	# match type:
	# 	HenSideBar.AddType.VAR:
	# 		var_list.append(HenVarData.new())
	# 	HenSideBar.AddType.FUNC:
	# 		func_list.append(HenFuncData.new())
	# 	HenSideBar.AddType.SIGNAL_CALLBACK:
	# 		signal_callback_list.append(HenSignalCallbackData.new())
	# 	HenSideBar.AddType.MACRO:
	# 		macro_list.append(HenMacroData.new())
	# 	HenSideBar.AddType.LOCAL_VAR:
	# 		if router.current_route.get_ref().get(&'local_vars') is Array:
	# 			var var_data: HenVarData = HenVarData.new()
	# 			var_data.local_ref = router.current_route.get_ref()
				
	# 			(router.current_route.get_ref().local_vars as Array).append(var_data)
	# 	HenSideBar.AddType.SIGNAL:
	# 		signal_list.append(HenSignalData.new())

	list_changed.emit()

func change(_type: HenSideBar.AddType) -> void:
	type = _type

func get_list_to_draw() -> Array:
	var router: HenRouter = Engine.get_singleton(&'Router')

	# match type:
	# 	HenSideBar.AddType.VAR:
	# 		return var_list.map(func(x: HenVarData): return {name = x.name})
	# 	HenSideBar.AddType.FUNC:
	# 		return func_list.map(func(x: HenFuncData): return {name = x.name})
	# 	HenSideBar.AddType.SIGNAL_CALLBACK:
	# 		return signal_callback_list.map(func(x: HenSignalCallbackData): return {name = x.name})
	# 	HenSideBar.AddType.MACRO:
	# 		return macro_list.map(func(x: HenMacroData): return {name = x.name})
	# 	HenSideBar.AddType.LOCAL_VAR:
	# 		if router.current_route.get_ref().get(&'local_vars') is Array:
	# 			return (router.current_route.get_ref().local_vars as Array).map(func(x: HenVarData): return {name = x.name})
	# 	HenSideBar.AddType.SIGNAL:
	# 		return signal_list.map(func(x: HenSignalData): return {name = x.name})

	return []

func on_click(_item, _mouse_pos: Vector2) -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var pos: Vector2 = global.SIDE_BAR.global_position
	var prop_editor: HenPropEditor = HenPropEditor.mount(_item)

	pos.x = global.SIDE_BAR.position.x + global.SIDE_BAR.size.x + 10
	pos.y += _mouse_pos.y

	var popup: HenPopupContainer = global.GENERAL_POPUP.show_content(
		prop_editor,
		'Testing',
		pos,
		1.5
	)

	if not popup.closed.is_connected(_on_inspector_close): popup.closed.connect(_on_inspector_close)
	inspecting = true


func _on_inspector_close() -> void:
	inspecting = false