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


func _init() -> void:
	state = HenVirtualCNodeState.new(self)
	identity = HenVirtualCNodeIdentity.new(self)
	visual = HenVirtualCNodeVisual.new(self)
	route_info = HenVirtualCNodeRoute.new()
	children = HenVirtualCNodeChildren.new()
	io = HenVirtualCNodeIO.new(self)
	flow = HenVirtualCNodeFlow.new(self)
	references = HenVirtualCNodeReference.new()
	renderer = HenVirtualCNodeRenderer.new(self)


func get_save() -> Dictionary:
	var data: Dictionary = {
		id = identity.id,
		type = identity.type,
		sub_type = identity.sub_type,
		name = identity.name,
		position = var_to_str(visual.position),
		size = var_to_str(visual.size),
		input_connections = [],
		output_connections = [],
		flow_connections = []
	}

	if not state.can_delete:
		data.can_delete = false

	if identity.name_to_code:
		data.name_to_code = identity.name_to_code

	if identity.singleton_class:
		data.singleton_class = identity.singleton_class

	if state.invalid:
		data.invalid = state.invalid

	if references.ref:
		@warning_ignore("UNSAFE_PROPERTY_ACCESS")
		data.ref_id = references.ref.id

	if identity.from_side_bar_id > -1:
		data.from_side_bar_id = identity.from_side_bar_id

	if identity.from_id > -1:
		data.from_id = identity.from_id

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

	for flow_connection: HenVCFlowConnectionData in flow.flow_connections:
		if not flow_connection.to or not flow_connection.to.get_ref(): continue
		data.flow_connections.append(flow_connection.get_save())

	for input: HenVCConnectionData.InputConnectionData in io.input_connections:
		data.input_connections.append(input.get_save())

	if not children.virtual_cnode_list.is_empty():
		data.virtual_cnode_list = []

		for v_cnode: HenVirtualCNode in children.virtual_cnode_list:
			data.virtual_cnode_list.append(v_cnode.get_save())
	
	# these types don't need to save the flow connections, are hengo's native
	match identity.type:
		HenVirtualCNode.Type.DEFAULT:
			var flows: Array = []

			for flow_connection: HenVCFlowConnectionData in flow.flow_connections:
				if flow_connection.name:
					flows.append({id = flow_connection.id, name = flow_connection.name})
			
			if not flows.is_empty(): data.to_flow = flows
		HenVirtualCNode.Type.STATE:
			data.to_flow = []
			for flow_connection: HenVCFlowConnectionData in flow.flow_connections:
					if flow_connection.name:
						data.to_flow.append({name = flow_connection.name, id = flow_connection.id})


	if identity.from_id > -1:
		HenEnums.add_script_ref_cache(identity.from_id, HenGlobal.script_config.id)

	return data


func get_history_obj() -> HenVCNodeReturn:
	return HenVCNodeReturn.new(self)


