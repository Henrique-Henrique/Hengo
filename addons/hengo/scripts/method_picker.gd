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

var selected_id: int = 0:
	set(new_value):
		var item = list_container.get_child(new_value)
		var old_item = list_container.get_child(selected_id) if list_container.get_child_count() > selected_id else null

		if old_item:
			_item_exit(old_item)

		if item:
			_item_hover(item)

		selected_id = new_value

var native_list: Array = [
	{
		name = 'Expression',
		data = {
			name = 'Expression',
			sub_type = HenCnode.SUB_TYPE.EXPRESSION,
			type = HenCnode.TYPE.EXPRESSION,
			category = 'native',
			inputs = [],
			outputs = [ {
				name = 'result',
				type = 'Variant'
			}],
			route = HenRouter.current_route
		}
	},
	{
		name = 'Make Transition',
		data = {
			name = 'make_transition',
			sub_type = HenCnode.SUB_TYPE.FUNC,
			category = 'native',
			inputs = [
				{
					name = 'name',
					sub_type = '@dropdown',
					category = 'state_transition'
				}
			],
			route = HenRouter.current_route
		}
	},
	{
		name = 'Cast To ->',
		data = {
			name = 'Cast To',
			sub_type = HenCnode.SUB_TYPE.CAST,
			category = 'native',
			inputs = [
				{
					name = 'from',
					type = 'Variant'
				}
			],
			outputs = [
				{
					name = 'to',
					type = 'Node',
					sub_type = '@dropdown',
					category = 'cast_type'
				}
			],
			route = HenRouter.current_route
		}
	},
	{
		name = 'Comment',
		data_type = Type.COMMENT,
	},
	{
		name = 'debug value',
		data = {
			name = '',
			fantasy_name = 'Debug Value',
			sub_type = HenCnode.SUB_TYPE.DEBUG_VALUE,
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
			sub_type = HenCnode.SUB_TYPE.VOID,
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
			sub_type = HenCnode.SUB_TYPE.VOID,
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
			type = HenCnode.TYPE.IF,
			sub_type = HenCnode.SUB_TYPE.IF,
			route = HenRouter.current_route,
			inputs = [
				{
					name = 'condition',
					type = 'bool'
				},
			]
		}
	},
	{
		name = 'For -> Range',
		data = {
			name = 'For -> Range',
			sub_type = HenCnode.SUB_TYPE.FOR,
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
					type = 'int'
				}
			],
			outputs = [
				{
					name = 'index',
					type = 'int'
				}
			],
			route = HenRouter.current_route
		}
	},
	{
		name = 'For -> Item',
		data = {
			name = 'For -> Item',
			sub_type = HenCnode.SUB_TYPE.FOR_ARR,
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
			sub_type = HenCnode.SUB_TYPE.BREAK,
			category = 'native',
			route = HenRouter.current_route
		}
	},
	{
		name = 'continue',
		data = {
			name = 'continue',
			sub_type = HenCnode.SUB_TYPE.CONTINUE,
			category = 'native',
			route = HenRouter.current_route
		}
	},
	{
		name = 'Raw Code',
		data = {
			name = 'Raw Code',
			sub_type = HenCnode.SUB_TYPE.RAW_CODE,
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
	}
]


func _ready() -> void:
	list_container = get_node('%List')

	var error: int = start_api(connection_type)

	# disabling coming from inputs (for now)
	if error != OK or came_from == 'in':
		await get_tree().process_frame
		HenGlobal.CNODE_CAM.can_scroll = true
		HenGlobal.GENERAL_POPUP.get_parent().hide()


	match HenRouter.current_route.type:
		HenRouter.ROUTE_TYPE.SIGNAL, HenRouter.ROUTE_TYPE.FUNC:
			native_list.append(
				{
					name = 'Go to Event',
					data = {
						name = 'go_to_event',
						sub_type = HenCnode.SUB_TYPE.SELF_GO_TO_VOID,
						inputs = [
							{
								name = 'state',
								sub_type = '@dropdown',
								category = 'current_states'
							}
						],
						route = HenRouter.current_route
					}
				},
			)

	_show_list(native_list if show_native_first else api_list.slice(0, 20), false)

	var search_bar = (get_node('%Search') as LineEdit)

	search_bar.text_changed.connect(_search)
	search_bar.gui_input.connect(_on_search_gui_input)
	search_bar.grab_focus()


func _on_search_gui_input(_event: InputEvent) -> void:
	if _event is InputEventKey:
		if _event.pressed:
			if _event.keycode == KEY_DOWN:
				selected_id = wrapi(selected_id + 1, 0, list_container.get_child_count())
			elif _event.keycode == KEY_UP:
				selected_id = wrapi(selected_id - 1, 0, list_container.get_child_count())
			elif _event.keycode == KEY_ENTER:
				_select()


