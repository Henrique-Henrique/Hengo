@tool
class_name HenApi extends Node

const HENGO_CACHE_PATH = 'res://.godot/hengo/'
const EXTENSION_API_PATH = 'res://.godot/hengo/extension_api.json'
const EXTENSION_API_COMPRESSED_PATH = 'res://.godot/hengo/api_compressed.bin'

var compressed_api: CompressedData
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

	compressed_api = await _get_compressed_api()
	

func _get_compressed_api() -> CompressedData:
	if FileAccess.file_exists(EXTENSION_API_COMPRESSED_PATH):
		return load_compressed_data(EXTENSION_API_COMPRESSED_PATH)
	
	return await _map_api()


func get_decompressed_data() -> Dictionary:
	if not compressed_api:
		print('Erro open compressed api')
		return {}

	return decompress_and_get_data(compressed_api)


func map_category_data(_class_name: StringName, _item: Dictionary, _io_type: StringName = '', _type: StringName = '') -> Array:
	if not compressed_api:
		print('Erro open compressed api')
		return []

	var data: Dictionary = decompress_and_get_data(compressed_api)

	if not data:
		print('Not data')
		return []

	var class_data: Dictionary = data.classes[_class_name]
	var method_list_name: Array = _item.get(&'method_list', [])
	var arr: Array = []

	if class_data.has(&"methods"):
		for method_name: StringName in (class_data.methods as Dictionary).keys():
			var method_lower = method_name.to_lower()
			if method_list_name.has(method_lower):
				var new_data: Dictionary = class_data.methods[method_name]
				new_data.name = method_lower
				new_data._class_name = _class_name
				new_data.data = HenApiSerialize.get_func_void_hengo_data(new_data)

				if not check_type_validity(new_data, _io_type, _type):
					continue
				
				arr.append(new_data)
	
	return arr


func search_api(_search_text: String, _io_type: StringName = '', _type: StringName = '') -> void:
	var start: int = Time.get_ticks_usec()
	if not compressed_api:
		print('Erro open compressed api')
		return

	var data: Dictionary = decompress_and_get_data(compressed_api)

	if not data:
		print('Not data')
		return

	var text: String = _search_text.strip_edges().to_lower()
	var results: Array = []

	print("Query: '%s'" % text)
	print("Query length: %d" % text.length())

	# map classes
	for _class_name: StringName in (data.classes as Dictionary).keys():
		var class_data: Dictionary = data.classes[_class_name]

		search_method_data(_class_name, class_data, results, text, _io_type, _type)
		# search_enum_data(_class_name, class_data, results, text, _io_type, _type)
	
	# map native classes
	for _class_name: StringName in (data.native_classes as Dictionary).keys():
		var class_data: Dictionary = data.native_classes[_class_name]

		search_method_data(_class_name, class_data, results, text, _io_type, _type)
		# search_enum_data(_class_name, class_data, results, text, _io_type, _type)

	# Utilities
	for util_name: StringName in (data.utilities as Dictionary).keys():
		var util_lower = util_name.to_lower()
		var score = HenSearch.score_only(text, util_lower)
		var util_data: Dictionary = data.utilities[util_name] as Dictionary

		if score > 0:
			util_data._class_name = &''
			util_data.name = util_name
			util_data.score = score
			util_data.is_utility = true
			util_data.data = HenApiSerialize.get_func_void_hengo_data(util_data)
			
			if not check_type_validity(util_data, _io_type, _type):
				continue
			
			results.append(util_data)
	
	results.sort_custom(func(a, b): return a.score > b.score)

	var signal_bus: HenSignalBus = Engine.get_singleton(&'SignalBus')
	signal_bus.request_code_search_type_result.emit(results)

	var end: int = Time.get_ticks_usec()
	prints((end - start) / 1000., 'ms')


func search_method_data(_class_name: StringName, _class_data: Dictionary, _results: Array, _search_text: String, _io_type: StringName = '', _type: StringName = '') -> void:
	if _class_data.has(&"methods"):
		for method_name: StringName in (_class_data.methods as Dictionary).keys():
			var method_lower = method_name.to_lower()
			var score = HenSearch.score_only(_search_text, method_lower)
			var method_data: Dictionary = _class_data.methods[method_name] as Dictionary
			
			if score > 0:
				method_data._class_name = _class_name
				method_data.name = method_name
				method_data.score = score
				method_data.data = HenApiSerialize.get_func_void_hengo_data(method_data)

				if not check_type_validity(method_data, _io_type, _type):
					continue
				
				_results.append(method_data)


func search_enum_data(_class_name: StringName, _class_data: Dictionary, _results: Array, _search_text: String, _io_type: StringName = '', _type: StringName = '') -> void:
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


