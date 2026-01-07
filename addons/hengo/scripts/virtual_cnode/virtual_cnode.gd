@tool
class_name HenVirtualCNode extends HenVirtualCNodeRenderer

enum Type {
	DEFAULT = 0,
	IF = 1,
	FOR = 2,
	IMG = 3,
	EXPRESSION = 4,
	STATE = 5,
	STATE_START = 6,
	MACRO = 8,
	MACRO_INPUT = 9,
	MACRO_OUTPUT = 10,
}

enum SubType {
	FUNC = 0,
	VOID = 1,
	VAR = 2,
	LOCAL_VAR = 3,
	DEBUG_VALUE = 4,
	USER_FUNC = 5,
	SET_VAR = 6,
	GET_FROM_PROP = 9,
	VIRTUAL = 10,
	FUNC_INPUT = 11,
	CAST = 12,
	IF = 13,
	RAW_CODE = 14,
	SELF_GO_TO_VOID = 15,
	FOR = 16,
	FOR_ARR = 17,
	FOR_ITEM = 18,
	FUNC_OUTPUT = 19,
	CONST = 20,
	GO_TO_VOID = 22,
	IMG = 23,
	EXPRESSION = 24,
	SET_LOCAL_VAR = 25,
	IN_PROP = 26,
	NOT_CONNECTED = 27,
	DEBUG = 28,
	DEBUG_PUSH = 29,
	DEBUG_FLOW_START = 30,
	START_DEBUG_STATE = 31,
	DEBUG_STATE = 32,
	BREAK = 33,
	CONTINUE = 34,
	PASS = 35,
	STATE = 36,
	STATE_START = 37,
	SIGNAL_ENTER = 39,
	SIGNAL_CONNECTION = 40,
	SIGNAL_DISCONNECTION = 41,
	MACRO = 42,
	MACRO_INPUT = 43,
	MACRO_OUTPUT = 44,
	OVERRIDE_VIRTUAL = 45,
	FUNC_FROM = 46,
	INVALID = 47,
	VAR_FROM = 50,
	SET_VAR_FROM = 51,
	MAKE_TRANSITION = 52,
	STATE_TRANSITION = 53,
	STATE_TRANSITION_FROM = 54,
	GET_PROP = 55,
	SET_PROP = 56
}


func _init() -> void:
	if not cnode_need_update.is_connected(update): cnode_need_update.connect(update)
	if not io_hovered.is_connected(on_node_io_hovered): io_hovered.connect(on_node_io_hovered)
	if not expression_saved.is_connected(on_expression_saved): expression_saved.connect(on_expression_saved)
	if not method_picker_requested.is_connected(on_method_picker_requested): method_picker_requested.connect(on_method_picker_requested)


func show() -> void:
	var cnode: HenCnode = HenPool.get_cnode_from_pool()
	if not cnode:
		return

	cnode_instance = cnode
	configure_cnode_to_show(self, cnode)
	cnode.reset_signals(self)


func hide() -> void:
	if not cnode_instance:
		return
	
	configure_cnode_to_hide(cnode_instance)
	cnode_instance.reset_signals()
	cnode_instance = null


func update() -> void:
	if not cnode_instance:
		return
	var router: HenRouter = Engine.get_singleton(&'Router')
	var route: HenRouteData = get_parent_route()
	var should_hide: bool = is_deleted or (not route or not router.current_route or route.id != router.current_route.id)

	hide()

	if not should_hide:
		check_visibility()


func check_visibility(_rect: Rect2 = (Engine.get_singleton(&'Global') as HenGlobal).CAM.get_rect()) -> void:
	is_showing = _rect.intersects(Rect2(
		position,
		size
	))

	if is_showing and not is_instance_valid(cnode_instance):
		show()
	elif not is_showing:
		hide()


func get_input_by_idx(_idx: int) -> HenVCInOutData:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	return get_inputs(global.SAVE_DATA).get(_idx)

func get_output_by_idx(_idx: int) -> HenVCInOutData:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	return get_outputs(global.SAVE_DATA).get(_idx)


func get_new_input_connection_command(_id: int, _from_id: int, _from: HenVirtualCNode) -> HenVCConnectionReturn:
	return create_input_connection(_id, _from_id, self, _from)


func select() -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')

	if not global.SELECTED_VIRTUAL_CNODE.has(self):
		global.SELECTED_VIRTUAL_CNODE.append(self)

		if cnode_instance:
			cnode_instance.select()


func unselect() -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')

	global.SELECTED_VIRTUAL_CNODE.erase(self)

	if cnode_instance:
		cnode_instance.unselect()


func on_cnode_mouse_enter() -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')

	if global.can_make_flow_connection and not get_flow_inputs(global.SAVE_DATA).is_empty():
		global.flow_connection_to_data = {
			to_cnode = self,
			to_id = get_flow_inputs(global.SAVE_DATA)[0].id
		}

