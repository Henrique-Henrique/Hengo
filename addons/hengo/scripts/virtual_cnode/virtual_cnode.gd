@tool
class_name HenVirtualCNode extends RefCounted

enum Type {
	DEFAULT = 0,
	IF = 1,
	FOR = 2,
	IMG = 3,
	EXPRESSION = 4,
	STATE = 5,
	STATE_START = 6,
	STATE_EVENT = 7,
	MACRO = 8,
	MACRO_INPUT = 9,
	MACRO_OUTPUT = 10
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
	STATE_EVENT = 38,
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
	SET_VAR_FROM = 51
}


var state: HenVirtualCNodeState
var identity: HenVirtualCNodeIdentity
var visual: HenVirtualCNodeVisual
var route_info: HenVirtualCNodeRoute
var io: HenVirtualCNodeIO
var flow: HenVirtualCNodeFlow
var references: HenVirtualCNodeReference
var renderer: HenVirtualCNodeRenderer
var pool: HenPool

var cnode_instance: HenCnode

func _init() -> void:
	pool = HenPool.new()
	state = HenVirtualCNodeState.new()
	identity = HenVirtualCNodeIdentity.new()
	visual = HenVirtualCNodeVisual.new()
	route_info = HenVirtualCNodeRoute.new()
	flow = HenVirtualCNodeFlow.new(identity)
	references = HenVirtualCNodeReference.new()
	io = HenVirtualCNodeIO.new(identity, state, references)
	renderer = HenVirtualCNodeRenderer.new(
		state,
		visual,
		identity,
		io,
		flow,
		pool,
		references
	)

	identity.cnode_need_update.connect(update)
	io.cnode_need_update.connect(update)
	flow.cnode_need_update.connect(update)
	state.cnode_need_update.connect(update)
	io.connection_request.connect(on_node_connection_command_requested)
	io.io_hovered.connect(on_node_io_hovered)
	io.expression_saved.connect(on_expression_saved)
	io.method_picker_requested.connect(on_method_picker_requested)


func show() -> void:
	var cnode: HenCnode = pool.get_cnode_from_pool()

	if not cnode:
		return

	cnode_instance = cnode
	renderer.configure_cnode_to_show(cnode)
	cnode.reset_signals(self)


func hide() -> void:
	if not cnode_instance:
		return
	
	renderer.configure_cnode_to_hide(cnode_instance)
	cnode_instance.reset_signals()
	cnode_instance = null


func update() -> void:
	if not cnode_instance:
		return
	var router: HenRouter = Engine.get_singleton(&'Router')
	var should_hide: bool = state.is_deleted or (not route_info.route_ref or not router.current_route or route_info.route_ref.id != router.current_route.id)

	hide()

	if not should_hide:
		check_visibility()


func check_visibility(_rect: Rect2 = (Engine.get_singleton(&'Global') as HenGlobal).CAM.get_rect()) -> void:
	state.is_showing = _rect.intersects(Rect2(
		visual.position,
		visual.size
	))

	if state.is_showing and cnode_instance == null:
		show()
	elif not state.is_showing:
		hide()


func get_input(_id: int) -> HenVCInOutData:
	return io.get_input(_id)


func get_input_by_idx(_idx: int) -> HenVCInOutData:
	return io.get_inputs().get(_idx)

func get_output_by_idx(_idx: int) -> HenVCInOutData:
	return io.get_outputs().get(_idx)


func get_new_input_connection_command(_id: int, _from_id: int, _from: HenVirtualCNode) -> HenVCConnectionReturn:
	return io.create_input_connection(_id, _from_id, self, _from)


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

	if global.can_make_flow_connection and not flow.flow_inputs.is_empty():
		global.flow_connection_to_data = {
			to_cnode = self,
			to_id = flow.flow_inputs[0].id
		}

func on_cnode_selected(_selected: bool) -> void:
	if _selected:
		select()
	else:
		unselect()


func on_cnode_hovering(_mouse_pos: Vector2) -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')

	if state.invalid:
		global.TOOLTIP.go_to(_mouse_pos, HenEnums.TOOLTIP_TEXT.CNODE_INVALID)
	else:
		match identity.type:
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

	if route_info.route:
		router.change_route(route_info.route)


