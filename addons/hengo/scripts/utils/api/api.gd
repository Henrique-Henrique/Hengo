@tool
class_name HenApi extends Node

const HENGO_CACHE_PATH = 'res://.godot/hengo/'
const EXTENSION_API_PATH = 'res://.godot/hengo/extension_api.json'
const EXTENSION_API_COMPRESSED_PATH = 'res://.godot/hengo/api_compressed.bin'
const API_VERSION: int = 1

var api_data: Dictionary = {}
var timer: SceneTreeTimer


enum Type {
	ENUM,
	METHOD,
	UTILITIES
}


class CompressedData:
	var bytes: PackedByteArray
	var original_size: int

	func _init(_bytes: PackedByteArray, _original_size: int) -> void:
		bytes = _bytes
		original_size = _original_size


func _ready() -> void:
	_generate_compressed_data()

		
func on_search_change(_text: String, _io_type: StringName = '', _type: StringName = '') -> void:
	debounce_search(0.3, search_api.bind(_text, _io_type, _type))


func check_hengo_folder() -> void:
	if not DirAccess.dir_exists_absolute(HENGO_CACHE_PATH):
		DirAccess.make_dir_absolute(HENGO_CACHE_PATH)


func _generate_compressed_data() -> void:
	check_hengo_folder()

	var compressed_api = await _get_compressed_api()
	if compressed_api:
		api_data = decompress_and_get_data(compressed_api)
	

func _get_compressed_api() -> CompressedData:
	if FileAccess.file_exists(EXTENSION_API_COMPRESSED_PATH):
		var data = load_compressed_data(EXTENSION_API_COMPRESSED_PATH)
		if data:
			return data
	
	return await _map_api()


func get_decompressed_data() -> Dictionary:
	if api_data.is_empty():
		print('Erro open compressed api')
		return {}

	return api_data


func map_category_data(_class_name: StringName, _item: Dictionary, _io_type: StringName = '', _type: StringName = '') -> Array:
	var data: Dictionary = get_decompressed_data()
	
	if not data:
		print('Not data')
		return []

	var class_data: Dictionary = data.classes[_class_name]
	var method_list_name: Array = _item.get(&'method_list', [])
	var arr: Array = []
	var native_props: Dictionary = data.get(&'native_props')

	if class_data.has(&"methods"):
		for method_name: StringName in (class_data.methods as Dictionary).keys():
			var method_lower = method_name.to_lower()
			if method_list_name.has(method_lower):
				var new_data: Dictionary = (class_data.methods[method_name] as Dictionary).duplicate()
				new_data.erase(&'use_props_only')
				new_data.erase(&'input_io_idx')
				new_data.erase(&'output_io_idx')
				
				new_data.name = method_lower
				new_data._class_name = _class_name
				new_data.data = HenApiSerialize.get_func_void_hengo_data(new_data)

				if not check_type_validity(new_data, _io_type, _type, native_props):
					continue
				
				if new_data.get(&'use_props_only', false):
					arr.append_array(get_native_props_as_data(new_data, _io_type, _type, native_props))
				else:
					arr.append(new_data)
	
	return arr


func search_api(_search_text: String, _io_type: StringName = '', _type: StringName = '') -> void:
	# offload to thread to verify performance and avoid blocking
	WorkerThreadPool.add_task(_threaded_search_api.bind(_search_text, _io_type, _type))


func _threaded_search_api(_search_text: String, _io_type: StringName, _type: StringName) -> void:
	var start: int = Time.get_ticks_usec()
	if api_data.is_empty():
		print('Erro open compressed api')
		return

	var data: Dictionary = api_data

	if not data:
		print('Not data')
		return

	var text: String = _search_text.strip_edges().to_lower()
	var results: Array = []
	var native_props: Dictionary = data.get(&'native_props')
	var mutex: Mutex = Mutex.new()

	print("Query: '%s'" % text)
	print("Query length: %d" % text.length())
	
	var thread_data: Dictionary = {
		"results": results,
		"text": text,
		"io_type": _io_type,
		"type": _type,
		"native_props": native_props,
		"data": data,
		"mutex": mutex
	}
	
	# task groups: classes, native classes, utilities, processors, map dependencies
	var group_id: int = WorkerThreadPool.add_group_task(_worker_search_task.bind(thread_data), 5, -1, true, "ApiSearch")
	WorkerThreadPool.wait_for_group_task_completion(group_id)

	results.sort_custom(func(a, b): return a.score > b.score)

	call_deferred("_emit_search_results", results)

	var end: int = Time.get_ticks_usec()
	prints((end - start) / 1000., 'ms')


func _emit_search_results(results: Array) -> void:
	var signal_bus: HenSignalBus = Engine.get_singleton(&'SignalBus')
	signal_bus.request_code_search_type_result.emit(results)