func on_cnode_selected(_selected: bool) -> void:
	if _selected:
		select()
	else:
		unselect()


func on_cnode_hovering(_mouse_pos: Vector2) -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')


	if invalid:
		global.TOOLTIP.go_to(_mouse_pos, HenEnums.TOOLTIP_TEXT.CNODE_INVALID)
	else:
		match type:
			HenVirtualCNode.Type.STATE:
				global.TOOLTIP.go_to(_mouse_pos, HenEnums.TOOLTIP_TEXT.RIGHT_MOUSE_INSPECT)
			_:
				global.TOOLTIP.close()


func request_flow_connector_connection(_id: int, _mouse_pos: Vector2) -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')

	global.GENERAL_POPUP.show_content(HenCodeSearch.load(_mouse_pos, {
		id = _id,
		from_flow_connector = self
	}), '')


func request_io_connection(_io_type: StringName, _id: int, _mouse_pos: Vector2, _type: StringName) -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')

	global.GENERAL_POPUP.show_content(HenCodeSearch.load(_mouse_pos, {
		io_type = _io_type,
		id = _id,
		vc_ref = self,
		type = _type
	}), '')


func on_cnode_double_click() -> void:
	var router: HenRouter = Engine.get_singleton(&'Router')
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var res: HenSaveResTypeWithRoute = get_res(global.SAVE_DATA)

	if res:
		var route: HenRouteData = res.get_route(global.SAVE_DATA)
		if route:
			router.change_route(route)


func on_cnode_right_click(_mouse_pos: Vector2) -> void:
	# showing state config on right click
	if type == HenVirtualCNode.Type.STATE:
		pass

func on_node_io_hovered(context: Dictionary) -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	
	# creates connection data using self as the owner and context source as the port
	global.connection_to_data = CNodeInOutConnectionData.new(
		self,
		context.source
	)

	if global.CONNECTION_GUIDE.is_in_out:
		var connector: TextureRect = context.connector
		var pos = global.CAM.get_relative_vec2(connector.global_position)

		# updates the global guide visual state
		global.CONNECTION_GUIDE.hover_pos = pos + connector.size / 2
		global.CONNECTION_GUIDE.gradient.colors[1] = context.color


func on_expression_saved(context: Dictionary) -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var _inputs: Array[HenVCInOutData] = get_inputs(global.SAVE_DATA)
	_inputs[0].value = context.code
	
	var current_inputs_map := {}
	var inputs_to_remove: Array[HenVCInOutData] = []
	
	for i in range(1, _inputs.size()):
		var input = _inputs[i]
		current_inputs_map[input.name] = input
	
	var new_words_set := {}
	for word in context.words:
		new_words_set[word] = true
		
		if not current_inputs_map.has(word):
			add_io(true, {
				name = word,
				type = 'Variant'
			})
	
	for input_name in current_inputs_map:
		if not new_words_set.has(input_name):
			inputs_to_remove.append(current_inputs_map[input_name])
	
	for input in inputs_to_remove:
		on_in_out_deleted(true, input)

	(Engine.get_singleton(&'Global') as HenGlobal).GENERAL_POPUP.hide_popup()
	update()


func on_method_picker_requested(context: Dictionary) -> void:
	# triggers the internal logic to open the connection menu
	request_io_connection(
		context.io_type,
		context.port_id,
		context.mouse_pos,
		context.port_type
	)


func set_cnode_moving(_moving: bool) -> void:
	if not cnode_instance:
		return

	cnode_instance.moving = _moving


func on_cnode_changed_position(_pos: Vector2) -> void:
	position = _pos


func set_position(_position: Vector2) -> void:
	position = _position
	update()


func follow(_position: Vector2) -> void:
	if cnode_instance:
		cnode_instance.follow(_position)


func set_position_transition(_position: Vector2) -> void:
	position = _position
	

func get_id() -> int:
	return id


func get_vc_name(_save_data: HenSaveData) -> String:
	var res: HenSaveResToInspectType = get_res(_save_data)
	
	if res:
		return res.get_vc_name(sub_type)
	else:
		return name


func add_flow_connection(_id: int, _to_id: int, _to: HenVirtualCNode) -> HenVCFlowConnectionReturn:
	return add_flow_connection_with_return(_id, _to_id, self, _to)


func add_io(_is_input: bool, _data: Dictionary, _check_types: bool = true) -> HenVCInOutData:
	return on_in_out_added(_is_input, _data, _check_types)


func get_history_obj() -> HenVCNodeReturn:
	return HenVCNodeReturn.new(self)


func get_flow_input_connection(_id: int) -> HenVCFlowConnectionData:
	return get_flow_input_connection_data(_id, self)


func get_flow_output_connection(_id: int) -> HenVCFlowConnectionData:
	return get_flow_output_connection_data(_id, self)