func check_type_validity(_data: Dictionary, _io_type: StringName = '', _type: StringName = '') -> bool:
	var has_type: bool = false

	if _io_type == &'in':
		if HenUtils.is_type_relation_valid(
			_data.get(&'return_type', &'null'),
			_type
		):
			var params: Array = (_data.data as Dictionary).get(&'outputs', [])
			var idx: int = 0
			for param: Dictionary in params:
				if HenUtils.is_type_relation_valid(
					_type,
					param.get(&'type', &'')
				):
					_data.output_io_idx = idx
					has_type = true
					break

				idx += 1
	elif _io_type == &'out':
		var params: Array = (_data.data as Dictionary).get(&'inputs', [])
		var idx: int = 0
		for param: Dictionary in params:
			if HenUtils.is_type_relation_valid(
				_type,
				param.get(&'type', &'')
			):
				_data.input_io_idx = idx
				has_type = true
				break

			idx += 1
	else:
		has_type = true
	
	return has_type


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
		native_classes = map_native_classes(data)
	}

	return save_and_get_compressed_data(new_api_data.duplicate(true), EXTENSION_API_COMPRESSED_PATH)


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
						description = prop_dict.description if prop_dict.has(&'description') else "",
					})

				if prop_dict.has(&'getter'):
					prop_data.set(prop_dict.getter, {
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
	var original_size = f.get_32()
	var compressed_bytes = f.get_buffer(file_size - 5)
	f.close()

	return CompressedData.new(compressed_bytes, original_size)


func decompress_and_get_data(compressed_data: CompressedData) -> Variant:
	var decompressed: PackedByteArray = compressed_data.bytes.decompress(compressed_data.original_size, FileAccess.COMPRESSION_ZSTD)
	return bytes_to_var(decompressed)


func get_side_bar_list() -> Dictionary:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var ast: HenMapDependencies.ProjectAST = HenMapDependencies.ProjectAST.new()

	ast.identity = global.SAVE_DATA.identity
	ast.macros = global.SAVE_DATA.macros
	ast.variables = global.SAVE_DATA.variables
	ast.functions = global.SAVE_DATA.functions
	ast.signals = global.SAVE_DATA.signals
	ast.signals_callback = global.SAVE_DATA.signals_callback
	ast.states = global.SAVE_DATA.states

	return {_class_name = 'Hengo', categories = get_side_bar_categories(ast)}


func get_side_bar_categories(_ast: HenMapDependencies.ProjectAST, _from_another_script: bool = false) -> Array:
	var arr: Array = []
	
	# datas
	var state_category: Dictionary = {
		name = 'States',
		icon = 'activity',
		color = '#ff9ff3',
		method_list = []
	}
	var func_category: Dictionary = {
		name = 'Functions',
		icon = 'braces',
		color = '#b05353',
		method_list = []
	}
	var var_category: Dictionary = {
		name = 'Variables',
		icon = 'variable',
		color = '#509fa6',
		method_list = []
	}
	var signal_category: Dictionary = {
		name = 'Signals',
		icon = 'radio-tower',
		color = '#51a650',
		method_list = []
	}
	var macro_category: Dictionary = {
		name = 'Macros',
		icon = 'wand-sparkles',
		color = '#9f50a6',
		method_list = []
	}

	var save_data_id: StringName = _ast.identity.id

	if _ast.identity.id == (Engine.get_singleton('Global') as HenGlobal).SAVE_DATA.identity.id:
		save_data_id = ''

	for state_data: HenSaveState in _ast.states:
		(state_category.method_list as Array).append({
			_class_name = 'State',
			name = state_data.name,
			data = state_data.get_cnode_data(save_data_id, _from_another_script)
		})
	
	for func_data: HenSaveFunc in _ast.functions:
		(func_category.method_list as Array).append({
			_class_name = 'Function',
			name = func_data.name,
			data = func_data.get_cnode_data(save_data_id, _from_another_script)
		})
	
	for var_data: HenSaveVar in _ast.variables:
		var getter_name: String = 'get: ' + var_data.name
		var setter_name: String = 'set: ' + var_data.name

		(var_category.method_list as Array).append({
			_class_name = 'Variable',
			name = getter_name,
			data = var_data.get_getter_cnode_data(_from_another_script)
		})
		(var_category.method_list as Array).append({
			_class_name = 'Variable',
			name = setter_name,
			data = var_data.get_setter_cnode_data(_from_another_script)
		})

	for signal_data: HenSaveSignalCallback in _ast.signals_callback:
		var connect_name: String = 'connect: ' + signal_data.name
		var disconnect_name: String = 'disconnect: ' + signal_data.name

		(signal_category.method_list as Array).append({
			_class_name = 'Signal',
			name = connect_name,
			data = signal_data.get_connect_cnode_data()
		})
		(signal_category.method_list as Array).append({
			_class_name = 'Signal',
			name = disconnect_name,
			data = signal_data.get_diconnect_cnode_data()
		})

	for macro_data: HenSaveMacro in _ast.macros:
		(macro_category.method_list as Array).append({
			_class_name = 'Macro',
			name = macro_data.name,
			data = macro_data.get_cnode_data(save_data_id, _from_another_script)
		})

	arr.append(state_category)
	arr.append(func_category)
	arr.append(var_category)
	arr.append(signal_category)
	arr.append(macro_category)

	return arr


func get_native_list_raw() -> Array:
	var router: HenRouter = Engine.get_singleton(&'Router')

	return [
	# {
	# 	name = 'State',
	# 	icon = 'circle-dot',
	# 	color = '#3b82f6',
	# 	is_native = true,
	# 	data = {
	# 		name = 'State 1',
	# 		type = HenVirtualCNode.Type.STATE,
	# 		sub_type = HenVirtualCNode.SubType.STATE,
	# 		route = router.current_route,
	# 	}
	# },
	{
		name = 'State Event',
		icon = 'activity',
		color = '#f59e0b',
		is_native = true,
		data = {
			name = 'State Event 1',
			type = HenVirtualCNode.Type.STATE_EVENT,
			sub_type = HenVirtualCNode.SubType.STATE_EVENT,
			route = router.current_route,
		}
	},
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
			sub_type = HenVirtualCNode.SubType.FUNC,
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
]