func _worker_search_task(idx: int, thread_data: Dictionary) -> void:
	var data: Dictionary = thread_data.data
	var text: String = thread_data.text
	var io_type: StringName = thread_data.io_type
	var type: StringName = thread_data.type
	var native_props: Dictionary = thread_data.native_props
	var mutex: Mutex = thread_data.mutex
	
	var local_results: Array = []

	match idx:
		0:
			for _class_name: StringName in (data.classes as Dictionary).keys():
				var class_data: Dictionary = data.classes[_class_name]
				search_method_data(_class_name, class_data, local_results, text, io_type, type, native_props)
				# search_enum_data(_class_name, class_data, local_results, text, io_type, type, native_props)
				
		1:
			for _class_name: StringName in (data.native_classes as Dictionary).keys():
				var class_data: Dictionary = data.native_classes[_class_name]
				search_method_data(_class_name, class_data, local_results, text, io_type, type, native_props)
				# search_enum_data(_class_name, class_data, local_results, text, io_type, type, native_props)
				
		2:
			for util_name: StringName in (data.utilities as Dictionary).keys():
				var util_lower = util_name.to_lower()
				var score = HenSearch.score_only(text, util_lower)
				var util_data: Dictionary = (data.utilities[util_name] as Dictionary).duplicate()
				
				util_data.erase(&'use_props_only')
				util_data.erase(&'input_io_idx')
				util_data.erase(&'output_io_idx')

				if score > 0:
					util_data._class_name = &''
					util_data.name = util_name
					util_data.score = score
					util_data.is_utility = true
					util_data.data = HenApiSerialize.get_func_void_hengo_data(util_data)

					util_data.data.category = &'native'
					
					if not check_type_validity(util_data, io_type, type, native_props):
						continue
					
					var sub_items: Array = []
					var is_strict_match: bool = not util_data.get(&'use_props_only', false)

					if is_strict_match:
						var data_copy: Dictionary = util_data.duplicate()
						if not io_type:
							data_copy.force_valid = true
						sub_items.append(data_copy)
					
					var props_list: Array = get_native_props_as_data(util_data, io_type, type, native_props)

					for item: Dictionary in props_list:
						item.score = score
						if not io_type:
							item.force_valid = true

					sub_items.append_array(props_list)

					if not sub_items.is_empty():
						var folder_item: Dictionary = util_data.duplicate()
						folder_item.recursive_props = sub_items
						folder_item.is_match = is_strict_match if type else true
						
						local_results.append(folder_item)
						
		3:
			var sidebar_categories: Array = get_side_bar_categories(HenUtils.get_current_ast_list(), false, io_type, type)
			for category: Dictionary in sidebar_categories:
				for item: Dictionary in category.get(&'method_list', []):
					var item_name: String = item.get(&'name', '')
					var score: float = HenSearch.score_only(text, item_name.to_lower())
					
					if score > 0:
						item.score = score
						local_results.append(item)
						
		4:
			var map_deps: HenMapDependencies = Engine.get_singleton(&'MapDependencies')
			if map_deps:
				var deps_list: Dictionary = map_deps.get_code_search_list(io_type, type)
				for category: Dictionary in deps_list.get(&'categories', []):
					for script_data: Dictionary in category.get(&'method_list', []):
						var script_name: String = script_data.get(&'_class_name', '')
						for sub_category: Dictionary in script_data.get(&'categories', []):
							for item: Dictionary in sub_category.get(&'method_list', []):
								var item_name: String = item.get(&'name', '')
								var score: float = HenSearch.score_only(text, item_name.to_lower())
								
								if score > 0:
									var item_copy: Dictionary = item.duplicate()
									item_copy.score = score
									item_copy._class_name = script_name + ' :: ' + item.get(&'_class_name', '')
									local_results.append(item_copy)
									
	if not local_results.is_empty():
		mutex.lock()
		(thread_data.results as Array).append_array(local_results)
		mutex.unlock()


