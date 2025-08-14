class_name HenFactoryCNode extends RefCounted


static func get_cnode_from_dict(_cnode: Dictionary, _refs: HenSaveCodeType.References, _parent_ref=null) -> HenSaveCodeType.CNode:
	var cn: HenSaveCodeType.CNode = HenSaveCodeType.CNode.new()

	cn.id = int(_cnode.id)
	cn.name = _cnode.name
	cn.sub_type = int(_cnode.sub_type) as HenVirtualCNode.SubType
	cn.type = int(_cnode.type) as HenVirtualCNode.Type

	_refs.cnode_ref[cn.id] = cn
	
	if _cnode.has(&'singleton_class'):
		cn.singleton_class = _cnode.singleton_class

	if _cnode.has(&'invalid'):
		cn.invalid = _cnode.invalid

	if _cnode.has(&'ref_id'):
		if not cn.invalid:
			cn.ref = _refs.side_bar_item_ref[_cnode.ref_id]

	if _cnode.has(&'category'):
		cn.category = _cnode.category
	
	if _cnode.has(&'name_to_code'):
		cn.name_to_code = _cnode.name_to_code
	
	if _cnode.has('flow_connections'):
		for connection: Dictionary in _cnode.flow_connections:
			var fc: HenSaveCodeType.FlowConnection = HenSaveCodeType.FlowConnection.new()

			fc.from = cn

			fc.from_id = int(connection.from_id)
			fc.to_id = int(connection.to_id)
			fc.to_vc_id = int(connection.to_vc_id)


			_refs.flow_connections.append(fc)

	if _cnode.has('input_connections'):
		for connection: Dictionary in _cnode.input_connections:
			var input_connection: HenSaveCodeType.InputConnection = HenSaveCodeType.InputConnection.new()

			input_connection.from_id = int(connection.from_id)
			input_connection.to_id = int(connection.to_id)
			input_connection.to = cn
			input_connection.from_vc_id = int(connection.from_vc_id)

			_refs.input_connections.append(input_connection)

	if _cnode.has('inputs'):
		for input_data: Dictionary in _cnode.inputs:
			cn.inputs.append(HenFactoryIO.get_inout_from_dict(input_data))

	if _cnode.has('outputs'):
		for input_data: Dictionary in _cnode.outputs:
			cn.outputs.append(HenFactoryIO.get_inout_from_dict(input_data))

	# setting route types
	if _parent_ref:
		if _parent_ref is HenSaveCodeType.CNode and _parent_ref.type == HenVirtualCNode.Type.STATE:
			cn.route_type = HenRouter.ROUTE_TYPE.STATE
		elif _parent_ref is HenSaveCodeType.Func:
			cn.route_type = HenRouter.ROUTE_TYPE.FUNC

			match cn.sub_type:
				HenVirtualCNode.SubType.FUNC_INPUT:
					_parent_ref.input_ref = cn
				HenVirtualCNode.SubType.FUNC_OUTPUT:
					_parent_ref.output_ref = cn
		elif _parent_ref is HenSaveCodeType.SignalData:
			cn.route_type = HenRouter.ROUTE_TYPE.SIGNAL

			if cn.sub_type == HenVirtualCNode.SubType.SIGNAL_ENTER:
				_parent_ref.signal_enter = cn
		elif _parent_ref is HenSaveCodeType.Macro:
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
			if not cn.invalid:
				(cn.ref as HenSaveCodeType.Macro).macro_ref_list.append(cn)
	
	match cn.sub_type:
		HenVirtualCNode.SubType.VIRTUAL:
			if _parent_ref:
				(_parent_ref as HenSaveCodeType.CNode).virtual_sub_type_vc_list.append(cn)

	return cn


#
#
#
#
#
#
static func parse_connections(_refs: HenSaveCodeType.References) -> void:
	# generatin flow connection references
	for connection: HenSaveCodeType.FlowConnection in _refs.flow_connections:
		var cnode: HenSaveCodeType.CNode = _refs.cnode_ref[connection.to_vc_id]
		connection.to = cnode
		connection.from.flow_connections.append(connection)

	# generating input connection references
	for connection: HenSaveCodeType.InputConnection in _refs.input_connections:
		connection.from = _refs.cnode_ref[connection.from_vc_id]
		connection.to.input_connections.append(connection)