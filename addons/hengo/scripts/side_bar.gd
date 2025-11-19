@tool
class_name HenSideBar extends PanelContainer

var list: Tree


const ADD_ICON = preload('res://addons/hengo/assets/icons/plus.svg')
const CATEGORY_FONT = preload('res://addons/hengo/assets/fonts/Inter-Bold.ttf')
const TREE_ITEM_STYLEBOX = preload('res://addons/hengo/resources/style_box/flat_tree.tres')

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
		(Engine.get_singleton(&'Global') as HenGlobal).SIDE_BAR_LIST.list_changed.emit()
	
	func add() -> void:
		arr.append(item)
		HenUtils.move_array_item_to_idx(arr, item, idx)
		item.emit_signal('deleted', false)
		(Engine.get_singleton(&'Global') as HenGlobal).SIDE_BAR_LIST.list_changed.emit()


func _ready() -> void:
	if HenUtils.disable_scene_with_owner(self):
		return

	var global: HenGlobal = Engine.get_singleton(&'Global')

	list = get_node('%List')
	list.auto_tooltip = false
	list.button_clicked.connect(_on_list_button_clicked)
	list.item_mouse_selected.connect(_on_item_selected)
	list.gui_input.connect(_on_gui)
	list.mouse_exited.connect(_on_exit)

	global.SIDE_BAR = self
	global.SIDE_BAR_LIST = HenSideBarList.new()
	global.SIDE_BAR_LIST.list_changed.connect(_on_list_changed)


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

		if global.SIDE_BAR_LIST.inspecting:
			global.TOOLTIP.close()
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
			
			if obj.get('route'):
				(Engine.get_singleton(&'Router') as HenRouter).change_route(obj.get('route'))
		2:
			(Engine.get_singleton(&'Global') as HenGlobal).SIDE_BAR_LIST.on_click(list.get_selected().get_metadata(0), _mouse_position)


func _on_list_changed() -> void:
	list.clear()

	var root: TreeItem = list.create_item()
	var base: TreeItem = root.create_child()

	base.set_text(0, 'Base')
	base.set_metadata(0, {route = (Engine.get_singleton(&'Global') as HenGlobal).BASE_ROUTE})

	# variables
	_add_categories(root, 'Signals', AddType.SIGNAL)
	_add_categories(root, 'Variables', AddType.VAR)
	_add_categories(root, 'Functions', AddType.FUNC)
	_add_categories(root, 'Signals Callback', AddType.SIGNAL_CALLBACK)
	_add_categories(root, 'Macros', AddType.MACRO)

	var router: HenRouter = Engine.get_singleton(&'Router')
	if router.current_route and router.current_route.get_ref() and router.current_route.get_ref().get(&'local_vars') is Array:
		_add_categories(root, 'Local Variables', AddType.LOCAL_VAR)


func _add_categories(_root: TreeItem, _name: String, _type: AddType) -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')
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
			arr = global.SIDE_BAR_LIST.var_list
		AddType.FUNC:
			arr = global.SIDE_BAR_LIST.func_list
		AddType.SIGNAL_CALLBACK:
			arr = global.SIDE_BAR_LIST.signal_callback_list
		AddType.MACRO:
			arr = global.SIDE_BAR_LIST.macro_list
		AddType.LOCAL_VAR:
			var router: HenRouter = Engine.get_singleton(&'Router')
			if router.current_route.get_ref().get(&'local_vars') is Array:
				arr = (router.current_route.get_ref().local_vars as Array)
		AddType.SIGNAL:
			arr = global.SIDE_BAR_LIST.signal_list

	for item_data in arr:
		var item: TreeItem = category.create_child()
		var icon: Texture2D
		item.set_metadata(0, item_data)

		var icon_color: Color
		match _type:
			AddType.VAR, AddType.LOCAL_VAR:
				icon = HenUtils.get_icon_texture(item_data.type)
				icon_color = Color.WHITE
			_:
				icon = ICONS[_type]
				icon_color = BG_COLOR[_type]
		
		item.set_cell_mode(0, TreeItem.TreeCellMode.CELL_MODE_CUSTOM)
		item.set_custom_draw_callback(0, _draw_custom_button.bind(item_data.name, icon, icon_color))
		item.set_custom_color(0, Color.WHITE)


func _draw_custom_button(_item: TreeItem, _rect: Rect2, _text: String = "", _icon: Texture2D = null, _icon_color: Color = Color.WHITE) -> void:
	var font: Font = list.get_theme_font(&'font', &'Tree')
	var font_size: int = list.get_theme_font_size(&'font_size', &'Tree')
	var text_size: Vector2 = font.get_string_size(_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var padding = 50
	var button_width = text_size.x + padding
	
	# add vertical spacing by reducing the height and adding margin
	var spacing = 4
	var button_height = _rect.size.y - spacing
	var button_pos = Vector2(_rect.position.x, _rect.position.y + spacing / 2.)
	
	# draw the stylebox with reduced height
	list.draw_style_box(TREE_ITEM_STYLEBOX, Rect2(button_pos, Vector2(button_width, button_height)))
	
	if _icon:
		var icon_size = Vector2(14, 14)
		var icon_pos = Vector2(button_pos.x + 8, button_pos.y + (button_height - icon_size.y) / 2)
		list.draw_texture_rect(_icon, Rect2(icon_pos, icon_size), false, _icon_color)
		
		# draw text after icon with spacing
		var text_offset = icon_size.x + spacing
		var text_pos_x = button_pos.x + text_offset + (button_width - text_offset - text_size.x) / 2
		var text_pos_y = button_pos.y + (button_height + font.get_ascent(font_size)) / 2
		var text_pos = Vector2(text_pos_x, text_pos_y)
		list.draw_string(font, text_pos, _text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color('#737278'))
	else:
		# draw text centered when no icon
		var text_pos_x = button_pos.x + button_width / 2 - text_size.x / 2
		var text_pos_y = button_pos.y + (button_height + font.get_ascent(font_size)) / 2
		var text_pos = Vector2(text_pos_x, text_pos_y)
		list.draw_string(font, text_pos, _text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color('#737278'))


func _on_list_button_clicked(_item: TreeItem, _column: int, _id: int, _mouse_button_index: int) -> void:
	var _type: AddType = _item.get_metadata(0)
	var global: HenGlobal = Engine.get_singleton(&'Global')
	
	global.SIDE_BAR_LIST.change(_type)
	global.SIDE_BAR_LIST.add()
