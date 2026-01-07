@tool
class_name HenCodeSearch extends VBoxContainer

const CODE_SEARCH = preload('res://addons/hengo/scenes/code_search.tscn')
const CODE_SEARCH_ITEM = preload('res://addons/hengo/scenes/code_search_item.tscn')

@onready var search_input: LineEdit = %Search

@export var first_list_virtual_list_item: PackedScene

var current_tab: int = 0
var config: Dictionary
var start_pos: Vector2
var categories: Dictionary
var loading_label: Label

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
	set_data.call_deferred(0, _list)


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
	call_deferred("update")


func set_data(_virtual_list_id: int, _api_list: Array) -> void:
	var virtual_list: HenVirtualList

	var first_list: ScrollContainer = get_node('%FirstList')
	var second_list: ScrollContainer = get_node('%SecondList')
	var third_list: ScrollContainer = get_node('%ThirdList')

	match _virtual_list_id:
		0:
			virtual_list = first_list.get_node('%VirtualList')
			first_list.visible = true
			second_list.visible = false
			third_list.visible = false
		1:
			virtual_list = second_list.get_node('%VirtualList')
			first_list.visible = true
			second_list.visible = not _api_list.is_empty()
			third_list.visible = false
		2:
			virtual_list = third_list.get_node('%VirtualList')
			first_list.visible = true
			second_list.visible = true
			third_list.visible = not _api_list.is_empty()

	if virtual_list: virtual_list.set_data(_api_list)

	match _virtual_list_id:
		1, 2:
			await get_tree().process_frame
			(first_list.get_node('%VirtualList') as HenVirtualList).update.call_deferred(true)
			(second_list.get_node('%VirtualList') as HenVirtualList).update.call_deferred(true)
			(third_list.get_node('%VirtualList') as HenVirtualList).update.call_deferred(true)


func _update_loading(loading: bool) -> void:
	if not loading_label:
		loading_label = Label.new()
		loading_label.text = "Loading..."
		loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		loading_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		loading_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
		loading_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.5))
		add_child(loading_label)
		move_child(loading_label, 1)

	loading_label.visible = loading
	
	var first_list: ScrollContainer = get_node('%FirstList')
	var second_list: ScrollContainer = get_node('%SecondList')
	var third_list: ScrollContainer = get_node('%ThirdList')
	
	if loading:
		first_list.visible = false
		second_list.visible = false
		third_list.visible = false
	else:
		# Restoration of visibility is handled by set_data
		pass

func update() -> void:
	_update_loading(true)
	
	var global: HenGlobal = Engine.get_singleton('Global')
	
	var input_data: Dictionary = {
		"config": config.duplicate(true),
		"global_identity_type": global.SAVE_DATA.identity.type,
		"categories": categories.duplicate(true)
	}
	
	var thread_helper: HenThreadHelper = Engine.get_singleton(&'ThreadHelper')
	thread_helper.add_task(_threaded_update.bind(input_data))

func _threaded_update(input_data: Dictionary) -> void:
	var api: HenApi = Engine.get_singleton(&'API')
	var data: Dictionary = api.get_decompressed_data()

	if not data:
		call_deferred("_on_update_completed", [])
		return
	
	var map_dep: HenMapDependencies = Engine.get_singleton(&'MapDependencies')
	var io_type: StringName = (input_data.config as Dictionary).get(&'io_type', &'')
	var type: StringName = (input_data.config as Dictionary).get(&'type', &'')
	var native_props: Dictionary = data.get(&'native_props')
	
	# results container: properties, map list, hengo list, native, inheritance
	var results: Array = [[], null, null, null, []]
	
	var thread_data: Dictionary = {
		"results": results,
		"api": api,
		"map_dep": map_dep,
		"io_type": io_type,
		"type": type,
		"native_props": native_props,
		"data": data,
		"input_data": input_data
	}
	
	var group_id: int = WorkerThreadPool.add_group_task(_worker_task.bind(thread_data), 5, -1, true, "CodeSearchContext")
	WorkerThreadPool.wait_for_group_task_completion(group_id)
	
	var api_list: Array[Dictionary] = []
	
	# assemble the final list in order
	api_list.append_array(results[0])
	
	if results[1] and not (results[1].categories as Array).is_empty():
		api_list.append(results[1])
		
	if results[2] and not (results[2].categories as Array).is_empty():
		api_list.append(results[2])
		
	if results[3] and not (results[3].categories as Array).is_empty():
		api_list.append(results[3])
		
	api_list.append_array(results[4])

	call_deferred("_on_update_completed", api_list)


