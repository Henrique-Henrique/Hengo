@tool
class_name HenCodeSearch extends VBoxContainer

const CODE_SEARCH = preload('res://addons/hengo/scenes/code_search.tscn')
const CODE_SEARCH_ITEM = preload('res://addons/hengo/scenes/code_search_item.tscn')

@onready var search_input: LineEdit = %Search

@export var first_list_virtual_list_item: PackedScene

var config: Dictionary
var start_pos: Vector2
var categories: Dictionary

func _ready() -> void:
	if HenUtils.disable_scene_with_owner(self):
		return

	(get_node('%FirstList').get_node('%VirtualList') as HenVirtualList).item_scene = first_list_virtual_list_item

	clear_list()

	search_input.text_changed.connect(_search)

	var signal_bus: HenSignalBus = Engine.get_singleton(&'SignalBus')
	signal_bus.request_code_search_show_list.connect(_on_list_request)
	signal_bus.request_code_search_show_categories.connect(_show_custom_categories)
	signal_bus.request_code_search_type_result.connect(_on_search_result)
	signal_bus.request_code_search_select.connect(_on_select)

	search_input.grab_focus()

	var thread_helper: HenThreadHelper = Engine.get_singleton(&'ThreadHelper')
	thread_helper.add_task(_open_categories)


func _show_custom_categories(_list: Array) -> void:
	clear_list()
	set_data.call_deferred(_list)


func _search(_text: String) -> void:
	if _text.is_empty():
		return

	var api: HenApi = Engine.get_singleton(&'API')
	var io_type: StringName = config.get(&'io_type', &'')
	var type: StringName = config.get(&'type', &'')

	api.on_search_change(_text, io_type, type)


func _on_search_result(_list: Array) -> void:
	set_data.call_deferred(1, _list)


func clear_list() -> void:
	pass


func _on_list_request(_list: Array, _list_id: int = 1) -> void:
	set_data.call_deferred(_list_id, _list)


func _open_categories() -> void:
	var json: JSON = load('res://addons/hengo/resources/json/api_categories.json')
	categories = json.data
	update()


func set_data(_virtual_list_id: int, _api_list: Array) -> void:
	var virtual_list: HenVirtualList

	match _virtual_list_id:
		0: virtual_list = get_node('%FirstList').get_node('%VirtualList')
		1: virtual_list = get_node('%SecondList').get_node('%VirtualList')
		2: virtual_list = get_node('%ThirdList').get_node('%VirtualList')

	if virtual_list: virtual_list.set_data(_api_list)


func update() -> void:
	var api: HenApi = Engine.get_singleton(&'API')
	var data: Dictionary = api.get_decompressed_data()

	if not data:
		return
	
	var global: HenGlobal = Engine.get_singleton('Global')
	var map_dep: HenMapDependencies = Engine.get_singleton(&'MapDependencies')
	var io_type: StringName = config.get(&'io_type', &'')
	var type: StringName = config.get(&'type', &'')
	var api_list: Array[Dictionary] = []
	var map_list: Dictionary = map_dep.get_code_search_list(io_type, type)

	if type:
		var getter_dt: Dictionary = {
			_class_name = type,
			return_type = type,
			io_type = io_type
		}

		if io_type == 'out':
			getter_dt.set(&'is_getter', true)
		elif io_type == 'in':
			getter_dt.set(&'is_setter', true)

		var getter_list = api.get_native_props_as_data(getter_dt)

		if not getter_list.is_empty():
			api_list.append({
				_class_name = 'Getters',
				categories = [
					{
						_class_name = type,
						method_list = getter_list,
						name = 'Getters',
						icon = 'activity',
						color = '#ff9ff3'
					}
				]
			})

	if not (map_list.categories as Array).is_empty():
		api_list.append(map_list)

	var hengo_list: Dictionary = api.get_side_bar_list(io_type, type)

	if not (hengo_list.categories as Array).is_empty():
		api_list.append(hengo_list)
	
	var native_list: Array = api.get_native_list_raw(io_type, type)
	if not native_list.is_empty():
		api_list.append({_class_name = 'Native', categories = native_list, is_native = true})
	
	var _class: StringName = global.SAVE_DATA.identity.type
	var item_list: Array = get_class_parent_recursively(_class)

	# filter categories with API data
	# this is necessary because category only has method name
	for item: Dictionary in item_list:
		if item.get(&'is_native', false): continue

		var class_data: Dictionary = data.classes[item._class_name]
		var new_categories: Array = []
	
		for category: Dictionary in item.get(&'categories', []):
			var new_methods: Array = []

			for method_name: StringName in category.get(&'method_list', []):
				if not (class_data.methods as Dictionary).has(method_name):
					print('Category method not found: %s' % method_name)
					continue
				
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

	set_data.call_deferred(0, api_list)


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


func _on_select(_data: Dictionary) -> void:
	var data: Dictionary = _data.data if _data.has(&'data') else {}

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

	if not vc_return.v_cnode:
		return

	if _data.has(&'input_io_idx'):
		var input_ref: HenVCInOutData = vc_return.v_cnode.get_input_by_idx(_data.get(&'input_io_idx'))

		if input_ref:
			var connection: HenVCConnectionReturn = vc_return.v_cnode.get_new_input_connection_command(
				input_ref.id,
				config.get(&'id'),
				config.get(&'vc_ref')
			)

			if connection: connection.add()
	elif _data.has(&'output_io_idx'):
		var output_ref: HenVCInOutData = vc_return.v_cnode.get_output_by_idx(_data.get(&'output_io_idx'))

		if output_ref:
			var ref: HenVirtualCNode = config.get(&'vc_ref')

			if not ref:
				return

			var connection: HenVCConnectionReturn = ref.get_new_input_connection_command(
				config.get(&'id'),
				output_ref.id,
				vc_return.v_cnode
			)

			if connection: connection.add()

	# add connection when dragging from connector
	if config.has(&'from_flow_connector') and not vc_return.v_cnode.get_flow_inputs(global.SAVE_DATA).is_empty():
		var flow_connection := (config.from_flow_connector as HenVirtualCNode).add_flow_connection(config.id, vc_return.v_cnode.get_flow_inputs(global.SAVE_DATA)[0].id, vc_return.v_cnode)

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
