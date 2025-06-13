@tool
class_name HenMethodPicker extends VBoxContainer

enum Type {
	COMMENT
}

var list_container: VBoxContainer
var start_pos: Vector2 = Vector2.ZERO
var connection_type: StringName = 'all'
var show_native_first: bool = true
var came_from: String = ''
var cnode_config: Dictionary = {}
var api_list = []
var current_class_type: CLASS_TYPE = CLASS_TYPE.SELF
var to_type: StringName

const LIST_SIZE: int = 40

enum CLASS_TYPE {
	SELF,
	TO,
	FROM,
	CUSTOM
}
enum FILTER_TYPE {
	SELF,
	ALL,
	NATIVE,
	FUNC,
	SIGNAL,
	MACRO,
	FUNC_FROM,
	VAR_FROM
}

var class_type: CLASS_TYPE = CLASS_TYPE.SELF
var select_type: FILTER_TYPE = FILTER_TYPE.SELF
var selected_class: StringName
var name_to_search: String = ''

var first_time: bool = true

@onready var tree: Tree = %List


const BG_COLOR = {
	FILTER_TYPE.SELF: Color('#212121'),
	FILTER_TYPE.FUNC: Color('#432F2F'),
	FILTER_TYPE.SIGNAL: Color('#2F4335'),
	FILTER_TYPE.MACRO: Color('#332F43'),
	FILTER_TYPE.NATIVE: Color.BLACK,
	FILTER_TYPE.FUNC_FROM: Color.BLUE
}

const FILTER_ICONS = {
	FILTER_TYPE.SELF: preload('res://addons/hengo/assets/icons/menu/void.svg'),
	FILTER_TYPE.FUNC: preload('res://addons/hengo/assets/icons/menu/void.svg'),
	FILTER_TYPE.SIGNAL: preload('res://addons/hengo/assets/icons/menu/wifi.svg'),
	FILTER_TYPE.MACRO: preload('res://addons/hengo/assets/icons/menu/text.svg'),
	FILTER_TYPE.NATIVE: preload('res://addons/hengo/assets/icons/menu/text.svg'),
}


var native_list: Array = [
	{
		name = 'State',
		data = {
			name = 'State 1',
			type = HenVirtualCNode.Type.STATE,
			sub_type = HenVirtualCNode.SubType.STATE,
			route = HenRouter.current_route,
		}
	},
	{
		name = 'State Event',
		data = {
			name = 'State Event 1',
			type = HenVirtualCNode.Type.STATE_EVENT,
			sub_type = HenVirtualCNode.SubType.STATE_EVENT,
			route = HenRouter.current_route,
		}
	},
	{
		name = 'Get',
		data = {
			name = 'Get',
			sub_type = HenVirtualCNode.SubType.GET_PROP,
			outputs = [
				{
					name = '',
					type = 'Variant',
					sub_type = '@dropdown',
					category = 'get_prop',
				}
			],
			route = HenRouter.current_route
		}

	},
	{
		name = 'Set',
		data = {
			name = 'Set',
			sub_type = HenVirtualCNode.SubType.SET_PROP,
			inputs = [
				{
					name = '',
					type = 'Variant',
					sub_type = '@dropdown',
					category = 'set_prop',
					code_value = '__a',
					is_static = true
				},
				{
					name = 'value',
					type = 'Variant',
				},
			],
			route = HenRouter.current_route
		}
	},
	{
		name = 'Expression',
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
			route = HenRouter.current_route
		}
	},
	{
		name = 'Make Transition',
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
			route = HenRouter.current_route
		}
	},
	{
		name = 'debug value',
		data = {
			name = '',
			fantasy_name = 'Debug Value',
			sub_type = HenVirtualCNode.SubType.DEBUG_VALUE,
			category = 'native',
			inputs = [
				{
					name = 'content',
					type = 'Variant'
				}
			],
			route = HenRouter.current_route
		}
	},
	{
		name = 'print',
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
			route = HenRouter.current_route
		}
	},
	{
		name = 'Print Text',
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
			route = HenRouter.current_route
		}
	},
	{
		name = 'IF Condition',
		data = {
			name = 'IF',
			type = HenVirtualCNode.Type.IF,
			sub_type = HenVirtualCNode.SubType.IF,
			route = HenRouter.current_route,
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
			route = HenRouter.current_route
		}
	},
	{
		name = 'For -> Item',
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
			route = HenRouter.current_route
		}
	},
	{
		name = 'break',
		data = {
			name = 'break',
			sub_type = HenVirtualCNode.SubType.BREAK,
			category = 'native',
			route = HenRouter.current_route
		}
	},
	{
		name = 'continue',
		data = {
			name = 'continue',
			sub_type = HenVirtualCNode.SubType.CONTINUE,
			category = 'native',
			route = HenRouter.current_route
		}
	},
	{
		name = 'Raw Code',
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
			route = HenRouter.current_route
		}
	},
]


