class_name HenFactoryCNode extends RefCounted


static func get_cnode_from_dict(_cnode: Dictionary, _refs: HenTypeReferences, _parent_ref=null) -> HenTypeCnode:
	var cn: HenTypeCnode = HenTypeCnode.new();
	var input_code_value_map: Dictionary = _cnode.get(&'input_code_value_map', {})

	cn.id = int(_cnode.id)
	cn.name = _cnode.name
	cn.sub_type = int(_cnode.sub_type) as HenVirtualCNode.SubType
	cn.type = int(_cnode.type) as HenVirtualCNode.Type

	_refs.cnode_ref[cn.id] = cn
	
	if _cnode.has(&'singleton_class'):
		cn.singleton_class = _cnode.singleton_class

	if _cnode.has(&'invalid'):
		cn.invalid = _cnode.invalid

	if _cnode.has(&'category'):
		cn.category = _cnode.category
	
	if _cnode.has(&'name_to_code'):
		cn.name_to_code = _cnode.name_to_code

	if _cnode.has('res'):
		cn.res = _cnode.get('res')

		if cn.res is HenSaveResType:
			var res: HenSaveResType = cn.res

			cn.name = res.name

			for input_data: Dictionary in res.get_inputs(cn.sub_type):
				cn.inputs.append(HenFactoryIO.get_inout_from_dict(true, input_data, input_code_value_map.get(input_data.id, {})))
			
			for output_data: Dictionary in res.get_outputs(cn.sub_type):
				cn.outputs.append(HenFactoryIO.get_inout_from_dict(false, output_data))
	else:
		if _cnode.has('inputs'):
			for input_data: Dictionary in _cnode.inputs:
				cn.inputs.append(HenFactoryIO.get_inout_from_dict(true, input_data, input_code_value_map.get(input_data.id, {})))

		if _cnode.has('outputs'):
			for output_data: Dictionary in _cnode.outputs:
				cn.outputs.append(HenFactoryIO.get_inout_from_dict(false, output_data))
			
	# setting route types
	if _parent_ref:
		if (_parent_ref is HenTypeCnode and _parent_ref.type == HenVirtualCNode.Type.STATE) \
		or \
		(_parent_ref is HenVirtualCNode and (_parent_ref as HenVirtualCNode).identity.type == HenVirtualCNode.Type.STATE):
			cn.route_type = HenRouter.ROUTE_TYPE.STATE
		elif _parent_ref is HenTypeFunc:
			cn.route_type = HenRouter.ROUTE_TYPE.FUNC

			match cn.sub_type:
				HenVirtualCNode.SubType.FUNC_INPUT:
					_parent_ref.input_ref = cn
				HenVirtualCNode.SubType.FUNC_OUTPUT:
					_parent_ref.output_ref = cn
		elif _parent_ref is HenTypeSignalCallbackData:
			cn.route_type = HenRouter.ROUTE_TYPE.SIGNAL

			if cn.sub_type == HenVirtualCNode.SubType.SIGNAL_ENTER:
				_parent_ref.signal_enter = cn
		elif _parent_ref is HenTypeMacro:
			cn.route_type = HenRouter.ROUTE_TYPE.MACRO

			if cn.sub_type == HenVirtualCNode.SubType.MACRO_INPUT:
				_parent_ref.input_ref = cn

			if cn.sub_type == HenVirtualCNode.SubType.MACRO_OUTPUT:
				_parent_ref.output_ref = cn

	match cn.type:
		HenVirtualCNode.Type.STATE:
			cn.route_type = HenRouter.ROUTE_TYPE.BASE
			_refs.states.append(cn)
		HenVirtualCNode.Type.MACRO:
			pass
			# if not cn.invalid:
			# 	(cn.ref.get_ref() as HenTypeMacro).macro_ref_list.append(cn)
	
	match cn.sub_type:
		HenVirtualCNode.SubType.VIRTUAL:
			if _parent_ref:
				(_parent_ref as HenTypeCnode).virtual_sub_type_vc_list.append(cn)

	return cn

#
#
#
#
#
#
static func parse_connections(_refs: HenTypeReferences) -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')

	print('- >>>>>>>>>>>>>>>>> ', global.SAVE_DATA)

	# generatin flow connection references
	# for flow_connection_data: HenVCFlowConnectionData in global.SAVE_DATA.get_all_flow_connections():
	# 	var flow_connection: HenTypeFlowConnection = HenTypeFlowConnection.new(flow_connection_data, _refs)
	# 	flow_connection.get_from().flow_connections.append(flow_connection)


	# generating input connection references
	# for connection: Dictionary in global.SAVE_DATA.connections:
	# 	var input: HenTypeInputConnection = HenTypeInputConnection.new(connection, _refs)
	# 	input.get_to().input_connections.append(input)