func _worker_task(idx: int, thread_data: Dictionary) -> void:
	var api: HenApi = thread_data.api
	var map_dep: HenMapDependencies = thread_data.map_dep
	var io_type: StringName = thread_data.io_type
	var type: StringName = thread_data.type
	var native_props: Dictionary = thread_data.native_props
	var data: Dictionary = thread_data.data
	
	match idx:
		0:
			if type and io_type == 'out':
				var getter_dt: Dictionary = {
					_class_name = type,
					return_type = type,
					io_type = io_type,
					is_getter = true,
					is_setter = true
				}

				var getter_list = api.get_native_props_as_data(getter_dt, io_type, '', native_props)

				if not getter_list.is_empty():
					(thread_data.results[0] as Array).append({
						_class_name = 'Properties',
						categories = [
							{
								_class_name = type,
								method_list = getter_list,
								name = 'Properties',
								icon = 'activity',
								color = '#ff9ff3'
							}
						]
					})
		
		1:
			thread_data.results[1] = map_dep.get_code_search_list(io_type, type)
			
		2:
			thread_data.results[2] = api.get_side_bar_list(io_type, type)
			
		3:
			var native_list: Array = api.get_native_list_raw(io_type, type)
			if not native_list.is_empty():
				thread_data.results[3] = {_class_name = 'Native', categories = native_list, is_native = true}
				
		4:
			var _class: StringName = thread_data.input_data.global_identity_type
			var item_list: Array = get_class_parent_recursively(_class)

			# filter categories with api data
			for item: Dictionary in item_list:
				if item.get(&'is_native', false): continue

				var class_data: Dictionary = data.classes[item._class_name]
				var new_categories: Array = []
			
				for category: Dictionary in item.get(&'categories', []):
					var new_methods: Array = []

					for method_name: StringName in category.get(&'method_list', []):
						if not (class_data.methods as Dictionary).has(method_name):
							continue
						
						var new_data: Dictionary = (class_data.methods as Dictionary).get(method_name)

						if not new_data:
							continue

						new_data.name = method_name
						new_data._class_name = item._class_name
						new_data.data = HenApiSerialize.get_func_void_hengo_data(new_data)

						if not api.check_type_validity(new_data, io_type, type, native_props):
							continue
						
						var sub_items: Array = []
						var is_strict_match: bool = not new_data.get(&'use_props_only', false)

						if is_strict_match:
							var data_copy: Dictionary = new_data.duplicate()
							if not io_type:
								data_copy.force_valid = true
							sub_items.append(data_copy)
						
						var props: Array = api.get_native_props_as_data(new_data, io_type, type, native_props)

						if not io_type:
							for prop: Dictionary in props:
								prop.force_valid = true

						sub_items.append_array(props)

						if not sub_items.is_empty():
							var folder_item: Dictionary = new_data.duplicate()
							folder_item.recursive_props = sub_items
							folder_item.is_match = is_strict_match if type else true
							
							new_methods.append(folder_item)

					if not new_methods.is_empty():
						category.set(&'method_list', new_methods)
						new_categories.append(category)
				
				if not new_categories.is_empty():
					item.set(&'categories', new_categories)
					(thread_data.results[4] as Array).append(item)

func _on_update_completed(api_list: Array) -> void:
	_update_loading(false)
	set_data(0, api_list)


func get_native_props_as_data(_data: Dictionary, _native_props: Dictionary = {}) -> Array:
	var io_type: StringName = config.get(&'io_type', &'')
	var type: StringName = config.get(&'type', &'')
	var api: HenApi = Engine.get_singleton(&'API')
	return api.get_native_props_as_data(_data, io_type, type, _native_props)
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

	if _data.has(&'linked_prop'):
		var prop_data: Dictionary = _data.linked_prop
		var offset: Vector2 = Vector2(250, 0)
		prop_data.position = data.position + offset
		
		var prop_return: HenVCNodeReturn = HenVirtualCNode.instantiate(prop_data)
		global.history.add_do_method(prop_return.add)
		global.history.add_do_reference(prop_return)
		global.history.add_undo_method(prop_return.remove)
		
		if prop_return.v_cnode and vc_return.v_cnode:
			var source_idx: int = _data.get(&'linked_prop_source_idx', 0)
			var var_output = vc_return.v_cnode.get_output_by_idx(source_idx)
			var prop_input = prop_return.v_cnode.get_input_by_idx(0)
			
			if var_output and prop_input:
				var connection: HenVCConnectionReturn = prop_return.v_cnode.get_new_input_connection_command(
					prop_input.id,
					var_output.id,
					vc_return.v_cnode
				)
				if connection:
					global.history.add_do_method(connection.add)
					global.history.add_do_reference(connection)
					global.history.add_undo_method(connection.remove)
			
			# update vc_return to point to the property node for subsequent connections
			vc_return = prop_return

	if not vc_return.v_cnode:
		return

	if _data.has(&'input_io_idx'):
		var input_ref: HenVCInOutData = vc_return.v_cnode.get_input_by_idx(_data.get(&'input_io_idx'))

		if input_ref and config.get(&'id') != null and config.get(&'vc_ref'):
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

			if ref and config.get(&'id') != null:
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
	var global: HenGlobal = Engine.get_singleton(&'Global')

	code_search.current_tab = 0
	code_search.start_pos = _start_pos
	code_search.config = _config

	global.CODE_SEARCH = code_search

	return code_search