func _ready() -> void:
	set_process(false)

	if not HenGlobal.script_config:
		return

	var _type: StringName = HenGlobal.script_config.type

	tree.item_activated.connect(_on_select)
	(%Search as LineEdit).text_changed.connect(_on_search)
	(%Search as LineEdit).grab_focus()

	# filter buttons
	for chd: Button in (%FilterList as HBoxContainer).get_children():
		chd.pressed.connect(_filter_change.bind(chd.name))


func _filter_change(_name: StringName) -> void:
	match _name:
		&'Self':
			select_type = FILTER_TYPE.SELF
		&'All':
			select_type = FILTER_TYPE.ALL
		&'Native':
			select_type = FILTER_TYPE.NATIVE
		&'Func':
			select_type = FILTER_TYPE.FUNC
		&'Signal':
			select_type = FILTER_TYPE.SIGNAL
		&'Macro':
			select_type = FILTER_TYPE.MACRO
	
	_build_api_list(selected_class)


func _on_search(_text: String) -> void:
	name_to_search = _text
	build_list()


func _process(_delta: float) -> void:
	%LoadingBt.rotation += 5 * _delta


func _build_api_list(_class: StringName) -> void:
	selected_class = _class

	%LoadingBt.visible = true
	set_process(true)
	await HenGlobal.CAM.get_tree().process_frame
	%LoadingBt.pivot_offset = %LoadingBt.size / 2
	var thread: Thread = Thread.new()

	set_process(true)
	thread.start(mount_list.bind(_class, thread))


func hide_loading_bt() -> void:
	%LoadingBt.visible = false
	set_process(false)


