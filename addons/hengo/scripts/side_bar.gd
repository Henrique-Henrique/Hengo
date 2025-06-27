@tool
class_name HenSideBar extends PanelContainer

var list: Tree


const ADD_ICON = preload('res://addons/hengo/assets/icons/plus.svg')
const CATEGORY_FONT = preload('res://addons/hengo/assets/fonts/Inter-Bold.ttf')

enum AddType {VAR, FUNC, SIGNAL, LOCAL_VAR, MACRO}
enum ParamType {INPUT, OUTPUT}

const BG_COLOR = {
	AddType.VAR: Color('#509fa6'),
	AddType.FUNC: Color('#b05353'),
	AddType.SIGNAL: Color('#51a650'),
	AddType.MACRO: Color('#9f50a6'),
	AddType.LOCAL_VAR: Color('#a69150')
}

const ICONS = {
	AddType.VAR: preload('res://addons/hengo/assets/icons/menu/cuboid.svg'),
	AddType.MACRO: preload('res://addons/hengo/assets/icons/menu/text.svg'),
	AddType.FUNC: preload('res://addons/hengo/assets/icons/menu/void.svg'),
	AddType.SIGNAL: preload('res://addons/hengo/assets/icons/menu/wifi.svg'),
	AddType.LOCAL_VAR: preload('res://addons/hengo/assets/icons/menu/cuboid.svg')
}

const NAME = {
	AddType.VAR: 'Variables',
	AddType.FUNC: 'Functions',
	AddType.SIGNAL: 'Signals',
	AddType.LOCAL_VAR: 'Local Variables',
	AddType.MACRO: 'Macro'
}


class SideBarList:
	var type: AddType

	var var_list: Array
	var func_list: Array
	var signal_list: Array
	var macro_list: Array

	signal list_changed

	func clear() -> void:
		var_list.clear()
		func_list.clear()
		signal_list.clear()
		macro_list.clear()

		change(AddType.VAR)
		list_changed.emit()

	func add() -> void:
		match type:
			AddType.VAR:
				var_list.append(HenVarData.new())
			AddType.FUNC:
				func_list.append(HenFuncData.new())
			AddType.SIGNAL:
				signal_list.append(HenSignalData.new())
			AddType.MACRO:
				macro_list.append(HenMacroData.new())
			AddType.LOCAL_VAR:
				if HenRouter.current_route.ref.get(&'local_vars') is Array:
					var var_data: HenVarData = HenVarData.new()
					var_data.local_ref = HenRouter.current_route.ref
					
					(HenRouter.current_route.ref.local_vars as Array).append(var_data)

		list_changed.emit()

	func change(_type: AddType) -> void:
		type = _type

	func get_list_to_draw() -> Array:
		match type:
			AddType.VAR:
				return var_list.map(func(x: HenVarData): return {name = x.name})
			AddType.FUNC:
				return func_list.map(func(x: HenFuncData): return {name = x.name})
			AddType.SIGNAL:
				return signal_list.map(func(x: HenSignalData): return {name = x.name})
			AddType.MACRO:
				return macro_list.map(func(x: HenMacroData): return {name = x.name})
			AddType.LOCAL_VAR:
				if HenRouter.current_route.ref.get(&'local_vars') is Array:
					return (HenRouter.current_route.ref.local_vars as Array).map(func(x: HenVarData): return {name = x.name})
			
		return []
	
	func on_click(_item) -> void:
		var inspector_item_arr: Array
		var name: String = ''

		inspector_item_arr = _item.get_inspector_array_list()

		name = _item.name

		var state_inspector: HenInspector = HenInspector.start(inspector_item_arr)

		state_inspector.item_changed.connect(_on_config_changed)

		HenGlobal.GENERAL_POPUP.get_parent().show_content(
			state_inspector,
			name,
			HenGlobal.CNODE_CONTAINER.get_global_mouse_position()
		)

	func _on_config_changed(_name: StringName, _ref, _inspector: HenInspector) -> void:
		if _ref is HenSignalData and _name == 'signal_name':
			HenInspector.start(_ref.get_inspector_array_list(), _inspector)

		list_changed.emit()
	
	func get_save() -> Dictionary:
		return {
			var_list = var_list.map(func(x: HenVarData): return x.get_save()),
			func_list = func_list.map(func(x: HenFuncData): return x.get_save()),
			signal_list = signal_list.map(func(x: HenSignalData): return x.get_save()),
			macro_list = macro_list.map(func(x: HenMacroData): return x.get_save())
		}
	
	func load_save(_data: Dictionary) -> void:
		for item_data: Dictionary in _data.var_list:
			var item: HenVarData = HenVarData.new()
			item.load_save(item_data)
			var_list.append(item)

		for item_data: Dictionary in _data.func_list:
			var item: HenFuncData = HenFuncData.new(false)
			item.load_save(item_data)
			func_list.append(item)
		
		for item_data: Dictionary in _data.signal_list:
			var item: HenSignalData = HenSignalData.new(false)
			item.load_save(item_data)
			signal_list.append(item)

		for item_data: Dictionary in _data.macro_list:
			var item: HenMacroData = HenMacroData.new(false)
			item.load_save(item_data)
			macro_list.append(item)

		# loading cnodes
		for item in HenGlobal.SIDE_BAR_LIST_CACHE.values():
			if item.get('cnode_list_to_load') is Array:
				HenLoader._load_vc(item.cnode_list_to_load, item.route)

		list_changed.emit()

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
		item.invalid = true
		HenGlobal.SIDE_BAR_LIST.list_changed.emit()
	
	func add() -> void:
		arr.append(item)
		HenUtils.move_array_item_to_idx(arr, item, idx)
		item.emit_signal('deleted', false)
		item.invalid = false
		HenGlobal.SIDE_BAR_LIST.list_changed.emit()