func search_method_data(_class_name: StringName, _class_data: Dictionary, _results: Array, _search_text: String, _io_type: StringName = '', _type: StringName = '', _native_props: Dictionary = {}) -> void:
	if _class_data.has(&"methods"):
		for method_name: StringName in (_class_data.methods as Dictionary).keys():
			var method_lower = method_name.to_lower()
			var score = HenSearch.score_only(_search_text, method_lower)
			var method_data: Dictionary = (_class_data.methods[method_name] as Dictionary).duplicate()

			method_data.erase(&'use_props_only')
			method_data.erase(&'input_io_idx')
			method_data.erase(&'output_io_idx')
			
			if score > 0:
				method_data._class_name = _class_name
				method_data.name = method_name
				method_data.score = score
				method_data.data = HenApiSerialize.get_func_void_hengo_data(method_data)

				if _class_data.get(&'is_native', false):
					method_data.category = &'native'

				if not check_type_validity(method_data, _io_type, _type, _native_props):
					continue
				
				var sub_items: Array = []
				var is_strict_match: bool = not method_data.get(&'use_props_only', false)
				
				if is_strict_match:
					var data_copy: Dictionary = method_data.duplicate()
					if not _io_type:
						data_copy.force_valid = true
					sub_items.append(data_copy)
				
				var props_list: Array = get_native_props_as_data(method_data, _io_type, _type, _native_props)

				for item: Dictionary in props_list:
					item.score = score
					if not _io_type:
						item.force_valid = true

				sub_items.append_array(props_list)

				if not sub_items.is_empty():
					var folder_item: Dictionary = method_data.duplicate()
					folder_item.recursive_props = sub_items
					folder_item.is_match = is_strict_match if _type else true
					
					_results.append(folder_item)


func search_enum_data(_class_name: StringName, _class_data: Dictionary, _results: Array, _search_text: String, _io_type: StringName = '', _type: StringName = '', _native_props: Dictionary = {}) -> void:
	if _class_data.has(&"enums"):
		for enum_name: StringName in (_class_data.enums as Dictionary).keys():
			var enum_lower = enum_name.to_lower()
			var score = HenSearch.score_only(_search_text, enum_lower)
			var enum_data: Dictionary = _class_data.enums[enum_name] as Dictionary

			if score > 0:
				enum_data._class_name = _class_name
				enum_data.name = enum_name
				enum_data.score = score
				_results.append(enum_data)


func check_type_validity(_data: Dictionary, _io_type: StringName = '', _type: StringName = '', _native_props: Dictionary = {}) -> bool:
	var has_type: bool = false

	if _io_type == &'in':
		if HenUtils.is_type_relation_valid(
			_data.get(&'return_type', &'null'),
			_type
		):
			var params: Array = (_data.data as Dictionary).get(&'outputs', [])
			var idx: int = HenAPIProcessors.check_param_validity(params, _type, false)

			if idx != -1:
				_data.output_io_idx = idx
				has_type = true
		elif not _native_props.is_empty():
			var type: StringName = _data.get(&'return_type', &'')

			if _native_props.has(type):
				for prop: Dictionary in _native_props[type]:
					if HenUtils.is_type_relation_valid(prop.type, _type):
						has_type = true
						_data.use_props_only = true
						break
	elif _io_type == &'out':
		var params: Array = (_data.data as Dictionary).get(&'inputs', [])
		var idx: int = HenAPIProcessors.check_param_validity(params, _type, true)

		if idx != -1:
			_data.input_io_idx = idx
			has_type = true
		elif not _native_props.is_empty():
			for param: Dictionary in params:
				var type: StringName = param.get(&'type', &'')
				if _native_props.has(type):
					for prop: Dictionary in _native_props[type]:
						if HenUtils.is_type_relation_valid(_type, prop.type):
							has_type = true
							_data.use_props_only = true
							break
				if has_type: break

	else:
		has_type = true
	
	return has_type


func get_doc_for_ref(_type: StringName, _name: String) -> String:
	var data: Dictionary = get_decompressed_data()
	if data.is_empty():
		return ""

	if data.has(&"classes") and (data.classes as Dictionary).has(_type):
		var class_data: Dictionary = data.classes[_type]
		if class_data.has(&"methods") and (class_data.methods as Dictionary).has(_name):
			return (class_data.methods[_name] as Dictionary).get(&"description", "")
	
	if data.has(&"native_classes") and (data.native_classes as Dictionary).has(_type):
		var class_data: Dictionary = data.native_classes[_type]
		if class_data.has(&"methods") and (class_data.methods as Dictionary).has(_name):
			return (class_data.methods[_name] as Dictionary).get(&"description", "")

	if data.has(&"utilities") and (data.utilities as Dictionary).has(_name):
		return (data.utilities[_name] as Dictionary).get(&"description", "")
		
	return ""


func debounce_search(delay: float, callback: Callable) -> void:
	if timer:
		timer.timeout.disconnect(callback)
		timer = null

	timer = get_tree().create_timer(delay)
	timer.timeout.connect(callback)


# map just the necessary
func _map_api() -> CompressedData:
	var extension_api: FileAccess = await get_api_file()

	if not extension_api:
		print('Error dumping API')
		return
	
	var data: Dictionary = JSON.parse_string(extension_api.get_as_text())
	var new_api_data: Dictionary = {
		classes = map_classes(data),
		utilities = map_utilities(data),
		global_enums = map_global_enums(data),
		singletons = map_singletons(data),
		native_classes = map_native_classes(data),
		native_props = map_native_props(data)
	}

	var compressed_data: CompressedData = save_and_get_compressed_data(new_api_data.duplicate(true), EXTENSION_API_COMPRESSED_PATH)
	
	if FileAccess.file_exists(EXTENSION_API_PATH):
		DirAccess.remove_absolute(EXTENSION_API_PATH)

	return compressed_data


