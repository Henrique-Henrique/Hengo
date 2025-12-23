@tool
class_name HenCodeSearch extends VBoxContainer

const CODE_SEARCH = preload('res://addons/hengo/scenes/code_search.tscn')
const CODE_SEARCH_ITEM = preload('res://addons/hengo/scenes/code_search_item.tscn')

@onready var list: Tree = %ItemList
@onready var info: RichTextLabel = %Info
@onready var search_input: LineEdit = %Search
@onready var tab_container: TabContainer = %TabContainer
@onready var navigation: HBoxContainer = %Navigation

var config: Dictionary
var start_pos: Vector2
var categories: Dictionary

func _ready() -> void:
	if HenUtils.disable_scene_with_owner(self):
		return

	clear_list()

	list.item_selected.connect(_on_select_item)
	list.item_activated.connect(_on_select)
	search_input.text_changed.connect(_search)
	(navigation.get_child(0) as Button).pressed.connect(back_to_classes)

	var signal_bus: HenSignalBus = Engine.get_singleton(&'SignalBus')
	signal_bus.request_code_search_show_list.connect(_on_list_request)
	signal_bus.request_code_search_show_categories.connect(_show_custom_categories)
	signal_bus.request_code_search_type_result.connect(_on_search_result)
	signal_bus.request_code_search_select.connect(_on_select)

	back_to_classes()
	
	search_input.grab_focus()

	var thread_helper: HenThreadHelper = Engine.get_singleton(&'ThreadHelper')
	thread_helper.add_task(_open_categories)


func _draw_text_start_end(_item: TreeItem, _rect: Rect2, start_text: String, end_text: String) -> void:
	var font: Font = list.get_theme_font(&'font', &'Tree')
	var font_size: int = list.get_theme_font_size(&'font_size', &'Tree')
	
	# calculate text sizes
	var end_text_size: Vector2 = font.get_string_size(end_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	
	# start text position (left)
	var start_text_pos_x = _rect.position.x + 8 # left padding
	var start_text_pos_y = _rect.position.y + (_rect.size.y + font.get_ascent(font_size)) / 2
	var start_text_pos = Vector2(start_text_pos_x, start_text_pos_y)
	
	# end text position (right)
	var end_text_pos_x = _rect.position.x + _rect.size.x - end_text_size.x - 8 # right padding
	var end_text_pos_y = _rect.position.y + (_rect.size.y + font.get_ascent(font_size)) / 2
	var end_text_pos = Vector2(end_text_pos_x, end_text_pos_y)
	
	# draw texts
	list.draw_string(font, start_text_pos, start_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)
	list.draw_string(font, end_text_pos, end_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color('#737278'))


func show_navigation_info(_class_name: StringName, _category: String) -> void:
	var class_bt: Button = navigation.get_child(1)
	var category_bt: Button = navigation.get_child(2)

	class_bt.visible = true
	category_bt.visible = true

	class_bt.text = _class_name
	category_bt.text = _category


func hide_navigation_info() -> void:
	(navigation.get_child(1) as Button).visible = false
	(navigation.get_child(2) as Button).visible = false


func back_to_classes() -> void:
	clear_list()
	hide_navigation_info()
	tab_container.set_current_tab(0)


func _show_custom_categories(_list: Array) -> void:
	clear_list()
	set_data.call_deferred(_list)


func _search(_text: String) -> void:
	if _text.is_empty():
		back_to_classes()
		return

	var api: HenApi = Engine.get_singleton(&'API')
	var io_type: StringName = config.get(&'io_type', &'')
	var type: StringName = config.get(&'type', &'')

	api.on_search_change(_text, io_type, type)


func _on_search_result(_list: Array) -> void:
	tab_container.set_current_tab(1)
	show_navigation_info('All', 'All')
	
	clear_list()

	for item: Dictionary in _list:
		var t_item: TreeItem = list.create_item()
		t_item.set_cell_mode(0, TreeItem.CELL_MODE_CUSTOM)
		t_item.set_custom_draw_callback(0, _draw_text_start_end.bind(item.name, item._class_name))
		t_item.set_metadata(0, item)


func _on_select_item() -> void:
	var item_data: Dictionary = list.get_selected().get_metadata(0)

	info.text = "[center][font_size=24][b][color=cyan]{_class_name}[/color][/b][/font_size][/center]

[center][font_size=16][color=lightblue]{method_name}[/color][/font_size][/center]

[center][hr color=black][/center]

[color=lightgray]{dsc}[/color]".format({
	_class_name = item_data._class_name,
	method_name = item_data.name,
	dsc = item_data.get(&'description', 'No Documentation')
})


func clear_list() -> void:
	list.clear()
	info.clear()
	list.create_item()


func _on_list_request(_class_name: StringName, _list: Array, _category_name: String) -> void:
	tab_container.set_current_tab(1)
	show_navigation_info(_class_name, _category_name)
	clear_list()
	var list_map: Array[Dictionary] = []

	for item: Dictionary in _list:
		var _name: String = item.get(&'name', '')
		var t_item: TreeItem = list.create_item()

		t_item.set_cell_mode(0, TreeItem.CELL_MODE_CUSTOM)
		t_item.set_custom_draw_callback(0, _draw_text_start_end.bind(_name, _class_name))
		t_item.set_metadata(0, item)


