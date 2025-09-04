@tool
class_name HenSideBar extends PanelContainer

var list: Tree


const ADD_ICON = preload('res://addons/hengo/assets/icons/plus.svg')
const CATEGORY_FONT = preload('res://addons/hengo/assets/fonts/Inter-Bold.ttf')

enum AddType {VAR, FUNC, SIGNAL_CALLBACK, SIGNAL, LOCAL_VAR, MACRO}
enum ParamType {INPUT, OUTPUT}

const BG_COLOR = {
	AddType.VAR: Color('#509fa6'),
	AddType.FUNC: Color('#b05353'),
	AddType.SIGNAL_CALLBACK: Color('#51a650'),
	AddType.MACRO: Color('#9f50a6'),
	AddType.LOCAL_VAR: Color('#a69150'),
	AddType.SIGNAL: Color('#51a650')
}

const ICONS = {
	AddType.VAR: preload('res://addons/hengo/assets/icons/menu/cuboid.svg'),
	AddType.MACRO: preload('res://addons/hengo/assets/icons/menu/text.svg'),
	AddType.FUNC: preload('res://addons/hengo/assets/icons/menu/void.svg'),
	AddType.SIGNAL_CALLBACK: preload('res://addons/hengo/assets/icons/menu/wifi.svg'),
	AddType.LOCAL_VAR: preload('res://addons/hengo/assets/icons/menu/cuboid.svg'),
	AddType.SIGNAL: preload('res://addons/hengo/assets/icons/menu/wifi.svg')
}

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
		HenGlobal.SIDE_BAR_LIST.list_changed.emit()
	
	func add() -> void:
		arr.append(item)
		HenUtils.move_array_item_to_idx(arr, item, idx)
		item.emit_signal('deleted', false)
		HenGlobal.SIDE_BAR_LIST.list_changed.emit()


func _ready() -> void:
	if HenUtils.disable_scene_with_owner(self):
		return

	list = get_node('%List')
	list.auto_tooltip = false
	list.button_clicked.connect(_on_list_button_clicked)
	list.item_mouse_selected.connect(_on_item_selected)
	list.gui_input.connect(_on_gui)
	list.mouse_exited.connect(_on_exit)

	HenGlobal.SIDE_BAR = self
	HenGlobal.SIDE_BAR_LIST = HenSideBarList.new()
	HenGlobal.SIDE_BAR_LIST.list_changed.connect(_on_list_changed)


func _on_exit() -> void:
	HenGlobal.TOOLTIP.close()


func _on_gui(_event: InputEvent) -> void:
	if _event is InputEventMouseMotion:
		var item: TreeItem = list.get_item_at_position((_event as InputEventMouseMotion).position)
		var bt_id: int = list.get_button_id_at_position((_event as InputEventMouseMotion).position)

		if bt_id >= 0:
			HenGlobal.TOOLTIP.close()
			return

		if HenGlobal.SIDE_BAR_LIST.inspecting:
			HenGlobal.TOOLTIP.close()
			return

		if item:
			var _side_bar_item = item.get_metadata(0)
			
			if _side_bar_item is not int and _side_bar_item is RefCounted:
				var pos: Vector2 = (_event as InputEventMouseMotion).global_position
				var text: String = ''

				if _side_bar_item is HenVarData:
					text = '[b]HenTypeVariable[/b]\n\n{0}\n\n{1}'.format([_side_bar_item.name, HenEnums.TOOLTIP_TEXT.RIGHT_MOUSE_INSPECT])
				elif _side_bar_item is HenFuncData:
					text = '[b]Function[/b]\n\n{0}\n\n{1}'.format([_side_bar_item.name, HenEnums.TOOLTIP_TEXT.RIGHT_MOUSE_INSPECT])
				elif _side_bar_item is HenSignalCallbackData:
					text = '[b]Signal[/b]\n\n{0}\n\n{1}'.format([_side_bar_item.name, HenEnums.TOOLTIP_TEXT.RIGHT_MOUSE_INSPECT])
				elif _side_bar_item is HenMacroData:
					text = '[b]HenTypeMacro[/b]\n\n{0}\n\n{1}'.format([_side_bar_item.name, HenEnums.TOOLTIP_TEXT.RIGHT_MOUSE_INSPECT])
				elif _side_bar_item is HenSignalData:
					text = '[b]Signal[/b]\n\n{0}\n\n{1}'.format([_side_bar_item.name, HenEnums.TOOLTIP_TEXT.RIGHT_MOUSE_INSPECT])

				pos.x = HenGlobal.SIDE_PANEL.global_position.x

				HenGlobal.TOOLTIP.go_to(pos, text, Vector2(-1, 0))
			else:
				HenGlobal.TOOLTIP.close()
		else:
			HenGlobal.TOOLTIP.close()