func mount_list(_class: StringName, _thread: Thread) -> void:
	var local_api: Array = []

	match current_class_type:
		CLASS_TYPE.SELF:
			match select_type:
				FILTER_TYPE.SELF:
					for dict in ClassDB.class_get_method_list(selected_class):
						local_api.append(_get_class_obj(dict, selected_class))
				FILTER_TYPE.ALL:
					local_api.append_array(get_native_list())
					local_api.append_array(get_function_list())
					local_api.append_array(get_hengo_signal_list())
					local_api.append_array(get_macro_list())
					local_api.append_array(get_others_classes_list())
					local_api.append_array(get_from_list())
					local_api.append_array(get_global_const_list())
					local_api.append_array(get_native_singleton_list())
				FILTER_TYPE.NATIVE:
					local_api.append_array(get_native_list())
				FILTER_TYPE.FUNC:
					local_api.append_array(get_function_list())
				FILTER_TYPE.SIGNAL:
					local_api.append_array(get_hengo_signal_list())
				FILTER_TYPE.MACRO:
					local_api.append_array(get_macro_list())
		CLASS_TYPE.TO:
			for dict in ClassDB.class_get_method_list(to_type):
				local_api.append(_get_class_obj(dict, to_type))

			if HenEnums.NATIVE_API_LIST.has(to_type):
				for dict: Dictionary in HenEnums.NATIVE_API_LIST.get(to_type):
					var dt: Dictionary = dict.duplicate()
					dt.name = '({0}) -> {1}'.format([to_type, dict.name])
					dt.icon_type = &'void'
					dt.data.route = HenRouter.current_route
					local_api.append(dt)
			
			if HenEnums.NATIVE_PROPS_LIST.has(to_type):
				for dict: Dictionary in HenEnums.NATIVE_PROPS_LIST.get(to_type):
					var dt: Dictionary = dict.duplicate()
					var name: String = 'Get {0} property'.format([dt.name])

					local_api.append({
						name = name,
						icon_type = 'void',
						data = {
							name = name,
							sub_type = HenVirtualCNode.SubType.GET_PROP,
							inputs = [ {name = to_type, type = to_type, is_ref = true}],
							outputs = [dt.merged({code_value = dt.name, })],
							route = HenRouter.current_route
						}
					})

		CLASS_TYPE.FROM:
			var idx: int = 0

			match select_type:
				FILTER_TYPE.SELF:
					print(selected_class)
					for class_method in ClassDB.class_get_method_list(selected_class):
						var dt: Dictionary = _get_class_obj(class_method, selected_class)
						
						if dt.data.has(&'outputs'):
							idx = 0
							for output: Dictionary in dt.data.outputs:
								if HenUtils.is_type_relation_valid(output.type, to_type):
									dt.data.idx_to_connect = idx
									local_api.append(dt)

								idx += 1
				FILTER_TYPE.ALL:
					# methods
					for class_n in ClassDB.get_class_list():
						for class_method in ClassDB.class_get_method_list(class_n, true):
							var dt: Dictionary = _get_class_obj(class_method, class_n, true)
							
							if dt.data.has(&'outputs'):
								idx = 0
								for output: Dictionary in dt.data.outputs:
									if HenUtils.is_type_relation_valid(output.type, to_type):
										dt.data.idx_to_connect = idx
										local_api.append(dt)

									idx += 1
				

			if HenEnums.NATIVE_API_LIST.has(selected_class):
				for dict: Dictionary in HenEnums.NATIVE_API_LIST.get(selected_class):
					if dict.data.has(&'outputs'):
						idx = 0
						for output: Dictionary in dict.data.outputs:
							if HenUtils.is_type_relation_valid(output.type, to_type):
								var dt: Dictionary = dict.duplicate()
								dt.name = '({0}) -> {1}'.format([selected_class, dict.name])
								dt.icon_type = &'void'
								dt.data.route = HenRouter.current_route
								dt.data.idx_to_connect = idx
								local_api.append(dt)
							
							idx += 1


	if self != null:
		api_list = local_api
		build_list.call_deferred()
		hide_loading_bt.call_deferred()
	
	_thread.wait_to_finish.call_deferred()