func _select() -> void:
	HenGlobal.CNODE_CAM.can_scroll = true
	if list_container.get_child_count() > 0:
		var item = list_container.get_child(selected_id)
		var item_data = item.get_meta('data')

		if item_data.has('data_type'):
			match item_data.data_type as Type:
				Type.COMMENT:
					var comment = preload('res://addons/hengo/scenes/utils/comment.tscn').instantiate()
					comment.route_ref = HenRouter.current_route
					comment.position = HenGlobal.CNODE_CAM.get_relative_vec2(start_pos)
					HenRouter.comment_reference[HenRouter.current_route.id].append(comment)
					HenGlobal.COMMENT_CONTAINER.add_child(comment)
					HenGlobal.GENERAL_POPUP.get_parent().hide()
					return
				
		var data = item_data['data']

		# intercepting method creation
		# method picker middleware
		# TODO: make this apresentable

		if data.has('inputs'):
			for input in data.inputs:
				if input.has('type'):
					if input.type == 'Callable':
						input.sub_type = '@dropdown'
						input.category = 'callable'

		if data.name.contains('is_action'):
			for input in data.inputs:
				if input.name == 'action':
					input.sub_type = '@dropdown'
					input.category = 'action'

		elif data.name == 'connect' or data.name == 'disconnect':
			for input in data.inputs:
				if input.name == 'signal':
					input.sub_type = '@dropdown'
					input.category = 'signal'
					input.data = data.inputs[0].type


		data['position'] = HenGlobal.CNODE_CAM.get_relative_vec2(start_pos)

		print(data)

		var v_cnode: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode_and_add(data)
		# var cnode: HenCnode = HenCnode.instantiate_and_add(data)

		# # make connection
		if cnode_config.has('from_in_out'):
			var input = v_cnode.cnode_ref.get_node('%InputContainer').get_child(0)

			input.create_virtual_connection({
				from = cnode_config.from_in_out,
				type = came_from,
				conn_type = connection_type,
				reparent_data = HenGlobal.reparent_data
			})

			# v_cnode.input_connections.append({
			# 	idx = 0,
			# 	to = out_virtual_ref,
			# 	to_idx = cnode_config.in_out_idx,
			# 	line_ref = line
			# })

			# 	input.create_connection_and_instance({
			# 		from = output,
			# 		type = came_from,
			# 		conn_type = connection_type,
			# 		reparent_data = HenGlobal.reparent_data
			# 	})
		
		
		# if cnode_config.has('from_flow_connector'):
		# 	var from_flow_connector = cnode_config.get('from_flow_connector')

		# 	from_flow_connector.create_connection_line_and_instance({
		# 		from_cnode = cnode,
		# 	})

		HenGlobal.GENERAL_POPUP.get_parent().hide()


func _show_list(_list: Array, _slice: bool = true) -> void:
	# cleaning list first
	for item in list_container.get_children():
		item.queue_free()

	for dict: Dictionary in _list.slice(0, 20) if _slice else _list:
		var item = preload('res://addons/hengo/scenes/method_picker_item.tscn').instantiate()
		item.set_meta('data', dict)
		item.mouse_entered.connect(_on_item_hover.bind(item))
		item.mouse_exited.connect(_on_item_exit.bind(item))
		item.gui_input.connect(_on_item_gui_input)
		item.get_node('%Name').text = dict.name
		item.get_node('%Type').text = dict.type if dict.has('type') else ''

		list_container.add_child(item)
	
	await RenderingServer.frame_post_draw
	HenGlobal.GENERAL_POPUP.size = Vector2.ZERO

	if list_container.get_child_count() > 0:
		_item_hover(list_container.get_child(0))


func _on_item_gui_input(_event: InputEvent) -> void:
	if _event is InputEventMouseButton:
		if _event.pressed:
			if _event.button_index == MOUSE_BUTTON_LEFT:
				_select()


func _on_item_hover(_item) -> void:
	_item_hover(_item)
	selected_id = _item.get_index()


func _on_item_exit(_item) -> void:
	_item_exit(_item)
	selected_id = _item.get_index()


func _item_hover(_item) -> void:
	_item.get('theme_override_styles/panel').set('bg_color', Color.DARK_CYAN)


func _item_exit(_item) -> void:
	_item.get('theme_override_styles/panel').set('bg_color', Color(0, 0, 0, .3))


