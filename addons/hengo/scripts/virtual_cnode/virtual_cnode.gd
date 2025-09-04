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
	DEEP_PROP = 48,
	SET_DEEP_PROP = 49
}


var state: HenVirtualCNodeState
var identity: HenVirtualCNodeIdentity
var visual: HenVirtualCNodeVisual
var route_info: HenVirtualCNodeRoute
var children: HenVirtualCNodeChildren
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
	children = HenVirtualCNodeChildren.new()
	io = HenVirtualCNodeIO.new(identity, state)
	flow = HenVirtualCNodeFlow.new(identity)
	references = HenVirtualCNodeReference.new()
	renderer = HenVirtualCNodeRenderer.new(
		state,
		visual,
		identity,
		io,
		flow,
		pool
	)

	identity.cnode_need_update.connect(update)
	io.cnode_need_update.connect(update)
	flow.cnode_need_update.connect(update)
	state.cnode_need_update.connect(update)


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

	var should_hide: bool = state.is_deleted or (not route_info.route_ref or not HenRouter.current_route or route_info.route_ref.id != HenRouter.current_route.id)

	hide()

	if not should_hide:
		check_visibility()


func check_visibility(_rect: Rect2 = HenGlobal.CAM.get_rect()) -> void:
	state.is_showing = _rect.intersects(Rect2(
		visual.position,
		visual.size
	))

	if state.is_showing and cnode_instance == null:
		show()
	elif not state.is_showing:
		hide()


func get_new_input_connection_command(_id: int, _from_id: int, _from: HenVirtualCNode) -> HenVCConnectionReturn:
	return io.create_input_connection(_id, _from_id, self, _from)


func get_flow_input_connection(_id: int) -> HenVCFlowConnectionReturn:
	return flow.get_flow_input_connection_command(_id)

func get_flow_output_connection(_id: int) -> HenVCFlowConnectionReturn:
	return flow.get_flow_output_connection_command(_id)


func select() -> void:
	HenGlobal.SELECTED_VIRTUAL_CNODE.append(self)
	
	if cnode_instance:
		cnode_instance.select()


func unselect() -> void:
	HenGlobal.SELECTED_VIRTUAL_CNODE.erase(self)

	if cnode_instance:
		cnode_instance.unselect()


func on_cnode_mouse_enter() -> void:
	if HenGlobal.can_make_flow_connection and not flow.flow_inputs.is_empty():
		HenGlobal.flow_connection_to_data = {
			to_cnode = self,
			to_id = flow.flow_inputs[0].id
		}

func on_cnode_selected(_selected: bool) -> void:
	if _selected:
		select()
	else:
		unselect()


func on_cnode_hovering(_mouse_pos: Vector2) -> void:
	if state.invalid:
		HenGlobal.TOOLTIP.go_to(_mouse_pos, HenEnums.TOOLTIP_TEXT.CNODE_INVALID)
	else:
		match identity.type:
			HenVirtualCNode.Type.STATE:
				HenGlobal.TOOLTIP.go_to(_mouse_pos, HenEnums.TOOLTIP_TEXT.RIGHT_MOUSE_INSPECT)
			_:
				HenGlobal.TOOLTIP.close()


func on_cnode_double_click() -> void:
	if route_info.route:
		HenRouter.change_route(route_info.route)
	elif references.ref and references.ref.get_ref():
		@warning_ignore('unsafe_method_access')
		if references.ref.get_ref().get('route'):
			@warning_ignore('unsafe_method_access')
			HenRouter.change_route(references.ref.get_ref().get('route'))


func on_cnode_right_click(_mouse_pos: Vector2) -> void:
	# showing state config on doubleclick
	if identity.type == HenVirtualCNode.Type.STATE:
		@warning_ignore('unsafe_method_access')
		HenGlobal.GENERAL_POPUP.get_parent().show_content(
			HenPropEditor.mount(self),
			'Testing',
			_mouse_pos
		)


func on_cnode_changed_position(_pos: Vector2) -> void:
	visual.position = _pos


func get_save(_script_data: HenScriptData) -> Dictionary:
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

	if references.ref and references.ref.get_ref():
		@warning_ignore("UNSAFE_PROPERTY_ACCESS")
		data.ref_id = references.ref.get_ref().id

	if identity.from_side_bar_id > -1:
		data.from_side_bar_id = identity.from_side_bar_id

	if identity.from_id > -1:
		data.from_id = str(identity.from_id)
		_script_data.deps.append(str(identity.from_id))

	if not io.inputs.is_empty():
		data.inputs = []

		for input: HenVCInOutData in io.inputs:
			data.inputs.append(input.get_save())
	
	if not io.outputs.is_empty():
		data.outputs = []

		for output: HenVCInOutData in io.outputs:
			data.outputs.append(output.get_save())

	if identity.category:
		data.category = identity.category


	for flow_connection: HenVCFlowConnectionData in flow.flow_connections_2:
		if not flow_connection.get_to(): continue
		if flow_connection.get_to() == self: continue

		_script_data.flow_connections.append(flow_connection.get_save())


	for input: HenVCConnectionData in io.connections:
		if input.get_to().identity.id != identity.id:
			continue

		_script_data.connections.append(input.get_save())


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


	if not children.virtual_cnode_list.is_empty():
		data.virtual_cnode_list = []

		for v_cnode: HenVirtualCNode in children.virtual_cnode_list:
			data.virtual_cnode_list.append(v_cnode.get_save(_script_data))


	return data