func build_list() -> void:
	tree.clear()

	var root: TreeItem = tree.create_item()
	var tree_items: Array[Dictionary] = []
	const item_size_limit: int = 1000

	match current_class_type:
		CLASS_TYPE.SELF:
			%Native.visible = true
		CLASS_TYPE.TO:
			%Native.visible = false
		CLASS_TYPE.FROM:
			%Native.visible = false


	for data: Dictionary in api_list:
		if tree_items.size() >= item_size_limit:
			continue

		if not name_to_search or search_name(data.name, name_to_search):
			var dt: Dictionary = {
				name = data.name,
				data = data.data
			}
		
			if data.has('type'):
				if FILTER_ICONS.has(data.type):
					dt.icon = FILTER_ICONS[data.type]
					dt.bg_color = BG_COLOR[data.type]
			elif data.has('icon_type'):
				if data.icon_type == 'void':
					dt.icon = FILTER_ICONS[FILTER_TYPE.FUNC]
					dt.bg_color = Color(1, 1, 1, .03)
				else:
					dt.icon = HenAssets.get_icon_texture(data.icon_type)

			tree_items.append(dt)

	for item_data: Dictionary in tree_items:
		var item: TreeItem = root.create_child()

		item.set_text(0, item_data.name)
		item.set_metadata(0, item_data.data)
		item.set_icon(0, item_data.icon)
		
		if item_data.has('bg_color'): item.set_custom_bg_color(0, item_data.bg_color)

	if root.get_child_count() > 0:
		var item_size: Vector2 = tree.get_item_area_rect(root.get_child(0)).size
		tree.custom_minimum_size.y = item_size.y * tree_items.size()

		var rect: Rect2 = HenGlobal.CAM.get_viewport_rect()
		if tree.custom_minimum_size.y > rect.size.y:
			tree.custom_minimum_size.y = rect.size.y * .4
	else:
		tree.custom_minimum_size.y = 0
		
	HenGlobal.GENERAL_POPUP.get_parent().reset_size()


func get_from_list() -> Array:
	var local_api: Array = []

	for script_path: String in DirAccess.get_files_at('res://hengo/save'):
		var id: int = int(script_path.get_basename())

		if id == 0:
			continue

		var path: StringName = HenLoader.get_data_path(id)
		var res: HenScriptData = ResourceLoader.load(path)
		var res_name: String = ResourceUID.get_id_path(id).get_file().get_basename()

		for var_data: Dictionary in res.side_bar_list.var_list:
			var dt: Dictionary = {
				name = '({0}) {1}'.format([res_name, var_data.name]),
				type = FILTER_TYPE.VAR_FROM,
				data = {
					name = 'Get From -> ' + res_name,
					name_to_code = var_data.name,
					from_side_bar_id = var_data.id,
					sub_type = HenVirtualCNode.SubType.GET_FROM_PROP,
					from_id = id,
					inputs = [
						{
							name = 'from',
							type = res.type,
							is_ref = true,
						}
					],
					outputs = [
						{
							name = var_data.name,
							type = var_data.type
						}
					],
					route = HenRouter.current_route,
				}
			}

			local_api.append(dt)

		for func_data: Dictionary in res.side_bar_list.func_list:
			var dt: Dictionary = {
				name = '({0}) {1}'.format([res_name, func_data.name]),
				type = FILTER_TYPE.FUNC_FROM,
				data = {
					name = func_data.name,
					from_side_bar_id = func_data.id,
					from_id = id,
					sub_type = HenVirtualCNode.SubType.FUNC_FROM,
					name_to_code = func_data.name,
					inputs = [
						{
							name = 'from',
							type = res.type,
							is_ref = true,
						}
					] + func_data.inputs.map(func(x): return {name = x.name, type = x.type, from_id = x.id}),
					outputs = func_data.outputs.map(func(x): return {name = x.name, type = x.type, from_id = x.id}),
					route = HenRouter.current_route,
				}
			}

			local_api.append(dt)
		
	return local_api


func get_native_singleton_list() -> Array:
	var local_api: Array = []

	for data: Dictionary in HenEnums.SINGLETON_API_LIST:
		data.type = FILTER_TYPE.NATIVE
		data.data.route = HenRouter.current_route
		local_api.append(data)

	return local_api


func get_global_const_list() -> Array:
	var local_api: Array = []

	for key: StringName in HenEnums.CONST_API_LIST.keys():
		var items: Array = HenEnums.CONST_API_LIST[key]

		for data: Dictionary in items:
			var custom_name: String = '({0}) {1}'.format([key, data.name])
			
			var dt: Dictionary = {
				name = custom_name,
				type = FILTER_TYPE.NATIVE,
				data = {
					name = key,
					name_to_code = data.name,
					sub_type = HenVirtualCNode.SubType.CONST,
					outputs = [
						{
							name = data.name,
							type = data.type
						}
					],
					route = HenRouter.current_route,
				}
			}

			local_api.append(dt)

	return local_api