func _search(_text: String) -> void:
	if _text.is_empty():
		_show_list(native_list, false)
		return

	var arr: Array = []

	for dict: Dictionary in api_list:
		if (dict.name as String).replacen(' -> ', '').to_snake_case().replacen('_', '').contains(_text.to_snake_case().replacen('_', '')):
			arr.append(dict)

	_show_list(arr)

# ---------------------------------------------------------------------------------------------------------------
# ---------------------------------------------------------------------------------------------------------------
# ---------------------------------------------------------------------------------------------------------------
# ---------------------------------------------------------------------------------------------------------------
# ---------------------------------------------------------------------------------------------------------------
# ---------------------------------------------------------------------------------------------------------------
# ---------------------------------------------------------------------------------------------------------------
# GENERATING API
func _get_sub_type(_type: Variant.Type, _usage: int) -> HenCnode.SUB_TYPE:
	match _type:
		TYPE_NIL:
			if _usage == 131078: # is the code for nil returning variant, so... a func
				return HenCnode.SUB_TYPE.FUNC
			else:
				return HenCnode.SUB_TYPE.VOID
		_:
			return HenCnode.SUB_TYPE.FUNC


func _get_typeny_arg(_arg: Dictionary) -> StringName:
	match _arg.type:
		TYPE_OBJECT:
			return _arg.class_name
		TYPE_NIL:
			if _arg.usage == 131078:
				return 'Variant'

	return type_string(_arg.type)


func _get_class_obj(_dict: Dictionary, _class_name: StringName, _type: String) -> Dictionary:
	var _obj_type: StringName = _get_typeny_arg(_dict.return )

	var obj: Dictionary = {
		name = _dict.name,
		type = _obj_type if _obj_type != StringName('Nil') else StringName('void'),
		data = {
			name = _dict.name,
			sub_type = _get_sub_type(_dict.return.type, _dict.return.usage),
			inputs = [ {
				name = _class_name,
				type = _class_name,
				ref = true
			}] + (_dict.args as Array).map(
				func(arg) -> Dictionary:
					match arg.usage:
						65542:
							return {
								name = arg.name,
								sub_type = '@dropdown',
								category = 'enum_list',
								data = arg.class_name.split('.'),
							}
						_:
							return {
							name = arg.name,
							type = _get_typeny_arg(arg)
						}
					),
			route = HenRouter.current_route
		},
	}


	# it's a void or return a variant
	if _dict.return.type != TYPE_NIL or (_dict.return.type == TYPE_NIL and _dict.return.usage == 131078):
		obj['data']['outputs'] = [ {
			name = _dict.return.name,
			type = _get_typeny_arg(_dict.return )
		}]

	return obj