func on_cnode_right_click(_mouse_pos: Vector2) -> void:
	# showing state config on doubleclick
	if identity.type == HenVirtualCNode.Type.STATE:
		@warning_ignore('unsafe_method_access')
		(Engine.get_singleton(&'Global') as HenGlobal).GENERAL_POPUP.show_content(
			HenPropEditor.mount(self),
			'Testing',
			_mouse_pos
		)

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
	var inputs: Array[HenVCInOutData] = io.get_inputs()
	# updates the first input value and clears subsequent inputs
	inputs[0].value = context.code
	
	for input: HenVCInOutData in inputs.slice(1):
		input._on_delete(true)

	for word in context.words:
		# adds new inputs based on the word list
		add_io(true, {
			name = word,
			type = 'Variant'
		})

	(Engine.get_singleton(&'Global') as HenGlobal).GENERAL_POPUP.hide_popup()
	update()


func on_node_connection_command_requested(_context: Dictionary) -> void:
	var connection: HenVCConnectionReturn
	var r_data: CNodeInOutConnectionData = _context.remote_data
	
	# determines creation direction based on type
	if _context.type == "in":
		connection = get_new_input_connection_command(
			_context.local_port_id,
			r_data.in_out.id,
			r_data.vc
		)
	else:
		connection = (r_data.vc as HenVirtualCNode).get_new_input_connection_command(
			r_data.in_out.id,
			_context.local_port_id,
			self
		)

	# executes history logic if connection command is valid
	if connection:
		var global: HenGlobal = Engine.get_singleton(&'Global')
		
		global.history.create_action('Add Connection')
		global.history.add_do_method(connection.add)
		global.history.add_do_reference(connection)
		global.history.add_undo_method(connection.remove)
		global.history.commit_action()


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
	visual.position = _pos


func set_position(_position: Vector2) -> void:
	visual.position = _position
	update()


func follow(_position: Vector2) -> void:
	if cnode_instance:
		cnode_instance.follow(_position)


func set_position_transition(_position: Vector2) -> void:
	visual.position = _position
	

func get_id() -> int:
	return identity.id


func get_save(_save_data: HenSaveData) -> Dictionary:
	var data: Dictionary = {
		id = identity.id,
		type = identity.type,
		sub_type = identity.sub_type,
		name = identity.name,
		position = var_to_str(visual.position),
		size = var_to_str(visual.size),
	}

	if not state.can_delete:
		data.can_delete = false

	if identity.name_to_code:
		data.name_to_code = identity.name_to_code

	if identity.singleton_class:
		data.singleton_class = identity.singleton_class

	if state.invalid:
		data.invalid = state.invalid

	if identity.from_side_bar_id > -1:
		data.from_side_bar_id = identity.from_side_bar_id

	if identity.from_id > -1:
		data.from_id = str(identity.from_id)
		data.side_bar_id = identity.side_bar_id

	if references.res:
		match identity.sub_type:
			HenVirtualCNode.SubType.FUNC_INPUT, HenVirtualCNode.SubType.FUNC_OUTPUT:
				pass
			_:
				data.res = references.res
	else:
		var inputs: Array[HenVCInOutData] = io.get_inputs()
		var outputs: Array[HenVCInOutData] = io.get_outputs()

		if not inputs.is_empty():
			data.inputs = []

			for input: HenVCInOutData in inputs:
				(data.inputs as Array).append(input.get_save())
		
		if not outputs.is_empty():
			data.outputs = []

			for output: HenVCInOutData in outputs:
				(data.outputs as Array).append(output.get_save())

	if identity.category:
		data.category = identity.category

	if _save_data:
		for flow_connection: HenVCFlowConnectionData in flow.flow_connections_2:
			if not flow_connection.get_to(): continue
			if flow_connection.get_to() == self: continue

			_save_data.flow_connections.append(flow_connection.get_save())


		for input: HenVCConnectionData in io.connections:
			if input.get_to().identity.id != identity.id:
				continue

			_save_data.connections.append(input.get_save())


	# these types don't need to save the flow connections, are hengo's native
	match identity.type:
		HenVirtualCNode.Type.DEFAULT:
			var flows: Array = []

			for flow_connection: HenVCFlow in flow.flow_outputs:
				if flow_connection.name:
					flows.append({id = flow_connection.id, name = flow_connection.name})
			
			if not flows.is_empty(): data.to_flow = flows
		HenVirtualCNode.Type.STATE:
			data.to_flow = []
			for flow_connection: HenVCFlow in flow.flow_outputs:
					if flow_connection.name:
						(data.to_flow as Array).append({name = flow_connection.name, id = flow_connection.id})


	if route_info.route and not route_info.route.virtual_cnode_list.is_empty():
		data.virtual_cnode_list = []

		for v_cnode: HenVirtualCNode in route_info.route.virtual_cnode_list:
			(data.virtual_cnode_list as Array).append(v_cnode.get_save(_save_data))


	return data