func get_native_list() -> Array:
	var local_api: Array = []
	for data: Dictionary in native_list:
		data.type = FILTER_TYPE.NATIVE
		local_api.append(data)
	
	return local_api


func get_function_list() -> Array:
	var local_api: Array = []
	for func_data: HenSideBar.FuncData in HenGlobal.SIDE_BAR_LIST.func_list:
		var dt: Dictionary = {
			name = func_data.name,
			type = FILTER_TYPE.FUNC,
			data = func_data.get_cnode_data()
		}

		local_api.append(dt)
	
	return local_api


func get_others_classes_list() -> Array:
	var local_api: Array = []

	for class_n in ClassDB.get_class_list():
		for class_method in ClassDB.class_get_method_list(class_n, true):
			local_api.append(_get_class_obj(class_method, class_n, true))

	return local_api


func get_hengo_signal_list() -> Array:
	var local_api: Array = []

	for signal_data: HenSideBar.SignalData in HenGlobal.SIDE_BAR_LIST.signal_list:
		var connect_dt: Dictionary = {
			name = signal_data.name,
			type = FILTER_TYPE.SIGNAL,
			data = signal_data.get_connect_cnode_data()
		}

		var disconnect_dt: Dictionary = {
			name = signal_data.name,
			type = FILTER_TYPE.SIGNAL,
			data = signal_data.get_diconnect_cnode_data()
		}

		local_api.append(connect_dt)
		local_api.append(disconnect_dt)

	return local_api


func get_macro_list() -> Array:
	var local_api: Array = []

	for macro_data: HenSideBar.MacroData in HenGlobal.SIDE_BAR_LIST.macro_list:
		var dt: Dictionary = {
			name = macro_data.name,
			type = FILTER_TYPE.MACRO,
			data = macro_data.get_cnode_data()
		}

		local_api.append(dt)

	return local_api


func search_name(_name: String, _name_to_search: String) -> bool:
	# var reg: RegEx = RegEx.new()
	# reg.compile('[()\\->.\\s]')
	# var clean_name: String = reg.sub(_name.to_lower(), "", true)
	# var clean_name_to_search: String = reg.sub(_name_to_search.to_lower(), "", true)
	# return clean_name.containsn(clean_name_to_search)
	var clean_name: String = _name.to_lower().replace('_', '')
	var clean_name_to_search: String = _name_to_search.to_lower().replace('_', '')
	
	return clean_name.containsn(clean_name_to_search)


func _on_select() -> void:
	var data: Dictionary = tree.get_selected().get_metadata(0)

	print(data)

	data.position = HenGlobal.CAM.get_relative_vec2(start_pos)

	var vc_return: HenVirtualCNode.VCNodeReturn = HenVirtualCNode.instantiate(data)

	HenGlobal.history.create_action('Add CNode')
	HenGlobal.history.add_do_method(vc_return.add)
	HenGlobal.history.add_do_reference(vc_return)
	HenGlobal.history.add_undo_method(vc_return.remove)

	# make connection
	if cnode_config.has('from_virtual_ref'):
		vc_return.v_cnode.create_connection(
			vc_return.v_cnode.inputs[0].id,
			cnode_config.in_out_id,
			cnode_config.from,
		).add()
	elif cnode_config.has('to_virtual_ref'):
		cnode_config.from.create_connection(
			cnode_config.to_virtual_ref.id,
			vc_return.v_cnode.outputs[data.idx_to_connect].id,
			vc_return.v_cnode,
		).add()

	# add connection when dragging from connector
	if cnode_config.has('from_flow_connector'):
		var connector: HenFlowConnector = cnode_config.from_flow_connector

		connector.root.virtual_ref.add_flow_connection(cnode_config.from_flow_connector.id, vc_return.v_cnode.from_flow_connections[0].id, vc_return.v_cnode).add()

	HenGlobal.history.commit_action()
	HenGlobal.GENERAL_POPUP.get_parent().hide_popup()