func get_api_file() -> FileAccess:
	print('Generating Godot Native Api...')
	print('Dumping Godot Extension Api...')
	if FileAccess.file_exists(EXTENSION_API_PATH):
		print('Found extension_api.json')
		return FileAccess.open(EXTENSION_API_PATH, FileAccess.READ)

	var pid = OS.create_process(OS.get_executable_path(), ['-q', '--headless', '--dump-extension-api-with-docs', '--path', '.godot/hengo/'])
	
	if pid > 0:
		while OS.is_process_running(pid):
			await Engine.get_main_loop().process_frame
	
	if FileAccess.file_exists(EXTENSION_API_PATH):
		print('Found extension_api.json')
		return FileAccess.open(EXTENSION_API_PATH, FileAccess.READ)
	
	print('Not Found extension_api.json.')
	return null


func map_native_props(_data: Dictionary) -> Dictionary:
	var dict: Dictionary = {}

	if _data.has(&'builtin_class_member_offsets'):
		for conf: Dictionary in _data.get(&'builtin_class_member_offsets'):
			if conf.has(&'classes'):
				for cls: Dictionary in conf.get(&'classes'):
					if not dict.has(cls.name):
						var members: Array = []
						
						for member: Dictionary in cls.get(&'members'):
							members.append({
								name = member.member,
								type = member.meta
							})
						
						dict[cls.name] = members

	return dict


func map_native_classes(_data: Dictionary) -> Dictionary:
	var dict: Dictionary = {}

	if _data.has(&'builtin_classes'):
		for class_data: Dictionary in _data.get(&'builtin_classes'):
			var dt: Dictionary = {}

			if class_data.has(&'members'):
				dt.members = class_data.members
			
			if class_data.has(&'constants'):
				dt.constants = class_data.constants

			if class_data.has(&'description'):
				dt.description = class_data.description
			
			if _data.has(&'enums'):
				var enums: Dictionary = {}
				for enum_data: Dictionary in _data.get(&'enums'):
					var value_data: Dictionary = {}
					
					for enum_value: Dictionary in enum_data.get(&'values'):
						value_data.set(enum_value.name, {
							description = enum_value.description
						})
					
					enums.set(enum_data.name, value_data)

				dt.enums = enums

			# map methods
			if class_data.has(&'methods'):
				dt.methods = map_methods(class_data.get(&'methods'))

			dict.set(class_data.name, dt)

	return dict


func map_methods(_list: Array, _prop_data: Dictionary = {}) -> Dictionary:
	var dt: Dictionary = {}

	for method_data: Dictionary in _list:
		var method_dt: Dictionary = {
			params = []
		}

		if method_data.has(&'description'):
			method_dt.description = method_data.description
		elif not _prop_data.is_empty():
			var dsc: String = ''

			if _prop_data.has(method_data.name):
				var prop: Dictionary = _prop_data.get(method_data.name)

				method_dt.prop_name = prop.get(&'prop_name')

				if prop.has(&'is_getter'):
					method_dt.is_getter = true
				elif prop.has(&'is_setter'):
					method_dt.is_setter = true

			if method_data.has(&'description'):
				dsc = method_data.get(&'description')
			else:
				dsc = _prop_data.get(method_data.name).description \
				if _prop_data.has(method_data.name) and (_prop_data.get(method_data.name) as Dictionary).has(&'description') else ''

			method_dt.description = dsc

		if method_data.has(&'is_static') and method_data.get(&'is_static', false):
			method_dt.is_static = true
		
		if method_data.has(&'is_virtual') and method_data.get(&'is_virtual', false):
			method_dt.is_virtual = true

		if method_data.has(&'arguments'):
			for argument_data: Dictionary in method_data.get(&'arguments'):
				(method_dt.params as Array).append(argument_data)

		if method_data.has(&'return_type'):
			method_dt.return_type = method_data.return_type
		elif method_data.has(&'return_value'):
			if (method_data.return_value as Dictionary).has(&'type'):
				method_dt.return_type = method_data.return_value.type

		dt.set(method_data.name, method_dt)
	
	return dt


func map_singletons(_data: Dictionary) -> Array:
	var arr: Array = []
	if _data.has(&'singletons'):
		for singleton_data: Dictionary in _data.get(&'singletons'):
			arr.append(singleton_data.name)

	return arr