func start_api(_class_name: StringName = 'all') -> int:
	api_list = HenGlobal.SCRIPTS_INFO.map(
		func(x: Dictionary) -> Dictionary:
			x['data']['route'] = HenRouter.current_route
			return x
	)

	match _class_name:
		'all':
			for cl_name: StringName in ClassDB.get_class_list():
				for dict in ClassDB.class_get_method_list(_class_name):
					api_list.append(_get_class_obj(dict, cl_name, _class_name))
		_:
			if HenEnums.VARIANT_TYPES.has(_class_name):
				if HenEnums.NATIVE_API_LIST.has(_class_name):
					api_list = HenEnums.NATIVE_API_LIST[_class_name].map(func(obj: Dictionary) -> Dictionary:
						var dt: Dictionary = obj

						dt.data.route = HenRouter.current_route
						dt.type = _class_name

						return dt
						)
				else:
					api_list = []
				
				if HenEnums.NATIVE_PROPS_LIST.has(_class_name):
					for prop in HenEnums.NATIVE_PROPS_LIST.get(_class_name):
							api_list.append({
								name = 'Get Prop -> ' + prop.name,
								data = {
									name = prop.name,
									fantasy_name = 'Get Prop -> ' + prop.name,
									sub_type = HenCnode.SUB_TYPE.GET_PROP,
									inputs = [
										{
											name = _class_name,
											type = _class_name,
											ref = true
										}
									],
									outputs = [
										{
											name = prop.name,
											type = prop.type,
										}
									],
									route = HenRouter.current_route
								}
							})

							api_list.append({
								name = 'Set Prop -> ' + prop.name,
								data = {
									name = prop.name,
									fantasy_name = 'Set Prop -> ' + prop.name,
									sub_type = HenCnode.SUB_TYPE.SET_PROP,
									inputs = [
										{
											name = _class_name,
											type = _class_name,
											ref = true
										},
										{
											name = prop.name,
											type = prop.type,
										}
									],
									route = HenRouter.current_route
								}
							})


			else:
				if came_from == 'in':
					api_list = []

				else:
					for dict in ClassDB.class_get_method_list(_class_name):
						api_list.append(_get_class_obj(dict, _class_name, _class_name))
					
					# const / enums
					for key in HenEnums.CONST_API_LIST:
						var value: Array = HenEnums.CONST_API_LIST[key]

						api_list.append({
							name = 'Const -> ' + key,
							data = {
								name = key,
								sub_type = HenCnode.SUB_TYPE.CONST,
								category = 'native',
								outputs = [
									{
										name = '',
										type = key,
										sub_type = '@dropdown',
										category = 'const',
										out_prop = '...',
										data = value
									}
								],
								route = HenRouter.current_route
							}
						})

					# singleton
					for singleton_config in HenEnums.SINGLETON_API_LIST:
						var dt: Dictionary = singleton_config
						dt.data.route = HenRouter.current_route
						api_list.append(dt)
					
					
					for prop in ClassDB.class_get_property_list(_class_name):
						var set_data: Dictionary = {
							name = 'Set Prop -> ' + prop.name,
							data = {
								name = prop.name,
								fantasy_name = 'Set Prop -> ' + prop.name,
								sub_type = HenCnode.SUB_TYPE.SET_PROP,
								inputs = [
									{
										name = _class_name,
										type = _class_name,
										ref = true
									},
									{
										name = prop.name,
										type = type_string(prop.type),
										ref = true
									}
								],
								route = HenRouter.current_route
							}
						}

						var get_data: Dictionary = {
							name = 'Get Prop -> ' + prop.name,
							data = {
								name = prop.name,
								fantasy_name = 'Get Prop -> ' + prop.name,
								sub_type = HenCnode.SUB_TYPE.GET_PROP,
								inputs = [
									{
										name = _class_name,
										type = _class_name,
										ref = true
									}
								],
								outputs = [
									{
										name = prop.name,
										type = type_string(prop.type),
									}
								],
								route = HenRouter.current_route
							}
						}

						if HenEnums.NATIVE_PROPS_LIST.has(type_string(prop.type)):
							set_data.data.inputs += HenEnums.NATIVE_PROPS_LIST.get(type_string(prop.type))
							get_data.data.outputs += HenEnums.NATIVE_PROPS_LIST.get(type_string(prop.type))

						api_list.append(set_data)
						api_list.append(get_data)

					
					# set variable
					var idx: int = 0
					for var_config in HenGlobal.PROPS_CONTAINER.get_all_values().filter(func(x: Dictionary) -> bool:
						return x.prop_type == StringName('VARIABLE')):
						api_list.append({
							name = 'Set Var -> ' + var_config.name,
							data = {
								name = 'Set Var -> ' + var_config.name,
								sub_type = HenCnode.SUB_TYPE.SET_VAR,
								inputs = [ {
									name = var_config.name,
									type = var_config.type,
									group = 'p' + str(idx),
								}],
								route = HenRouter.current_route
							}
						})

						api_list.append({
							name = 'Get Var -> ' + var_config.name,
							data = {
								name = '',
								sub_type = HenCnode.SUB_TYPE.VAR,
								outputs = [ {
									name = var_config.name,
									type = var_config.type,
									group = 'p' + str(idx),
									group_idx = idx
								}],
								route = HenRouter.current_route
							}
						})
						idx += 1
					
					# functions
					for func_ref in HenGlobal.ROUTE_REFERENCE_CONTAINER.get_children().filter(func(x: HenRouteReference) -> bool: return x.type == HenRouteReference.TYPE.FUNC):
						var dt_name: String = func_ref.props[0].value

						var dt: Dictionary = {
							name = 'Func -> ' + dt_name,
							data = {
								name = dt_name,
								fantasy_name = 'Func -> ' + dt_name,
								sub_type = HenCnode.SUB_TYPE.USER_FUNC,
								inputs = [],
								outputs = [],
								route = HenRouter.current_route,
								group = 'f_' + str(func_ref.hash)
							}
						}
						
						var p_idx: int = 0
						for prop_config in func_ref.props[1].value:
							prop_config.group = 'fi_' + str(func_ref.hash) + '_' + str(p_idx)
							dt.data.inputs.append(prop_config)
							p_idx += 1
						

						p_idx = 0
						for prop_config in func_ref.props[2].value:
							prop_config.group = 'fo_' + str(func_ref.hash) + '_' + str(p_idx)
							dt.data.outputs.append(prop_config)
							p_idx += 1

						api_list.append(dt)


	return OK


func start(_type: StringName, _pos: Vector2, _show_native: bool = true, _came_from: String = 'out', _cnode_config: Dictionary = {}) -> void:
	connection_type = _type
	start_pos = _pos
	show_native_first = _show_native
	came_from = _came_from
	cnode_config = _cnode_config