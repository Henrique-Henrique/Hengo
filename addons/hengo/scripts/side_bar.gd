@tool
class_name HenSideBar extends PanelContainer

enum SideBarItem {
	VARIABLES,
	FUNCTIONS,
	SIGNALS,
	SIGNALS_CALLBACK,
	MACROS,
	STATES
}

var list: Tree

const ADD_ICON = preload('res://addons/hengo/assets/icons/plus.svg')

enum AddType {VAR, FUNC, SIGNAL_CALLBACK, SIGNAL, LOCAL_VAR, MACRO, STATE}
enum ParamType {INPUT, OUTPUT}

var BG_COLOR: Dictionary
var ICONS: Dictionary


class DeleteResourceCommand:
	var side_bar: HenSideBar
	var save_data: HenSaveData
	var meta: HenSaveResType
	var removed_route_ids: Array[StringName] = []
	var removed_routes: Dictionary = {}
	var removed_items: Array[Dictionary] = []
	var removed_sub_states: Dictionary = {}
	var file_entries: Array[Dictionary] = []

	func _init(_side_bar: HenSideBar, _meta: HenSaveResType) -> void:
		side_bar = _side_bar
		meta = _meta
		save_data = (Engine.get_singleton(&'Global') as HenGlobal).SAVE_DATA
		if not save_data or not meta:
			return

		if meta is HenSaveState:
			side_bar._collect_state_delete_cache(meta as HenSaveState, removed_items, removed_route_ids, removed_sub_states)
		else:
			var target: Array = side_bar._get_target_array_for_meta(meta)
			if target:
				var idx: int = target.find(meta)
				if idx >= 0:
					removed_items.append({array = target, idx = idx, item = meta})

			if meta is HenSaveResTypeWithRoute:
				removed_route_ids.append(meta.id)

		for route_id: StringName in removed_route_ids:
			if save_data.routes.has(route_id):
				removed_routes[route_id] = save_data.routes[route_id]

		file_entries = side_bar._get_file_entries_for_delete(meta, removed_items, removed_route_ids)


	func can_remove() -> bool:
		return not removed_items.is_empty()


	func remove() -> void:
		if not can_remove():
			return

		var items_desc: Array = removed_items.duplicate()
		items_desc.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return int(a.idx) > int(b.idx)
		)

		for item_info: Dictionary in items_desc:
			side_bar._remove_item_from_array(item_info.array as Array, item_info.item)

		for route_id in removed_routes.keys():
			save_data.routes.erase(route_id)

		for state_id in removed_sub_states.keys():
			save_data.sub_states.erase(state_id)

		for file_info: Dictionary in file_entries:
			side_bar._move_res_path_to_trash(str(file_info.path))

		side_bar._after_resource_removed(removed_route_ids)


	func add() -> void:
		if not can_remove():
			return

		for route_id in removed_routes.keys():
			save_data.routes[route_id] = removed_routes[route_id]

		for state_id in removed_sub_states.keys():
			save_data.sub_states[state_id] = (removed_sub_states[state_id] as Array).duplicate()

		var items_asc: Array = removed_items.duplicate()
		items_asc.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return int(a.idx) < int(b.idx)
		)

		for item_info: Dictionary in items_asc:
			var target: Array = item_info.array
			var item: Variant = item_info.item
			if target.find(item) >= 0:
				continue

			var insert_idx: int = clampi(int(item_info.idx), 0, target.size())
			target.insert(insert_idx, item)

		for file_info: Dictionary in file_entries:
			side_bar._save_resource_at_path(file_info.res as Resource, str(file_info.path))

		side_bar._after_resource_restored()