func map_global_enums(_data: Dictionary) -> Dictionary:
	var dict: Dictionary = {}

	if _data.has(&'global_enums'):
		for enum_data: Dictionary in _data.get(&'global_enums'):
			var value_data: Dictionary = {}
			
			for enum_value: Dictionary in enum_data.get(&'values'):
				value_data.set(enum_data.name, {
					name = enum_value.name,
					description = enum_value.description
				})
			
			dict.set(enum_data.name, value_data)

	return dict


func map_utilities(_data: Dictionary) -> Dictionary:
	return map_methods(_data.get(&'utility_functions', []))


func map_classes(_data: Dictionary) -> Dictionary:
	var dict: Dictionary = {}

	# classes: just map docs
	for class_data: Dictionary in _data.get(&'classes', []):
		var dt: Dictionary = {
			description = class_data.description,
		}
		var prop_data: Dictionary = {}

		# map enums
		if class_data.has(&'enums'):
			var enums: Dictionary = {}
			for enum_data: Dictionary in class_data.get(&'enums'):
				for enum_value: Dictionary in enum_data.get(&'values'):
					enums.set(enum_data.name, {
						name = enum_value.name,
						description = enum_value.description if enum_value.has(&'description') else ""
					})

			dt.enums = enums

		# map props just to get description
		if class_data.has(&'properties'):
			for prop_dict: Dictionary in class_data.get(&'properties'):
				if prop_dict.has(&'setter'):
					prop_data.set(prop_dict.setter, {
						prop_name = prop_dict.name,
						is_setter = true,
						description = prop_dict.description if prop_dict.has(&'description') else "",
					})

				if prop_dict.has(&'getter'):
					prop_data.set(prop_dict.getter, {
						prop_name = prop_dict.name,
						is_getter = true,
						description = prop_dict.description if prop_dict.has(&'description') else "",
					})
		
		# map methods
		if class_data.has(&'methods'):
			dt.methods = map_methods(class_data.get(&'methods'), prop_data)

		dict.set(class_data.name, dt)
	
	return dict


func save_and_get_compressed_data(data: Variant, path_out: String) -> CompressedData:
	var raw_bytes = var_to_bytes(data)
	var compressed = raw_bytes.compress(FileAccess.COMPRESSION_ZSTD)
	var size: int = raw_bytes.size()
	var f = FileAccess.open(path_out, FileAccess.WRITE)
	
	if f == null:
		push_error("Erro ao abrir: " + path_out)
		return null
	
	f.store_8(FileAccess.COMPRESSION_ZSTD)
	f.store_32(API_VERSION)
	f.store_pascal_string(Engine.get_version_info().string)
	f.store_32(size)
	f.store_buffer(compressed)
	f.close()

	return CompressedData.new(compressed, size)


func load_compressed_data(path_in: String) -> CompressedData:
	var f = FileAccess.open(path_in, FileAccess.READ)
	if f == null:
		push_error("Não foi possível abrir: " + path_in)
		return null
	
	var file_size = f.get_length()
	f.get_8()
	var version = f.get_32()
	var godot_version = f.get_pascal_string()

	if version != API_VERSION or godot_version != Engine.get_version_info().string:
		return null

	var original_size = f.get_32()
	# 4 bytes (size) + 4 bytes (version) + 1 byte (compression) + pascal string (4 bytes len + utf8 len)
	var header_size: int = 13 + godot_version.to_utf8_buffer().size()
	var compressed_bytes = f.get_buffer(file_size - header_size)
	f.close()

	return CompressedData.new(compressed_bytes, original_size)


func decompress_and_get_data(compressed_data: CompressedData) -> Variant:
	var decompressed: PackedByteArray = compressed_data.bytes.decompress(compressed_data.original_size, FileAccess.COMPRESSION_ZSTD)
	return bytes_to_var(decompressed)


func get_side_bar_list(_io_type: StringName = '', _type: StringName = '') -> Dictionary:
	return {_class_name = 'Hengo', categories = get_side_bar_categories(HenUtils.get_current_ast_list(), false, _io_type, _type)}


func get_side_bar_categories(_ast: HenMapDependencies.ProjectAST, _from_another_script: bool = false, _io_type: StringName = '', _type: StringName = '') -> Array:
	var arr: Array = []
	var save_data_id: StringName = _ast.identity.id
	var native_props: Dictionary = get_decompressed_data().get(&'native_props', {})

	if _ast.identity.id == (Engine.get_singleton('Global') as HenGlobal).SAVE_DATA.identity.id:
		save_data_id = ''


	HenAPIProcessors.process_states(_ast, save_data_id, _io_type, _type, _from_another_script, arr, native_props)
	HenAPIProcessors.process_local_variables(_ast, save_data_id, _io_type, _type, _from_another_script, arr, native_props)
	HenAPIProcessors.process_functions(_ast, save_data_id, _io_type, _type, _from_another_script, arr, native_props)
	HenAPIProcessors.process_variables(_ast, save_data_id, _io_type, _type, _from_another_script, arr, native_props)
	HenAPIProcessors.process_signals(_ast, _io_type, _type, arr)
	HenAPIProcessors.process_macros(_ast, save_data_id, _io_type, _type, _from_another_script, arr, native_props)

	return arr