static func instantiate_virtual_cnode(_config: Dictionary) -> HenVirtualCNode:
	# adding virtual cnode to list
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var v_cnode: HenVirtualCNode = HenVirtualCNode.new()
	var _route: HenRouteData = _config.route

	v_cnode.name = _config.name
	v_cnode.type = _config.type as Type if _config.has('type') else Type.DEFAULT
	v_cnode.sub_type = _config.sub_type
	v_cnode.id = global.get_new_node_counter() if not _config.has('id') else _config.id
	v_cnode.parent_route_id = _route.id
	v_cnode.route_type = _route.type

	if _config.has('name_to_code'): v_cnode.name_to_code = _config.name_to_code

	_route.virtual_cnode_list.append(v_cnode)

	if _config.has('input_code_value_map'):
		v_cnode.input_code_value_map = _config.input_code_value_map

	if _config.has('singleton_class'):
		v_cnode.singleton_class = _config.singleton_class

	if _config.has('can_delete'):
		v_cnode.can_delete = _config.can_delete

	if _config.has('invalid'):
		v_cnode.invalid = _config.invalid

	if _config.has('res_data'):
		v_cnode.res_data = _config.get('res_data')

	if _config.has('res'):
		var res_obj: Resource = _config.get('res')
		var res_type: int = -1
		
		if "id" in res_obj:
			if res_obj is HenSaveVar:
				res_type = HenSideBar.AddType.VAR
			elif res_obj is HenSaveFunc:
				res_type = HenSideBar.AddType.FUNC
			elif res_obj is HenSaveSignalCallback:
				res_type = HenSideBar.AddType.SIGNAL_CALLBACK
			elif res_obj is HenSaveSignal:
				res_type = HenSideBar.AddType.SIGNAL
			elif res_obj is HenSaveMacro:
				res_type = HenSideBar.AddType.MACRO
			elif res_obj is HenSaveState:
				res_type = HenSideBar.AddType.STATE
		
		if res_type != -1:
			v_cnode.res_data = {
				id = res_obj.get(&'id'),
				type = res_type
			}

	if _config.has('category'):
		v_cnode.category = _config.category

	if _config.has('position'):
		v_cnode.position = _config.position if _config.position is Vector2 else str_to_var(_config.position)
	
	if _config.has('size'):
		v_cnode.size = _config.size if _config.size is Vector2 else str_to_var(_config.size)

	match v_cnode.sub_type:
		SubType.VIRTUAL:
			_route.virtual_sub_type_vc_list.append(v_cnode)


	match v_cnode.type:
		HenVirtualCNode.Type.DEFAULT:
			if not _config.has('to_flow'): v_cnode.get_flow_outputs(global.SAVE_DATA).append(HenVCFlow.create(v_cnode, {id = 0}))
			v_cnode.get_flow_inputs(global.SAVE_DATA).append(HenVCFlow.create(v_cnode, {id = 0}))
		Type.IF:
			v_cnode.get_flow_outputs(global.SAVE_DATA).append(HenVCFlow.create(v_cnode, {name = 'True', id = 0}))
			v_cnode.get_flow_outputs(global.SAVE_DATA).append(HenVCFlow.create(v_cnode, {name = 'False', id = 1}))
			v_cnode.get_flow_outputs(global.SAVE_DATA).append(HenVCFlow.create(v_cnode, {name = 'Then', id = 2}))
			v_cnode.get_flow_inputs(global.SAVE_DATA).append(HenVCFlow.create(v_cnode, {id = 0}))
		Type.FOR:
			v_cnode.get_flow_outputs(global.SAVE_DATA).append(HenVCFlow.create(v_cnode, {name = 'Body', id = 0}))
			v_cnode.get_flow_outputs(global.SAVE_DATA).append(HenVCFlow.create(v_cnode, {name = 'Then', id = 1}))
			v_cnode.get_flow_inputs(global.SAVE_DATA).append(HenVCFlow.create(v_cnode, {id = 0}))
		Type.STATE_START:
			v_cnode.get_flow_outputs(global.SAVE_DATA).append(HenVCFlow.create(v_cnode, {name = 'On Start', id = 0}))
			v_cnode.get_flow_inputs(global.SAVE_DATA).append(HenVCFlow.create(v_cnode, {id = 0}))
		_:
			if _config.has('to_flow'):
				for _flow: Dictionary in _config.to_flow:
					v_cnode.on_flow_added(false, _flow, v_cnode)

			if _config.has('from_flow'):
				for _flow: Dictionary in _config.from_flow:
					v_cnode.on_flow_added(true, _flow, v_cnode)

	if _config.has('inputs'):
		for input_data: Dictionary in _config.inputs:
			v_cnode.add_io(true, input_data, false)

	if _config.has('outputs'):
		for output_data: Dictionary in _config.outputs:
			v_cnode.add_io(false, output_data, false)

	return v_cnode


static func instantiate(_config: Dictionary) -> HenVCNodeReturn:
	var v_cnode: HenVirtualCNode = instantiate_virtual_cnode(_config)
	return HenVCNodeReturn.new(v_cnode)