func _open_categories() -> void:
	var json: JSON = load('res://addons/hengo/resources/json/api_categories.json')
	categories = json.data
	update()


func set_data(_api_list: Array) -> void:
	var _list: HenVirtualList = get_node('%VirtualList')
	_list.set_data(_api_list)


func update() -> void:
	var api: HenApi = Engine.get_singleton(&'API')
	var data: Dictionary = api.get_decompressed_data()

	if not data:
		return
	
	var global: HenGlobal = Engine.get_singleton('Global')
	var map_dep: HenMapDependencies = Engine.get_singleton(&'MapDependencies')

	var api_list: Array[Dictionary] = [map_dep.get_code_search_list(), api.get_side_bar_list(), {_class_name = 'Native', categories = api.get_native_list_raw(), is_native = true}]
	var _class: StringName = global.SAVE_DATA.identity.type
	var item_list: Array = get_class_parent_recursively(_class)
	var io_type: StringName = config.get(&'io_type', &'')
	var type: StringName = config.get(&'type', &'')

	# filter categories with API data
	# this is necessary because category only has method name
	for item: Dictionary in item_list:
		if item.get(&'is_native', false): continue

		var class_data: Dictionary = data.classes[item._class_name]
		var new_categories: Array = []
	
		for category: Dictionary in item.get(&'categories', []):
			var new_methods: Array = []

			for method_name: StringName in category.get(&'method_list', []):
				var new_data: Dictionary = (class_data.methods as Dictionary).get(method_name)

				if not new_data:
					continue

				new_data.name = method_name
				new_data._class_name = item._class_name
				new_data.data = HenApiSerialize.get_func_void_hengo_data(new_data)

				if not api.check_type_validity(new_data, io_type, type):
					continue
				
				new_methods.append(new_data)

			if not new_methods.is_empty():
				category.set(&'method_list', new_methods)
				new_categories.append(category)
		
		if not new_categories.is_empty():
			item.set(&'categories', new_categories)
			api_list.append(item)

	set_data.call_deferred(api_list)


func get_class_name_categories(_class_name: StringName) -> Array[Dictionary]:
	var arr: Array[Dictionary] = []
	var class_categories: Dictionary = categories.get(_class_name, {})

	for category: StringName in class_categories.keys():
		var item: Dictionary = class_categories.get(category)

		arr.append({
			name = category,
			icon = item.icon,
			color = item.color,
			method_list = item.get(&'method_list', [])
		})

	return arr

	
func get_class_parent_recursively(_class_name: StringName) -> Array[Dictionary]:
	var arr: Array[Dictionary] = []
	var parent_class_name: StringName = ClassDB.get_parent_class(_class_name)

	if parent_class_name.is_empty():
		return [ {_class_name = _class_name, categories = get_class_name_categories(_class_name)}]
	
	arr.append({_class_name = _class_name, categories = get_class_name_categories(_class_name)})
	arr.append_array(get_class_parent_recursively(parent_class_name))

	return arr


func _on_select(_custom_data: Dictionary = {}) -> void:
	var item_data: Dictionary = list.get_selected().get_metadata(0) if _custom_data.is_empty() else _custom_data
	var data: Dictionary = item_data.data if item_data.has(&'data') else {}

	if data.is_empty():
		print('Not has data')
		return

	var global: HenGlobal = Engine.get_singleton(&'Global')
	data.position = global.CAM.get_relative_vec2(start_pos)

	var vc_return: HenVCNodeReturn = HenVirtualCNode.instantiate(data)

	global.history.create_action('Add CNode')
	global.history.add_do_method(vc_return.add)
	global.history.add_do_reference(vc_return)
	global.history.add_undo_method(vc_return.remove)

	if item_data.has(&'input_io_idx'):
		var input_ref: HenVCInOutData = vc_return.v_cnode.get_input_by_idx(item_data.get(&'input_io_idx'))

		if input_ref:
			var connection: HenVCConnectionReturn = vc_return.v_cnode.get_new_input_connection_command(
				input_ref.id,
				config.get(&'id'),
				config.get(&'vc_ref')
			)

			if connection: connection.add()
	elif item_data.has(&'output_io_idx'):
		var output_ref: HenVCInOutData = vc_return.v_cnode.get_output_by_idx(item_data.get(&'output_io_idx'))

		if output_ref:
			var connection: HenVCConnectionReturn = (config.get(&'vc_ref') as HenVirtualCNode).get_new_input_connection_command(
				config.get(&'id'),
				output_ref.id,
				vc_return.v_cnode
			)

			if connection: connection.add()


	# add connection when dragging from connector
	if config.has(&'from_flow_connector') and not vc_return.v_cnode.flow_inputs.is_empty():
		var flow_connection := (config.from_flow_connector as HenVirtualCNode).add_flow_connection(config.id, vc_return.v_cnode.flow_inputs[0].id, vc_return.v_cnode)

		if flow_connection:
			flow_connection.add()

	global.history.commit_action()
	global.GENERAL_POPUP.hide_popup()

	global.CAM._check_virtual_cnodes()
	await RenderingServer.frame_pre_draw
	HenFormatter.format_current_route()

static func load(_start_pos: Vector2, _config: Dictionary = {}) -> HenCodeSearch:
	var code_search: HenCodeSearch = CODE_SEARCH.instantiate()
	code_search.start_pos = _start_pos
	code_search.config = _config
	return code_search
