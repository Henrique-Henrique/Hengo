@tool
class_name HenSideBar extends PanelContainer

enum SideBarItem {
	VARIABLES,
	FUNCTIONS,
	SIGNALS,
	SIGNALS_CALLBACK,
	MACROS
}

var list: Tree

const ADD_ICON = preload('res://addons/hengo/assets/icons/plus.svg')

enum AddType {VAR, FUNC, SIGNAL_CALLBACK, SIGNAL, LOCAL_VAR, MACRO}
enum ParamType {INPUT, OUTPUT}

var BG_COLOR: Dictionary
var ICONS: Dictionary

const NAME = {
	AddType.VAR: 'Variables',
	AddType.FUNC: 'Functions',
	AddType.SIGNAL_CALLBACK: 'Signal Callback',
	AddType.LOCAL_VAR: 'Local Variables',
	AddType.MACRO: 'Macro',
	AddType.SIGNAL: 'Signal'
}


class DeleteItemCache:
	var item: RefCounted
	var arr: Array
	var idx: int

	func _init(_item: RefCounted, _arr: Array) -> void:
		item = _item
		arr = _arr

	func remove() -> void:
		idx = arr.find(item)
		arr.erase(item)
		item.emit_signal('deleted', true)
	
	func add() -> void:
		arr.append(item)
		HenUtils.move_array_item_to_idx(arr, item, idx)
		item.emit_signal('deleted', false)


func _ready() -> void:
	if HenUtils.disable_scene_with_owner(self):
		return

	BG_COLOR = {
		AddType.VAR: HenEnums.FLOW_COLORS[1],
		AddType.FUNC: HenEnums.FLOW_COLORS[2],
		AddType.SIGNAL_CALLBACK: HenEnums.FLOW_COLORS[0],
		AddType.MACRO: HenEnums.FLOW_COLORS[4],
		AddType.LOCAL_VAR: HenEnums.FLOW_COLORS[3],
		AddType.SIGNAL: HenEnums.FLOW_COLORS[0]
	}

	ICONS = {
		AddType.VAR: HenUtils.ICON_VARIABLE,
		AddType.MACRO: HenUtils.ICON_FUNCTION,
		AddType.FUNC: HenUtils.ICON_FUNCTION,
		AddType.SIGNAL_CALLBACK: HenUtils.ICON_SIGNAL,
		AddType.LOCAL_VAR: HenUtils.ICON_VARIABLE,
		AddType.SIGNAL: HenUtils.ICON_SIGNAL
	}

	var global: HenGlobal = Engine.get_singleton(&'Global')

	list = get_node('%List')
	list.auto_tooltip = false
	list.button_clicked.connect(_on_list_button_clicked)
	list.item_mouse_selected.connect(_on_item_selected)
	list.gui_input.connect(_on_gui)
	list.mouse_exited.connect(_on_exit)

	custom_minimum_size = Vector2(HenUtils.get_scaled_size(250), 0)

	global.SIDE_BAR = self


func _on_exit() -> void:
	(Engine.get_singleton(&'Global') as HenGlobal).TOOLTIP.close()


func _on_gui(_event: InputEvent) -> void:
	if _event is InputEventMouseMotion:
		var item: TreeItem = list.get_item_at_position((_event as InputEventMouseMotion).position)
		var bt_id: int = list.get_button_id_at_position((_event as InputEventMouseMotion).position)
		var global: HenGlobal = Engine.get_singleton(&'Global')

		if bt_id >= 0:
			global.TOOLTIP.close()
			return

		if item:
			var _side_bar_item = item.get_metadata(0)

			if _side_bar_item is not int and _side_bar_item is RefCounted:
				var pos: Vector2 = (_event as InputEventMouseMotion).global_position
				var text: String = ''

				# if _side_bar_item is HenVarData:
				# 	text = '[b]HenTypeVariable[/b]\n\n{0}\n\n{1}'.format([_side_bar_item.name, HenEnums.TOOLTIP_TEXT.RIGHT_MOUSE_INSPECT])
				# elif _side_bar_item is HenFuncData:
				# 	text = '[b]Function[/b]\n\n{0}\n\n{1}'.format([_side_bar_item.name, HenEnums.TOOLTIP_TEXT.RIGHT_MOUSE_INSPECT])
				# elif _side_bar_item is HenSignalCallbackData:
				# 	text = '[b]Signal[/b]\n\n{0}\n\n{1}'.format([_side_bar_item.name, HenEnums.TOOLTIP_TEXT.RIGHT_MOUSE_INSPECT])
				# elif _side_bar_item is HenMacroData:
				# 	text = '[b]HenTypeMacro[/b]\n\n{0}\n\n{1}'.format([_side_bar_item.name, HenEnums.TOOLTIP_TEXT.RIGHT_MOUSE_INSPECT])
				# elif _side_bar_item is HenSignalData:
				# 	text = '[b]Signal[/b]\n\n{0}\n\n{1}'.format([_side_bar_item.name, HenEnums.TOOLTIP_TEXT.RIGHT_MOUSE_INSPECT])
				
				pos.x = global.SIDE_PANEL.global_position.x + global.SIDE_PANEL.size.x

				global.TOOLTIP.go_to(pos, text)
			else:
				global.TOOLTIP.close()
		else:
			global.TOOLTIP.close()