func add_flow_connection(_id: int, _to_id: int, _to: HenVirtualCNode) -> HenVCFlowConnectionReturn:
	return flow.add_flow_connection(_id, _to_id, self, _to)


func add_io(_is_input: bool, _data: Dictionary, _check_types: bool = true) -> HenVCInOutData:
	return io.on_in_out_added(self, _is_input, _data, _check_types)


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


static func instantiate_virtual_cnode(_config: Dictionary) -> HenVirtualCNode:
	# adding virtual cnode to list
	var v_cnode: HenVirtualCNode = HenVirtualCNode.new()
	
	v_cnode.identity.name = _config.name
	v_cnode.identity.type = _config.type as Type if _config.has('type') else Type.DEFAULT
	v_cnode.identity.sub_type = _config.sub_type
	v_cnode.identity.id = HenGlobal.get_new_node_counter() if not _config.has('id') else _config.id
	v_cnode.route_info.route_ref = _config.route
	
	if _config.has('name_to_code'): v_cnode.identity.name_to_code = _config.name_to_code

	match _config.route.type:
		HenRouter.ROUTE_TYPE.BASE:
			(_config.route.get_ref() as HenLoader.BaseRouteRef).virtual_cnode_list.append(v_cnode)
		HenRouter.ROUTE_TYPE.STATE:
			(_config.route.get_ref() as HenVirtualCNode).children.virtual_cnode_list.append(v_cnode)
		HenRouter.ROUTE_TYPE.FUNC:
			var _ref: HenFuncData = _config.route.get_ref()
			_ref.virtual_cnode_list.append(v_cnode)
		
			match v_cnode.identity.sub_type:
				SubType.FUNC_INPUT:
					_ref.input_ref = weakref(v_cnode)
				SubType.FUNC_OUTPUT:
					_ref.output_ref = weakref(v_cnode)
		HenRouter.ROUTE_TYPE.SIGNAL:
			var _ref: HenSignalCallbackData = _config.route.get_ref()
			_ref.virtual_cnode_list.append(v_cnode)
			match v_cnode.identity.sub_type:
				SubType.SIGNAL_ENTER:
					_ref.signal_enter = v_cnode
		HenRouter.ROUTE_TYPE.MACRO:
			var _ref: HenMacroData = _config.route.get_ref()
			_ref.virtual_cnode_list.append(v_cnode)

			match v_cnode.identity.sub_type:
				SubType.MACRO_INPUT:
					_ref.input_ref = weakref(v_cnode)
				SubType.MACRO_OUTPUT:
					_ref.output_ref = weakref(v_cnode)

	
	if _config.has('singleton_class'):
		v_cnode.identity.singleton_class = _config.singleton_class

	if _config.has('can_delete'):
		v_cnode.state.can_delete = _config.can_delete

	if _config.has('from_side_bar_id'):
		v_cnode.identity.from_side_bar_id = _config.from_side_bar_id

	if _config.has('from_id'):
		v_cnode.identity.from_id = int(_config.from_id)

	if _config.has('invalid'):
		v_cnode.state.invalid = _config.invalid

	if _config.has('ref_id'):
		if not v_cnode.state.invalid:
			_config.ref = HenGlobal.SIDE_BAR_LIST_CACHE[int(_config.ref_id)]

	if _config.has('ref'):
		# ref is required to have id to save and load work
		v_cnode.references.ref = weakref(_config.ref)

		if _config.ref.has_signal('name_changed'):
			_config.ref.name_changed.connect(v_cnode.identity.on_change_name)

		if _config.ref.has_signal('in_out_added'):
			_config.ref.in_out_added.connect(v_cnode.add_io)
	

		if _config.ref.has_signal('deleted'):
			_config.ref.deleted.connect(v_cnode.state.on_side_bar_deleted)


		if _config.ref.has_signal('in_out_reseted'):
			_config.ref.in_out_reseted.connect(v_cnode.io.on_in_out_reset.bind(v_cnode))

		if _config.ref.has_signal('flow_added'):
			_config.ref.flow_added.connect(v_cnode.flow.on_flow_added.bind(v_cnode))


	if _config.has('category'):
		v_cnode.identity.category = _config.category

	if _config.has('position'):
		v_cnode.visual.position = _config.position if _config.position is Vector2 else str_to_var(_config.position)

	match v_cnode.identity.sub_type:
		SubType.VIRTUAL:
			(_config.route.get_ref() as HenVirtualCNode).children.virtual_sub_type_vc_list.append(v_cnode)
		SubType.MACRO, SubType.MACRO_INPUT, SubType.MACRO_OUTPUT:
			var _ref: HenMacroData = _config.ref

			_config.from_flow = _ref.inputs.map(func(x: HenMacroData.MacroInOut) -> Dictionary: return x.get_data())
			_config.to_flow = _ref.outputs.map(func(x: HenMacroData.MacroInOut) -> Dictionary: return x.get_data())


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
				weakref(v_cnode)
			)

			HenRouter.line_route_reference[v_cnode.route_info.route.id] = []
			
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