func _ready() -> void:
	if EditorInterface.get_edited_scene_root() == self or EditorInterface.get_edited_scene_root() == owner:
		set_process(false)
		set_physics_process(false)
		set_process_input(false)
		set_process_unhandled_input(false)
		set_process_unhandled_key_input(false)
		return

	list = get_node('%List')
	list.auto_tooltip = false
	list.button_clicked.connect(_on_list_button_clicked)
	list.item_mouse_selected.connect(_on_item_selected)
	list.item_selected.connect(_on_select)
	list.gui_input.connect(_on_gui)
	list.mouse_exited.connect(_on_exit)

	HenGlobal.SIDE_BAR = self
	HenGlobal.SIDE_BAR_LIST = SideBarList.new()
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

		if item:
			var data = item.get_metadata(0)
			var pos: Vector2 = (_event as InputEventMouseMotion).global_position + Vector2(20, 20)

			if not data is int:
				if data is HenVarData:
					HenGlobal.TOOLTIP.go_to(pos, '[b]{type}[/b]\n{name}\n\n{inspect}'.format({
						name = data.name,
						type = data.type,
						inspect = HenEnums.TOOLTIP_TEXT.RIGHT_MOUSE_INSPECT
					}))
				elif data is HenFuncData:
					HenGlobal.TOOLTIP.go_to(pos, '{name}\n\n[b]Input size: [/b]{in_size}\n\n[b]Output size: [/b]{out_size}\n\n{inspect}\n{enter}'.format({
						name = data.name,
						in_size = data.inputs.size(),
						out_size = data.outputs.size(),
						inspect = HenEnums.TOOLTIP_TEXT.RIGHT_MOUSE_INSPECT,
						enter = HenEnums.TOOLTIP_TEXT.DOUBLE_CLICK
					}))
				elif data is HenSignalData:
					HenGlobal.TOOLTIP.go_to(pos, '{name}\n\n[b]Signal: [/b] {s_name}\n\n{inspect}\n{enter}'.format({
						name = data.name,
						s_name = data.signal_name if data.signal_name else 'Not Selected',
						inspect = HenEnums.TOOLTIP_TEXT.RIGHT_MOUSE_INSPECT,
						enter = HenEnums.TOOLTIP_TEXT.DOUBLE_CLICK
					}))
				elif data is HenMacroData:
					HenGlobal.TOOLTIP.go_to(pos, '{name}\n\n[b]Flow Input Size: [/b] {fi_size}\n[b]Flow Output Size: [/b] {fo_size}\n\n[b]Input Size: [/b] {i_size}\n[b]Output Size: [/b] {o_size}\n\n{inspect}\n{enter}'.format({
						name = data.name,
						fi_size = data.inputs.size(),
						fo_size = data.outputs.size(),
						i_size = data.inputs_value.size(),
						o_size = data.outputs_value.size(),
						inspect = HenEnums.TOOLTIP_TEXT.RIGHT_MOUSE_INSPECT,
						enter = HenEnums.TOOLTIP_TEXT.DOUBLE_CLICK
					}))
			else:
				HenGlobal.TOOLTIP.close()
		

func _on_select() -> void:
	var obj = list.get_selected().get_metadata(0)

	await RenderingServer.frame_post_draw
	
	if obj.get('route'):
		HenRouter.change_route(obj.get('route'))

func _on_item_selected(_mouse_position: Vector2, _mouse_button_index: int) -> void:
	match _mouse_button_index:
		2:
			HenGlobal.SIDE_BAR_LIST.on_click(list.get_selected().get_metadata(0))


func _on_list_changed() -> void:
	list.clear()

	var root: TreeItem = list.create_item()
	var base: TreeItem = root.create_child()

	base.set_text(0, 'Base')
	base.set_metadata(0, {route = HenGlobal.BASE_ROUTE})

	# variables
	_add_categories(root, 'Variables', AddType.VAR)
	_add_categories(root, 'Functions', AddType.FUNC)
	_add_categories(root, 'Signals', AddType.SIGNAL)
	_add_categories(root, 'Macros', AddType.MACRO)

	if not HenRouter.current_route.is_empty() and HenRouter.current_route.ref.get(&'local_vars') is Array:
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
		AddType.SIGNAL:
			arr = HenGlobal.SIDE_BAR_LIST.signal_list
		AddType.MACRO:
			arr = HenGlobal.SIDE_BAR_LIST.macro_list
		AddType.LOCAL_VAR:
			if HenRouter.current_route.ref.get(&'local_vars') is Array:
				arr = (HenRouter.current_route.ref.local_vars as Array)

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