func get_inspector_array_list() -> Array:
	match identity.sub_type:
		SubType.STATE:
			return [
				HenPropEditor.Prop.new({
					name = 'Name',
					type = HenPropEditor.Prop.Type.STRING,
					default_value = identity.name,
					on_value_changed = identity.on_change_name
				}),
				HenPropEditor.Prop.new({
					name = 'Outputs',
					type = HenPropEditor.Prop.Type.ARRAY,
					on_item_create = flow.create_flow_connection,
					prop_list = flow.flow_connections.map(func(x: HenVCFlowConnectionData) -> HenPropEditor.Prop: return HenPropEditor.Prop.new({
						name = 'name',
						type = HenPropEditor.Prop.Type.STRING,
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
			(_config.route.ref as HenLoader.BaseRouteRef).virtual_cnode_list.append(v_cnode)
		HenRouter.ROUTE_TYPE.STATE:
			(_config.route.ref as HenVirtualCNode).children.virtual_cnode_list.append(v_cnode)
		HenRouter.ROUTE_TYPE.FUNC:
			var _ref: HenFuncData = _config.route.ref
			
			_ref.virtual_cnode_list.append(v_cnode)

			# match v_cnode.identity.sub_type:
			# 	SubType.FUNC_INPUT:
			# 		_ref.input_ref = weakref(v_cnode)
			# 	SubType.FUNC_OUTPUT:
			# 		_ref.output_ref = weakref(v_cnode)
		HenRouter.ROUTE_TYPE.SIGNAL:
			var _ref: HenSignalData = _config.route.ref
			
			_ref.virtual_cnode_list.append(v_cnode)

			match v_cnode.identity.sub_type:
				SubType.SIGNAL_ENTER:
					_ref.signal_enter = v_cnode
		HenRouter.ROUTE_TYPE.MACRO:
			var _ref: HenMacroData = _config.route.ref
			
			_ref.virtual_cnode_list.append(v_cnode)

			# match v_cnode.identity.sub_type:
			# 	SubType.MACRO_INPUT:
			# 		_ref.input_ref = weakref(v_cnode)
			# 	SubType.MACRO_OUTPUT:
			# 		_ref.output_ref = weakref(v_cnode)

	
	if _config.has('singleton_class'):
		v_cnode.identity.singleton_class = _config.singleton_class

	if _config.has('can_delete'):
		v_cnode.state.can_delete = _config.can_delete

	if _config.has('from_side_bar_id'):
		v_cnode.identity.from_side_bar_id = _config.from_side_bar_id

	if _config.has('from_id'):
		v_cnode.identity.from_id = _config.from_id

	if _config.has('invalid'):
		v_cnode.state.invalid = _config.invalid

	if _config.has('ref_id'):
		if not v_cnode.state.invalid:
			_config.ref = HenGlobal.SIDE_BAR_LIST_CACHE[int(_config.ref_id)]

	if _config.has('ref'):
		# ref is required to have id to save and load work
		v_cnode.references.ref = _config.ref

		if _config.ref.has_signal('name_changed'):
			_config.ref.name_changed.connect(v_cnode.identity.on_change_name)

		if _config.ref.has_signal('in_out_added'):
			_config.ref.in_out_added.connect(v_cnode.io.on_in_out_added)
	

		if _config.ref.has_signal('deleted'):
			_config.ref.deleted.connect(v_cnode.state.on_side_bar_deleted)


		if _config.ref.has_signal('in_out_reseted'):
			_config.ref.in_out_reseted.connect(v_cnode.io.on_in_out_reset)

		if _config.ref.has_signal('flow_added'):
			_config.ref.flow_added.connect(v_cnode.flow.on_flow_added)


	if _config.has('category'):
		v_cnode.identity.category = _config.category

	if _config.has('position'):
		v_cnode.visual.position = _config.position if _config.position is Vector2 else str_to_var(_config.position)

	match v_cnode.identity.sub_type:
		SubType.VIRTUAL:
			_config.route.ref.children.virtual_sub_type_vc_list.append(v_cnode)
		SubType.MACRO, SubType.MACRO_INPUT, SubType.MACRO_OUTPUT:
			var _ref: HenMacroData = _config.ref

			_config.from_flow = _ref.inputs.map(func(x: HenMacroData.MacroInOut) -> Dictionary: return x.get_data())
			_config.to_flow = _ref.outputs.map(func(x: HenMacroData.MacroInOut) -> Dictionary: return x.get_data())


	match v_cnode.identity.type:
		HenVirtualCNode.Type.DEFAULT:
			if not _config.has('to_flow'): v_cnode.flow.flow_connections.append(HenVCFlowConnectionData.new({id = 0}))
			v_cnode.flow.from_flow_connections.append(HenVCFromFlowConnectionData.new({id = 0}))
		Type.IF:
			v_cnode.flow.flow_connections.append(HenVCFlowConnectionData.new({name = 'True', id = 0}))
			v_cnode.flow.flow_connections.append(HenVCFlowConnectionData.new({name = 'False', id = 1}))
			v_cnode.flow.flow_connections.append(HenVCFlowConnectionData.new({name = 'Then', id = 2}))
			v_cnode.flow.from_flow_connections.append(HenVCFromFlowConnectionData.new({id = 0}))
		Type.FOR:
			v_cnode.flow.flow_connections.append(HenVCFlowConnectionData.new({name = 'Body', id = 0}))
			v_cnode.flow.flow_connections.append(HenVCFlowConnectionData.new({name = 'Then', id = 1}))
			v_cnode.flow.from_flow_connections.append(HenVCFromFlowConnectionData.new({id = 0}))
		Type.STATE:
			v_cnode.route_info.route = {
				name = v_cnode.identity.name,
				type = HenRouter.ROUTE_TYPE.STATE,
				id = HenUtilsName.get_unique_name(),
				ref = v_cnode
			}

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

			v_cnode.flow.from_flow_connections.append(HenVCFromFlowConnectionData.new({id = 0}))

			if _config.has('to_flow'):
				for flow: Dictionary in _config.to_flow:
					v_cnode.flow.on_flow_added(false, flow)
		Type.STATE_START:
			v_cnode.flow.flow_connections.append(HenVCFlowConnectionData.new({name = 'On Start', id = 0}))
			v_cnode.flow.from_flow_connections.append(HenVCFromFlowConnectionData.new({id = 0}))
		Type.STATE_EVENT:
			v_cnode.flow.flow_connections.append(HenVCFlowConnectionData.new({id = 0}))
		_:
			if _config.has('to_flow'):
				for flow: Dictionary in _config.to_flow:
					v_cnode.flow.on_flow_added(false, flow)

			if _config.has('from_flow'):
				for flow: Dictionary in _config.from_flow:
					v_cnode.flow.on_flow_added(true, flow)

	if _config.has('inputs'):
		for input_data: Dictionary in _config.inputs:
			var input: HenVCInOutData = v_cnode.io.on_in_out_added(true, input_data, false)

			if not input_data.has('code_value'):
				input.reset_input_value()


	if _config.has('outputs'):
		for output_data: Dictionary in _config.outputs:
			v_cnode.io.on_in_out_added(false, output_data, false)

	return v_cnode


static func instantiate_virtual_cnode_and_add(_config: Dictionary) -> HenVirtualCNode:
	var v_cnode: HenVirtualCNode = instantiate_virtual_cnode(_config)
	v_cnode.update()
	return v_cnode


static func instantiate(_config: Dictionary) -> HenVCNodeReturn:
	var v_cnode: HenVirtualCNode = instantiate_virtual_cnode(_config)
	return HenVCNodeReturn.new(v_cnode)


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		print('DELETED -> ', identity.name)
	

func clean() -> void:
	pass
	# for chd in virtual_cnode_list:
	# 	chd.clean()

	# for chd in virtual_sub_type_vc_list:
	# 	chd.clean()

	# if route and route.has('ref'):
	# 	route.ref = null

	# for input: HenVCInOutData in inputs:
	# 	if input.ref: input.ref.clean()
	# 	input.ref = null

	# for output: HenVCInOutData in outputs:
	# 	if output.ref: output.ref.clean()
	# 	output.ref = null

	# for flow: HenVCFlowConnectionData in flow_connections:
	# 	flow.from = null
	# 	flow.to = null
	# 	flow.to_from_ref = null
	# 	flow.ref = null

	# for flow: HenVCFromFlowConnectionData in from_flow_connections:
	# 	flow.ref = null

	# 	for connection: HenVCFlowConnectionData in flow.from_connections:
	# 		connection.from = null
	# 		connection.to = null
	# 		connection.to_from_ref = null
	# 		connection.ref = null

	# 	flow.from_connections.clear()

	# if is_instance_valid(ref):
	# 	if ref.has_signal('name_changed'):
	# 		for connection_data: Dictionary in ref.get_signal_connection_list('name_changed'):
	# 			(ref as Variant).name_changed.disconnect(connection_data.callable)

	# 	if ref.has_signal('in_out_added'):
	# 		for connection_data: Dictionary in ref.get_signal_connection_list('in_out_added'):
	# 			(ref as Variant).in_out_added.disconnect(connection_data.callable)

	# 	if ref.has_signal('deleted'):
	# 		for connection_data: Dictionary in ref.get_signal_connection_list('deleted'):
	# 			(ref as Variant).deleted.disconnect(connection_data.callable)

	# 	if ref.has_signal('in_out_reseted'):
	# 		for connection_data: Dictionary in ref.get_signal_connection_list('in_out_reseted'):
	# 			(ref as Variant).in_out_reseted.disconnect(connection_data.callable)

	# 	if ref.has_signal('flow_added'):
	# 		for connection_data: Dictionary in ref.get_signal_connection_list('flow_added'):
	# 			(ref as Variant).flow_added.disconnect(connection_data.callable)


	# for input: HenVCConnectionData.InputConnectionData in input_connections:
	# 	input.from = null
	# 	input.from_ref = null
	# 	input.input_ref = null

	# for output: HenVCConnectionData.OutputConnectionData in output_connections:
	# 	output.to = null
	# 	output.to_ref = null
	# 	output.output_ref = null

	# inputs.clear()
	# outputs.clear()
	# flow_connections.clear()
	# from_flow_connections.clear()
	# input_connections.clear()
	# output_connections.clear()
	# virtual_cnode_list.clear()
	# virtual_sub_type_vc_list.clear()