func get_native_props_as_data(_data: Dictionary, _io_type: StringName = '', _type: StringName = '', _native_props_cache: Dictionary = {}) -> Array:
	var native_props: Dictionary

	if _native_props_cache.is_empty():
		var data: Dictionary = get_decompressed_data()

		if not data:
			print('Not data')
			return []

		native_props = data.get(&'native_props', {})
	else:
		native_props = _native_props_cache

	if native_props.is_empty():
		return []
	
	var arr: Array = []

	var type: StringName = _data.get(&'return_type', '')
	var prop_class_name: StringName = _data.get(&'_class_name')

	if not type:
		var inputs: Array = (_data.get(&'data', {}) as Dictionary).get(&'inputs', [])

		if not inputs.size() < 2:
			type = (inputs.get(1) as Dictionary).get(&'type', '')


	var props: Array = HenAPIProcessors.get_valid_recursive_props(type, _type, _io_type, native_props)
	
	for prop: Dictionary in props:
		if _data.has('is_getter'):
			var prop_name: String = _data.get(&'prop_name', '')
			var middle_name: String = prop_name + '.' if prop_name else ''
			var vc_name: String = '[Get] ' + middle_name + prop.name
			
			var prop_modified: Dictionary = prop.duplicate()
			if prop_name:
				prop_modified.name = prop_name + '.' + prop.name

			var dt: Dictionary = {
				_class_name = 'Getter',
				name = vc_name,
				data = HenAPIProcessors.get_prop_get_data(prop_modified, prop_class_name)
			}
			dt.data.name = vc_name

			if _io_type == 'in':
				dt.output_io_idx = 0
			elif _io_type == 'out':
				dt.input_io_idx = 0
			
			arr.append(dt)
		if _data.has('is_setter'):
			var prop_name: String = _data.get(&'prop_name', '')
			var middle_name: String = prop_name + '.' if prop_name else ''
			var vc_name: String = '[Set] ' + middle_name + prop.name

			var prop_modified: Dictionary = prop.duplicate()
			if prop_name:
				prop_modified.name = prop_name + '.' + prop.name

			var dt: Dictionary = {
				_class_name = 'Setter',
				name = vc_name,
				data = HenAPIProcessors.get_prop_set_data(prop_modified, prop_class_name)
			}
			dt.data.name = vc_name
			
			if _io_type == 'out':
				if _type and HenUtils.is_type_relation_valid(_type, prop.type):
					dt.input_io_idx = 1
				else:
					dt.input_io_idx = 0
			
			arr.append(dt)

	return arr