func _ready() -> void:
	if HenUtils.disable_scene_with_owner(self):
		return

	print(1234)

	BG_COLOR = {
		AddType.STATE: HenEnums.FLOW_COLORS[5],
		AddType.VAR: HenEnums.FLOW_COLORS[1],
		AddType.FUNC: HenEnums.FLOW_COLORS[2],
		AddType.SIGNAL_CALLBACK: HenEnums.FLOW_COLORS[0],
		AddType.MACRO: HenEnums.FLOW_COLORS[4],
		AddType.LOCAL_VAR: HenEnums.FLOW_COLORS[3],
		AddType.SIGNAL: HenEnums.FLOW_COLORS[0]
	}

	ICONS = {
		AddType.STATE: HenUtils.ICON_STATE,
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
			if meta:
				HenInspector.edit_resource(meta, _get_inspect_title(meta), _get_inspect_actions(meta))


func update() -> void:
	list.clear()

	var root: TreeItem = list.create_item()
	var base: TreeItem = root.create_child()

	base.set_text(0, 'Base')
	base.set_metadata(0, (Engine.get_singleton(&'Global') as HenGlobal).SAVE_DATA.get_base_route())

	_add_categories(root, 'States', AddType.STATE)
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
		AddType.STATE:
			for state_data: HenSaveState in global.SAVE_DATA.states:
				var item: TreeItem = create_item(
					category,
					state_data.name,
					state_data,
					ICONS[_type],
					BG_COLOR[_type]
				)
				_add_sub_states(item, state_data, _type)
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


func _add_sub_states(parent: TreeItem, state: HenSaveState, type: AddType) -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var sub_states: Array = state.get_sub_states(global.SAVE_DATA)

	if sub_states.is_empty():
		return

	for sub_state: HenSaveState in sub_states:
		var item: TreeItem = create_item(
			parent,
			sub_state.name,
			sub_state,
			ICONS[type],
			BG_COLOR[type]
		)
		_add_sub_states(item, sub_state, type)


func create_item(_category: TreeItem, _name: String, _meta: HenSaveResType, _icon: Texture2D = null, _icon_color: Color = Color.WHITE) -> TreeItem:
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
	
	if _meta is HenSaveState:
		item.add_button(0, ADD_ICON)

	return item


func _on_list_button_clicked(_item: TreeItem, _column: int, _id: int, _mouse_button_index: int) -> void:
	var meta = _item.get_metadata(0)
	var global: HenGlobal = Engine.get_singleton(&'Global')
	
	if meta is int:
		match meta:
			AddType.STATE:
				global.SAVE_DATA.add_state()
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
	elif meta is HenSaveState:
		(meta as HenSaveState).add_sub_state(global.SAVE_DATA)
		
	update()


func _get_inspect_title(meta: Variant) -> String:
	if meta is HenSaveResType:
		return '%s (%s)' % [meta.name, meta.get_class()]
	if meta is Resource:
		return meta.get_class()
	return 'Inspector'


func _get_inspect_actions(meta: Variant) -> Array[Dictionary]:
	if not meta is HenSaveResType:
		return []

	return [
		{
			name = 'Delete',
			callable = _confirm_delete_resource.bind(meta),
			color = Color('#c16460'),
			icon = 'res://addons/hengo/assets/new_icons/trash-2.svg'
		}
	]


func _confirm_delete_resource(meta: HenSaveResType) -> void:
	if not meta:
		return

	var message: String = "Are you sure you want to delete '%s'?" % meta.name
	HenConfirmPopup.show_confirm(
		message,
		_request_delete_resource.bind(meta),
		'Delete Resource',
		'Delete',
		'Cancel'
	)


func _request_delete_resource(meta: HenSaveResType) -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	if not global or not global.SAVE_DATA or not meta:
		return

	var cmd := DeleteResourceCommand.new(self, meta)
	if not cmd.can_remove():
		return

	if global.history:
		global.history.create_action('Delete ' + meta.name)
		global.history.add_do_method(cmd.remove)
		global.history.add_undo_reference(cmd)
		global.history.add_undo_method(cmd.add)
		global.history.commit_action()
	else:
		cmd.remove()

	(Engine.get_singleton(&'GeneralPopup') as HenGeneralPopup).hide_popup()


func _remove_item_from_array(target: Array, item: Variant) -> bool:
	var idx: int = target.find(item)
	if idx < 0:
		return false

	target.remove_at(idx)
	return true


func _collect_state_delete_cache(state: HenSaveState, removed_items: Array[Dictionary], removed_route_ids: Array[StringName], removed_sub_states: Dictionary) -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var save_data: HenSaveData = global.SAVE_DATA
	if not save_data:
		return

	_add_state_array_entry(save_data.states, state, removed_items)

	for sub_list: Array in save_data.sub_states.values():
		_add_state_array_entry(sub_list, state, removed_items)

	if not removed_route_ids.has(state.id):
		removed_route_ids.append(state.id)

	if save_data.sub_states.has(state.id):
		if not removed_sub_states.has(state.id):
			removed_sub_states[state.id] = (save_data.sub_states[state.id] as Array).duplicate()

		for sub_state in save_data.sub_states[state.id]:
			if sub_state is HenSaveState:
				_collect_state_delete_cache(sub_state as HenSaveState, removed_items, removed_route_ids, removed_sub_states)


func _add_state_array_entry(target: Array, state: HenSaveState, removed_items: Array[Dictionary]) -> void:
	var idx: int = target.find(state)
	if idx < 0:
		return

	for item_info: Dictionary in removed_items:
		if item_info.array == target and item_info.item == state:
			return

	removed_items.append({array = target, idx = idx, item = state})


func _move_res_path_to_trash(res_path: String) -> void:
	if res_path.is_empty():
		return

	var global_path: String = ProjectSettings.globalize_path(res_path)
	if not FileAccess.file_exists(global_path):
		return

	OS.move_to_trash(global_path)


func _save_resource_at_path(res: Resource, res_path: String) -> void:
	if not res or res_path.is_empty():
		return

	var base_dir: String = res_path.get_base_dir()
	if not DirAccess.dir_exists_absolute(base_dir):
		DirAccess.make_dir_recursive_absolute(base_dir)

	res.take_over_path(res_path)
	ResourceSaver.save(res, res_path)


func _after_resource_removed(removed_route_ids: Array[StringName]) -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var save_data: HenSaveData = global.SAVE_DATA

	var router: HenRouter = Engine.get_singleton(&'Router')
	if router and router.current_route and removed_route_ids.has(router.current_route.id):
		router.change_route(save_data.get_base_route())

	update()
	if global.HENGO_ROOT:
		global.HENGO_ROOT.schedule_check_errors()
	if global.DASHBOARD and global.DASHBOARD.visible:
		global.DASHBOARD.refresh()


func _after_resource_restored() -> void:
	update()
	var global: HenGlobal = Engine.get_singleton(&'Global')
	if global.HENGO_ROOT:
		global.HENGO_ROOT.schedule_check_errors()
	if global.DASHBOARD and global.DASHBOARD.visible:
		global.DASHBOARD.refresh()


func _get_target_array_for_meta(meta: HenSaveResType) -> Array:
	var save_data: HenSaveData = (Engine.get_singleton(&'Global') as HenGlobal).SAVE_DATA
	if not save_data:
		return []

	if meta is HenSaveVar:
		return save_data.variables
	if meta is HenSaveFunc:
		return save_data.functions
	if meta is HenSaveSignal:
		return save_data.signals
	if meta is HenSaveSignalCallback:
		return save_data.signals_callback
	if meta is HenSaveMacro:
		return save_data.macros
	if meta is HenSaveState:
		return save_data.states

	return []


func _get_file_entries_for_delete(meta: HenSaveResType, removed_items: Array[Dictionary], removed_route_ids: Array[StringName]) -> Array[Dictionary]:
	var save_data: HenSaveData = (Engine.get_singleton(&'Global') as HenGlobal).SAVE_DATA
	if not save_data:
		return []

	var result: Array[Dictionary] = []
	var path_set: Dictionary = {}

	var append_entry: Callable = func(res: Resource, res_path: String) -> void:
		if not res or res_path.is_empty() or path_set.has(res_path):
			return
		path_set[res_path] = true
		result.append({res = res, path = res_path})

	var side_bar_type: int = _get_side_bar_item_type(meta)
	if meta is HenSaveState:
		var base_path: String = str(HenUtils.get_side_bar_item_path(save_data.identity.id, SideBarItem.STATES))
		for route_id in removed_route_ids:
			for item_info: Dictionary in removed_items:
				var state_item: Variant = item_info.item
				if state_item is HenSaveState and state_item.id == route_id:
					append_entry.call(state_item, base_path + str(route_id) + '.tres')
					break
	else:
		if side_bar_type >= 0:
			append_entry.call(meta, str(HenUtils.get_side_bar_item_path(save_data.identity.id, side_bar_type)) + str(meta.id) + '.tres')
		if not meta.resource_path.is_empty():
			append_entry.call(meta, meta.resource_path)

	return result


func _get_side_bar_item_type(meta: HenSaveResType) -> int:
	if meta is HenSaveVar:
		return SideBarItem.VARIABLES
	if meta is HenSaveFunc:
		return SideBarItem.FUNCTIONS
	if meta is HenSaveSignal:
		return SideBarItem.SIGNALS
	if meta is HenSaveSignalCallback:
		return SideBarItem.SIGNALS_CALLBACK
	if meta is HenSaveMacro:
		return SideBarItem.MACROS
	if meta is HenSaveState:
		return SideBarItem.STATES

	return -1