func _on_item_selected(_mouse_position: Vector2, _mouse_button_index: int) -> void:
	match _mouse_button_index:
		1:
			var obj = list.get_selected().get_metadata(0)

			await RenderingServer.frame_pre_draw

			if obj is HenSaveResTypeWithRoute:
				var global: HenGlobal = Engine.get_singleton(&'Global')
				(Engine.get_singleton(&'Router') as HenRouter).change_route((obj as HenSaveResTypeWithRoute).get_route(global.SAVE_DATA))
			elif obj is HenRouteData:
				(Engine.get_singleton(&'Router') as HenRouter).change_route(obj as HenRouteData)
		2:
			var meta = list.get_selected().get_metadata(0)
			if meta: HenInspector.edit_resource(meta)


func update() -> void:
	list.clear()

	var root: TreeItem = list.create_item()
	var base: TreeItem = root.create_child()

	base.set_text(0, 'Base')
	base.set_metadata(0, (Engine.get_singleton(&'Global') as HenGlobal).SAVE_DATA.get_base_route())

	_add_categories(root, 'Signals', AddType.SIGNAL)
	_add_categories(root, 'Variables', AddType.VAR)
	_add_categories(root, 'Functions', AddType.FUNC)
	_add_categories(root, 'Signals Callback', AddType.SIGNAL_CALLBACK)
	_add_categories(root, 'Macros', AddType.MACRO)


func _add_categories(_root: TreeItem, _name: String, _type: AddType) -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var category: TreeItem = _root.create_child()

	category.set_icon(0, ICONS[_type])
	category.set_text(0, _name)
	category.add_button(0, ADD_ICON)
	category.set_metadata(0, _type)
	category.set_selectable(0, false)
	category.set_icon_modulate(0, Color(BG_COLOR[_type], 1.0))
	category.set_custom_color(0, Color('#808e9b'))
	category.set_button_color(0, 0, Color('#616161'))
	category.set_custom_bg_color(0, BG_COLOR.get(_type))

	match _type:
		AddType.VAR:
			for var_data: HenSaveVar in global.SAVE_DATA.variables:
				create_item(
					category,
					var_data.name,
					var_data,
					HenUtils.get_icon_texture(var_data.type),
				)
		AddType.FUNC:
			for func_data: HenSaveFunc in global.SAVE_DATA.functions:
				create_item(
					category,
					func_data.name,
					func_data,
					ICONS[_type],
					BG_COLOR[_type]
				)
		AddType.SIGNAL_CALLBACK:
			for db_data: HenSaveSignalCallback in global.SAVE_DATA.signals_callback:
				create_item(
					category,
					db_data.name,
					db_data,
					ICONS[_type],
					BG_COLOR[_type]
				)
		AddType.SIGNAL:
			for signal_data: HenSaveSignal in global.SAVE_DATA.signals:
				create_item(
					category,
					signal_data.name,
					signal_data,
					ICONS[_type],
					BG_COLOR[_type]
				)
		AddType.MACRO:
			for macro_data: HenSaveMacro in global.SAVE_DATA.macros:
				create_item(
					category,
					macro_data.name,
					macro_data,
					ICONS[_type],
					BG_COLOR[_type]
				)


func create_item(_category: TreeItem, _name: String, _meta: HenSaveResType, _icon: Texture2D = null, _icon_color: Color = Color.WHITE) -> void:
	var item: TreeItem = _category.create_child()

	item.set_cell_mode(0, TreeItem.TreeCellMode.CELL_MODE_CUSTOM)
	item.set_metadata(0, _meta)
	item.set_text(0, _name)
	item.set_icon(0, _icon)
	item.set_icon_modulate(0, Color(_icon_color, 1))
	item.set_custom_color(0, Color('#8c9197ff'))

	var bg_color = _icon_color
	bg_color.a = 0.05
	item.set_custom_bg_color(0, bg_color)


func _on_list_button_clicked(_item: TreeItem, _column: int, _id: int, _mouse_button_index: int) -> void:
	var _type: AddType = _item.get_metadata(0)
	var global: HenGlobal = Engine.get_singleton(&'Global')
	
	match _type:
		AddType.VAR:
			global.SAVE_DATA.add_var()
		AddType.FUNC:
			global.SAVE_DATA.add_func()
		AddType.SIGNAL:
			global.SAVE_DATA.add_signal()
		AddType.SIGNAL_CALLBACK:
			global.SAVE_DATA.add_signals_callback()
		AddType.MACRO:
			global.SAVE_DATA.add_macro()
		
	update()