func get_native_list_raw(_io_type: StringName = '', _type: StringName = '') -> Array:
	var router: HenRouter = Engine.get_singleton(&'Router')
	var list: Array = [
	{
		name = 'Expression',
		icon = 'calculator',
		color = '#8b5cf6',
		is_native = true,
		data = {
			name = 'Expression',
			type = HenVirtualCNode.Type.EXPRESSION,
			sub_type = HenVirtualCNode.SubType.EXPRESSION,
			category = 'native',
			inputs = [
				{
					name = '',
					type = 'Variant',
					sub_type = 'expression',
					is_static = true
				}
			],
			outputs = [
				{
					name = 'result',
					type = 'Variant'
				}
			],
			route = router.current_route
		}
	},
	{
		name = 'Make Transition',
		icon = 'arrow-right-left',
		color = '#06b6d4',
		is_native = true,
		data = {
			name = 'make_transition',
			sub_type = HenVirtualCNode.SubType.MAKE_TRANSITION,
			category = 'native',
			inputs = [
				{
					name = 'name',
					type = 'StringName',
					sub_type = '@dropdown',
					code_value = '',
					category = 'state_transition'
				}
			],
			route = router.current_route
		}
	},
	{
		name = 'print',
		icon = 'terminal',
		color = '#10b981',
		is_native = true,
		data = {
			name = 'print',
			sub_type = HenVirtualCNode.SubType.VOID,
			category = 'native',
			inputs = [
				{
					name = 'content',
					type = 'Variant'
				}
			],
			route = router.current_route
		}
	},
	{
		name = 'Print Text',
		icon = 'text-cursor',
		color = '#10b981',
		is_native = true,
		data = {
			name = 'print',
			sub_type = HenVirtualCNode.SubType.VOID,
			category = 'native',
			inputs = [
				{
					name = 'content',
					type = 'String'
				}
			],
			route = router.current_route
		}
	},
	{
		name = 'IF Condition',
		icon = 'git-branch',
		color = '#f97316',
		is_native = true,
		data = {
			name = 'IF',
			type = HenVirtualCNode.Type.IF,
			sub_type = HenVirtualCNode.SubType.IF,
			route = router.current_route,
			inputs = [
				{
					name = 'condition',
					type = 'bool'
				},
			],
		}
	},
	{
		name = 'For -> Range',
		icon = 'repeat',
		color = '#ec4899',
		is_native = true,
		data = {
			name = 'For -> Range',
			type = HenVirtualCNode.Type.FOR,
			sub_type = HenVirtualCNode.SubType.FOR,
			inputs = [
				{
					name = 'start',
					type = 'int'
				},
				{
					name = 'end',
					type = 'int'
				},
				{
					name = 'step',
					type = 'int',
					value = 1,
                	code_value = '1'
				}
			],
			outputs = [
				{
					name = 'index',
					type = 'int',
				}
			],
			route = router.current_route
		}
	},
	{
		name = 'For -> Item',
		icon = 'list',
		color = '#ec4899',
		is_native = true,
		data = {
			name = 'For -> Item',
			type = HenVirtualCNode.Type.FOR,
			sub_type = HenVirtualCNode.SubType.FOR_ARR,
			inputs = [
				{
					name = 'array',
					type = 'Array'
				},
			],
			outputs = [
				{
					name = 'item',
					type = 'Variant'
				}
			],
			route = router.current_route
		}
	},
	{
		name = 'break',
		icon = 'circle-slash',
		color = '#ef4444',
		is_native = true,
		data = {
			name = 'break',
			sub_type = HenVirtualCNode.SubType.BREAK,
			category = 'native',
			route = router.current_route
		}
	},
	{
		name = 'continue',
		icon = 'fast-forward',
		color = '#eab308',
		is_native = true,
		data = {
			name = 'continue',
			sub_type = HenVirtualCNode.SubType.CONTINUE,
			category = 'native',
			route = router.current_route
		}
	},
	{
		name = 'Raw Code',
		icon = 'code',
		color = '#6366f1',
		is_native = true,
		data = {
			name = 'Raw Code',
			sub_type = HenVirtualCNode.SubType.RAW_CODE,
			category = 'native',
			inputs = [
				{
					name = '',
					category = 'disabled',
					type = 'String'
				},
			],
			outputs = [
				{
					name = 'code',
					type = 'Variant'
				}
			],
			route = router.current_route
		}
	},
	# input event check nodes with dropdowns
	{
		name = 'On Key Pressed',
		icon = 'keyboard',
		color = '#22c55e',
		is_native = true,
		data = {
			name = 'On Key Pressed',
			sub_type = HenVirtualCNode.SubType.INPUT_EVENT_CHECK,
			category = 'native',
			input_code_value_map = {
				event_type = 'InputEventKey',
				check_pressed = true,
				property = 'keycode'
			},
			inputs = [
				{
					name = 'event',
					type = 'InputEvent'
				},
				{
					name = 'key',
					type = 'int',
					sub_type = '@dropdown',
					category = 'key_code'
				}
			],
			outputs = [
				{
					name = 'result',
					type = 'bool'
				}
			],
			route = router.current_route
		}
	},
	{
		name = 'On Key Released',
		icon = 'keyboard',
		color = '#ef4444',
		is_native = true,
		data = {
			name = 'On Key Released',
			sub_type = HenVirtualCNode.SubType.INPUT_EVENT_CHECK,
			category = 'native',
			input_code_value_map = {
				event_type = 'InputEventKey',
				check_pressed = false,
				property = 'keycode'
			},
			inputs = [
				{
					name = 'event',
					type = 'InputEvent'
				},
				{
					name = 'key',
					type = 'int',
					sub_type = '@dropdown',
					category = 'key_code'
				}
			],
			outputs = [
				{
					name = 'result',
					type = 'bool'
				}
			],
			route = router.current_route
		}
	},
	{
		name = 'On Mouse Button Pressed',
		icon = 'mouse-pointer-click',
		color = '#3b82f6',
		is_native = true,
		data = {
			name = 'On Mouse Button Pressed',
			sub_type = HenVirtualCNode.SubType.INPUT_EVENT_CHECK,
			category = 'native',
			input_code_value_map = {
				event_type = 'InputEventMouseButton',
				check_pressed = true,
				property = 'button_index'
			},
			inputs = [
				{
					name = 'event',
					type = 'InputEvent'
				},
				{
					name = 'button',
					type = 'int',
					sub_type = '@dropdown',
					category = 'mouse_button'
				}
			],
			outputs = [
				{
					name = 'result',
					type = 'bool'
				}
			],
			route = router.current_route
		}
	},
	{
		name = 'On Mouse Button Released',
		icon = 'mouse-pointer-click',
		color = '#ef4444',
		is_native = true,
		data = {
			name = 'On Mouse Button Released',
			sub_type = HenVirtualCNode.SubType.INPUT_EVENT_CHECK,
			category = 'native',
			input_code_value_map = {
				event_type = 'InputEventMouseButton',
				check_pressed = false,
				property = 'button_index'
			},
			inputs = [
				{
					name = 'event',
					type = 'InputEvent'
				},
				{
					name = 'button',
					type = 'int',
					sub_type = '@dropdown',
					category = 'mouse_button'
				}
			],
			outputs = [
				{
					name = 'result',
					type = 'bool'
				}
			],
			route = router.current_route
		}
	},
	# action check nodes with dropdown
	{
		name = 'On Action Pressed',
		icon = 'gamepad-2',
		color = '#f97316',
		is_native = true,
		data = {
			name = 'On Action Pressed',
			sub_type = HenVirtualCNode.SubType.INPUT_ACTION_CHECK,
			category = 'native',
			input_code_value_map = {
				method = 'is_action_pressed'
			},
			inputs = [
				{
					name = 'event',
					type = 'InputEvent'
				},
				{
					name = 'action',
					type = 'StringName',
					sub_type = '@dropdown',
					category = 'action'
				}
			],
			outputs = [
				{
					name = 'result',
					type = 'bool'
				}
			],
			route = router.current_route
		}
	},
	{
		name = 'On Action Released',
		icon = 'gamepad-2',
		color = '#f97316',
		is_native = true,
		data = {
			name = 'On Action Released',
			sub_type = HenVirtualCNode.SubType.INPUT_ACTION_CHECK,
			category = 'native',
			input_code_value_map = {
				method = 'is_action_released'
			},
			inputs = [
				{
					name = 'event',
					type = 'InputEvent'
				},
				{
					name = 'action',
					type = 'StringName',
					sub_type = '@dropdown',
					category = 'action'
				}
			],
			outputs = [
				{
					name = 'result',
					type = 'bool'
				}
			],
			route = router.current_route
		}
	},
	# input singleton polling nodes
	{
		name = 'Input Action Pressed',
		icon = 'gamepad-2',
		color = '#06b6d4',
		is_native = true,
		data = {
			name = 'Input Action Pressed',
			sub_type = HenVirtualCNode.SubType.INPUT_POLLING,
			category = 'native',
			input_code_value_map = {
				method = 'is_action_pressed'
			},
			inputs = [
				{
					name = 'action',
					type = 'StringName',
					sub_type = '@dropdown',
					category = 'action'
				}
			],
			outputs = [
				{
					name = 'result',
					type = 'bool'
				}
			],
			route = router.current_route
		}
	},
	{
		name = 'Input Action Just Pressed',
		icon = 'gamepad-2',
		color = '#06b6d4',
		is_native = true,
		data = {
			name = 'Input Action Just Pressed',
			sub_type = HenVirtualCNode.SubType.INPUT_POLLING,
			category = 'native',
			input_code_value_map = {
				method = 'is_action_just_pressed'
			},
			inputs = [
				{
					name = 'action',
					type = 'StringName',
					sub_type = '@dropdown',
					category = 'action'
				}
			],
			outputs = [
				{
					name = 'result',
					type = 'bool'
				}
			],
			route = router.current_route
		}
	},
	{
		name = 'Input Action Just Released',
		icon = 'gamepad-2',
		color = '#06b6d4',
		is_native = true,
		data = {
			name = 'Input Action Just Released',
			sub_type = HenVirtualCNode.SubType.INPUT_POLLING,
			category = 'native',
			input_code_value_map = {
				method = 'is_action_just_released'
			},
			inputs = [
				{
					name = 'action',
					type = 'StringName',
					sub_type = '@dropdown',
					category = 'action'
				}
			],
			outputs = [
				{
					name = 'result',
					type = 'bool'
				}
			],
			route = router.current_route
		}
	},
]
	var arr: Array = []

	for item: Dictionary in list:
		var has_valid_connection: bool = false
		var input_idx: int = -1
		var output_idx: int = -1

		if not _io_type:
			has_valid_connection = true
		elif _io_type == 'in':
			var params: Array = (item.data as Dictionary).get('outputs', [])
			output_idx = HenAPIProcessors.check_param_validity(params, _type, false)
			if output_idx != -1: has_valid_connection = true

		elif _io_type == 'out':
			var params: Array = (item.data as Dictionary).get('inputs', [])
			input_idx = HenAPIProcessors.check_param_validity(params, _type, true)
			if input_idx != -1: has_valid_connection = true

		if has_valid_connection:
			if input_idx != -1: item.input_io_idx = input_idx
			if output_idx != -1: item.output_io_idx = output_idx
			arr.append(item)

	return arr