func _get_sub_type(_type: Variant.Type, _usage: int) -> HenVirtualCNode.SubType:
	match _type:
		TYPE_NIL:
			if _usage == 131078: # is the code for nil returning variant, so... a func
				return HenVirtualCNode.SubType.FUNC
			else:
				return HenVirtualCNode.SubType.VOID
		_:
			return HenVirtualCNode.SubType.FUNC


func _get_typeny_arg(_arg: Dictionary) -> StringName:
	match _arg.type:
		TYPE_OBJECT:
			return _arg.class_name
		TYPE_NIL:
			if _arg.usage == 131078:
				return 'Variant'

	return type_string(_arg.type)


func _get_class_obj(_dict: Dictionary, _class_name: StringName, _use_class_name: bool = false) -> Dictionary:
	var _obj_type: StringName = _get_typeny_arg(_dict.return )

	var obj: Dictionary = {
		name = _dict.name if not _use_class_name else '({0}) -> {1}'.format([_class_name, _dict.name]),
		icon_type = _obj_type if _obj_type != StringName('Nil') else StringName('void'),
		data = {
			name = _dict.name,
			sub_type = _get_sub_type(_dict.return.type, _dict.return.usage) if _dict.flags != METHOD_FLAG_VIRTUAL else HenVirtualCNode.SubType.OVERRIDE_VIRTUAL,
			route = HenRouter.current_route
		},
	}

	if _dict.flags == METHOD_FLAG_VIRTUAL:
		obj.data.outputs = (_dict.args as Array).map(
			func(arg) -> Dictionary:
				match arg.usage:
					65542:
						return {
							name = arg.name,
							type = 'int',
							sub_type = '@dropdown',
							category = 'enum_list',
							data = arg.class_name.split('.'),
						}
					_:
						return {
						name = arg.name,
						type = _get_typeny_arg(arg)
					}
				)
	else:
		obj.data.inputs = []
		
		if Engine.has_singleton(_class_name):
			obj.data.singleton_class = _class_name
		else:
			obj.data.inputs.append({
				name = _class_name,
				type = _class_name,
				is_ref = true
			})

		obj.data.inputs += (_dict.args as Array).map(
			func(arg) -> Dictionary:
				match arg.usage:
					65542:
						return {
							name = arg.name,
							type = 'int',
							sub_type = '@dropdown',
							category = 'enum_list',
							data = arg.class_name.split('.'),
						}
					_:
						return {
						name = arg.name,
						type = _get_typeny_arg(arg)
					}
				)
			

	# it's a void or return a variant
	if _dict.return.type != TYPE_NIL or (_dict.return.type == TYPE_NIL and _dict.return.usage == 131078):
		obj['data']['outputs'] = [ {
			name = _dict.return.name,
			type = _get_typeny_arg(_dict.return )
		}]

	return obj


func start(_type: StringName, _pos: Vector2, _show_native: bool = true, _came_from: String = 'out', _cnode_config: Dictionary = {}) -> void:
	connection_type = _type
	start_pos = _pos
	show_native_first = _show_native
	came_from = _came_from
	cnode_config = _cnode_config

	if not _cnode_config.is_empty():
		if _cnode_config.has('to_virtual_ref'):
			current_class_type = CLASS_TYPE.FROM
			to_type = _cnode_config.to_virtual_ref.type
		elif _cnode_config.has('from_virtual_ref'):
			current_class_type = CLASS_TYPE.TO
			to_type = _cnode_config.from_virtual_ref.type
		elif _cnode_config.has('from_flow_connector'):
			current_class_type = CLASS_TYPE.SELF
	else:
		current_class_type = CLASS_TYPE.SELF

	_build_api_list(HenGlobal.script_config.type)