func _on_item_selected(_mouse_position: Vector2, _mouse_button_index: int) -> void:
	match _mouse_button_index:
		1:
			var obj = list.get_selected().get_metadata(0)

			await RenderingServer.frame_post_draw
			
			if obj.get('route'):
				HenRouter.change_route(obj.get('route'))
		2:
			HenGlobal.SIDE_BAR_LIST.on_click(list.get_selected().get_metadata(0), _mouse_position)


func _on_list_changed() -> void:
	list.clear()

	var root: TreeItem = list.create_item()
	var base: TreeItem = root.create_child()

	base.set_text(0, 'Base')
	base.set_metadata(0, {route = HenGlobal.BASE_ROUTE})

	# variables
	_add_categories(root, 'Signals', AddType.SIGNAL)
	_add_categories(root, 'Variables', AddType.VAR)
	_add_categories(root, 'Functions', AddType.FUNC)
	_add_categories(root, 'Signals Callback', AddType.SIGNAL_CALLBACK)
	_add_categories(root, 'Macros', AddType.MACRO)

	if HenRouter.current_route and HenRouter.current_route.get_ref() and HenRouter.current_route.get_ref().get(&'local_vars') is Array:
		_add_categories(root, 'Local Variables', AddType.LOCAL_VAR)


func _add_categories(_root: TreeItem, _name: String, _type: AddType) -> void:
	# variables
	var category: TreeItem = _root.create_child()
	category.set_text(0, _name)
	category.add_button(0, ADD_ICON)
	category.set_metadata(0, _type)
	category.set_selectable(0, false)
	category.set_icon_modulate(0, BG_COLOR[_type])
	category.set_custom_color(0, Color(BG_COLOR[_type], .8))
	category.set_custom_font(0, CATEGORY_FONT)
	category.set_button_color(0, 0, Color('#616161'))

	var arr: Array

	match _type:
		AddType.VAR:
			arr = HenGlobal.SIDE_BAR_LIST.var_list
		AddType.FUNC:
			arr = HenGlobal.SIDE_BAR_LIST.func_list
		AddType.SIGNAL_CALLBACK:
			arr = HenGlobal.SIDE_BAR_LIST.signal_callback_list
		AddType.MACRO:
			arr = HenGlobal.SIDE_BAR_LIST.macro_list
		AddType.LOCAL_VAR:
			if HenRouter.current_route.get_ref().get(&'local_vars') is Array:
				arr = (HenRouter.current_route.get_ref().local_vars as Array)
		AddType.SIGNAL:
			arr = HenGlobal.SIDE_BAR_LIST.signal_list

	for item_data in arr:
		var item: TreeItem = category.create_child()
		item.set_text(0, item_data.name)
		item.set_metadata(0, item_data)
		# item.set_custom_bg_color(0, Color((BG_COLOR[_type] as Color), .1))
		item.set_custom_color(0, Color('#868686'))

		match _type:
			AddType.VAR, AddType.LOCAL_VAR:
				item.set_icon(0, HenAssets.get_icon_texture(item_data.type))
			_:
				item.set_icon_modulate(0, BG_COLOR[_type])
				item.set_icon(0, ICONS[_type])


func _on_list_button_clicked(_item: TreeItem, _column: int, _id: int, _mouse_button_index: int) -> void:
	var _type: AddType = _item.get_metadata(0)

	HenGlobal.SIDE_BAR_LIST.change(_type)
	HenGlobal.SIDE_BAR_LIST.add()