func add_flow_connection(_id: int, _to_id: int, _to: HenVirtualCNode) -> HenVCFlowConnectionReturn:
	return flow.add_flow_connection(_id, _to_id, self, _to)


func add_io(_is_input: bool, _data: Dictionary, _check_types: bool = true) -> HenVCInOutData:
	return io.on_in_out_added(_is_input, _data, _check_types)


func get_history_obj() -> HenVCNodeReturn:
	return HenVCNodeReturn.new(self)


func get_inspector_array_list() -> Array:
	match identity.sub_type:
		SubType.STATE:
			return [
				HenProp.new({
					name = 'Name',
					type = HenProp.Type.STRING,
					default_value = identity.name,
					on_value_changed = identity.on_change_name
				}),
				HenProp.new({
					name = 'Outputs',
					type = HenProp.Type.ARRAY,
					on_item_create = flow.create_input_flow_connection.bind(self),
					prop_list = flow.flow_outputs.map(func(x: HenVCFlow) -> HenProp: return HenProp.new({
						name = 'name',
						type = HenProp.Type.STRING,
						default_value = x.name,
						on_value_changed = flow.change_flow_name.bind(x),
						on_item_delete = flow.on_delete_flow_state.bind(x),
						on_item_move = flow.move_flow.bind(x, false),
					})),
				}),
			]
		
	return []


func get_flow_input_connection(_id: int) -> HenVCFlowConnectionData:
	return flow.get_flow_input_connection(_id, self)


func get_flow_output_connection(_id: int) -> HenVCFlowConnectionData:
	return flow.get_flow_output_connection(_id, self)


static func instantiate_virtual_cnode(_config: Dictionary) -> HenVirtualCNode:
	# adding virtual cnode to list
	var v_cnode: HenVirtualCNode = HenVirtualCNode.new()
	var route: HenRouteData = _config.route

	v_cnode.identity.name = _config.name
	v_cnode.identity.type = _config.type as Type if _config.has('type') else Type.DEFAULT
	v_cnode.identity.sub_type = _config.sub_type
	v_cnode.identity.id = (Engine.get_singleton(&'Global') as HenGlobal).get_new_node_counter() if not _config.has('id') else _config.id
	v_cnode.route_info.route_ref = route
	
	if _config.has('name_to_code'): v_cnode.identity.name_to_code = _config.name_to_code

	match route.type:
		HenRouter.ROUTE_TYPE.BASE, HenRouter.ROUTE_TYPE.STATE:
			route.virtual_cnode_list.append(v_cnode)
		HenRouter.ROUTE_TYPE.FUNC:
			route.virtual_cnode_list.append(v_cnode)
		
			match v_cnode.identity.sub_type:
				SubType.FUNC_INPUT:
					route.input_ref = weakref(v_cnode)
				SubType.FUNC_OUTPUT:
					route.output_ref = weakref(v_cnode)
		HenRouter.ROUTE_TYPE.SIGNAL:
			route.virtual_cnode_list.append(v_cnode)
			match v_cnode.identity.sub_type:
				SubType.SIGNAL_ENTER:
					route.signal_enter = v_cnode
		HenRouter.ROUTE_TYPE.MACRO:
			route.virtual_cnode_list.append(v_cnode)

			match v_cnode.identity.sub_type:
				SubType.MACRO_INPUT:
					route.input_ref = weakref(v_cnode)
				SubType.MACRO_OUTPUT:
					route.output_ref = weakref(v_cnode)

	
	if _config.has('singleton_class'):
		v_cnode.identity.singleton_class = _config.singleton_class

	if _config.has('can_delete'):
		v_cnode.state.can_delete = _config.can_delete

	if _config.has('from_side_bar_id'):
		v_cnode.identity.from_side_bar_id = _config.from_side_bar_id

	if _config.has('from_id'):
		v_cnode.identity.from_id = int(_config.from_id)
		v_cnode.identity.side_bar_id = int(_config.side_bar_id)

	if _config.has('invalid'):
		v_cnode.state.invalid = _config.invalid

	if _config.has('res'):
		v_cnode.references.res = _config.get('res')

	if _config.has('category'):
		v_cnode.identity.category = _config.category

	if _config.has('position'):
		v_cnode.visual.position = _config.position if _config.position is Vector2 else str_to_var(_config.position)
	
	if _config.has('size'):
		v_cnode.visual.size = _config.size if _config.size is Vector2 else str_to_var(_config.size)

	match v_cnode.identity.sub_type:
		SubType.VIRTUAL:
			route.virtual_sub_type_vc_list.append(v_cnode)
		SubType.MACRO, SubType.MACRO_INPUT, SubType.MACRO_OUTPUT:
			if v_cnode.references.res is HenSaveMacro:
				var _ref: HenSaveMacro = v_cnode.references.res

				_config.from_flow = _ref.flow_inputs.map(func(x: HenSaveParam) -> Dictionary: return x.get_data())
				_config.to_flow = _ref.flow_outputs.map(func(x: HenSaveParam) -> Dictionary: return x.get_data())

	match v_cnode.identity.type:
		HenVirtualCNode.Type.DEFAULT:
			if not _config.has('to_flow'): v_cnode.flow.flow_outputs.append(HenVCFlow.new(v_cnode, {id = 0}))
			v_cnode.flow.flow_inputs.append(HenVCFlow.new(v_cnode, {id = 0}))
		Type.IF:
			v_cnode.flow.flow_outputs.append(HenVCFlow.new(v_cnode, {name = 'True', id = 0}))
			v_cnode.flow.flow_outputs.append(HenVCFlow.new(v_cnode, {name = 'False', id = 1}))
			v_cnode.flow.flow_outputs.append(HenVCFlow.new(v_cnode, {name = 'Then', id = 2}))
			v_cnode.flow.flow_inputs.append(HenVCFlow.new(v_cnode, {id = 0}))
		Type.FOR:
			v_cnode.flow.flow_outputs.append(HenVCFlow.new(v_cnode, {name = 'Body', id = 0}))
			v_cnode.flow.flow_outputs.append(HenVCFlow.new(v_cnode, {name = 'Then', id = 1}))
			v_cnode.flow.flow_inputs.append(HenVCFlow.new(v_cnode, {id = 0}))
		Type.STATE:
			v_cnode.route_info.route = HenRouteData.new(
				v_cnode.identity.name,
				HenRouter.ROUTE_TYPE.STATE,
				HenUtilsName.get_unique_name(),
			)

			if not _config.has('virtual_cnode_list'):
				HenVirtualCNode.instantiate_virtual_cnode({
					name = 'enter',
					sub_type = HenVirtualCNode.SubType.VIRTUAL,
					route = v_cnode.route_info.route,
					position = Vector2.ZERO,
					can_delete = false
				})

				HenVirtualCNode.instantiate_virtual_cnode({
					name = 'update',
					sub_type = HenVirtualCNode.SubType.VIRTUAL,
					outputs = [ {
						name = 'delta',
						type = 'float'
					}],
					route = v_cnode.route_info.route,
					position = Vector2(400, 0),
					can_delete = false
				})

			v_cnode.flow.flow_inputs.append(HenVCFlow.new(v_cnode, {id = 0}))

			if _config.has('to_flow'):
				for _flow: Dictionary in _config.to_flow:
					v_cnode.flow.on_flow_added(false, _flow, v_cnode)
		Type.STATE_START:
			v_cnode.flow.flow_outputs.append(HenVCFlow.new(v_cnode, {name = 'On Start', id = 0}))
			v_cnode.flow.flow_inputs.append(HenVCFlow.new(v_cnode, {id = 0}))
		Type.STATE_EVENT:
			v_cnode.flow.flow_outputs.append(HenVCFlow.new(v_cnode, {id = 0}))
		_:
			if _config.has('to_flow'):
				for _flow: Dictionary in _config.to_flow:
					v_cnode.flow.on_flow_added(false, _flow, v_cnode)

			if _config.has('from_flow'):
				for _flow: Dictionary in _config.from_flow:
					v_cnode.flow.on_flow_added(true, _flow, v_cnode)

	if _config.has('inputs'):
		for input_data: Dictionary in _config.inputs:
			var input: HenVCInOutData = v_cnode.add_io(true, input_data, false)

			if not input_data.has('code_value'):
				input.reset_input_value()


	if _config.has('outputs'):
		for output_data: Dictionary in _config.outputs:
			v_cnode.add_io(false, output_data, false)

	return v_cnode


static func instantiate_virtual_cnode_and_add(_config: Dictionary) -> HenVirtualCNode:
	var v_cnode: HenVirtualCNode = instantiate_virtual_cnode(_config)
	v_cnode.update()
	return v_cnode


static func instantiate(_config: Dictionary) -> HenVCNodeReturn:
	var v_cnode: HenVirtualCNode = instantiate_virtual_cnode(_config)
	return HenVCNodeReturn.new(v_cnode)


func clean() -> void:
	pass