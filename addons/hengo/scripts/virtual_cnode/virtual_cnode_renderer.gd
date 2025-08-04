class_name HenVirtualCNodeRenderer extends RefCounted

var state: HenVirtualCNodeState
var visual: HenVirtualCNodeVisual
var identity: HenVirtualCNodeIdentity
var io: HenVirtualCNodeIO
var flow: HenVirtualCNodeFlow
var pool: HenPool

func _init(
	_state: HenVirtualCNodeState,
	_visual: HenVirtualCNodeVisual,
	_identity: HenVirtualCNodeIdentity,
	_io: HenVirtualCNodeIO,
	_flow: HenVirtualCNodeFlow,
	_pool: HenPool
) -> void:
	state = _state
	visual = _visual
	identity = _identity
	io = _io
	flow = _flow
	pool = _pool


func configure_cnode_to_show(_cnode: HenCnode) -> void:
	_cnode.position = visual.position
	_cnode.visible = true
	_cnode.change_name(identity.name)
	_cnode.category = identity.category

	var idx: int = 0

	# clearing inputs and change to new
	for input: HenCnodeInOut in _cnode.get_node('%InputContainer').get_children():
		input.visible = false

		if idx < io.inputs.size():
			input.visible = true
			
			var input_data: HenVCInOutData = io.inputs[idx]

			input.change_name(input_data.name)
			input.input_ref = input_data
			
			if input_data.type:
				if input_data.is_prop:
					input.reset_in_props()
					input.add_prop_ref(input_data.value if input_data.value else null, 0)
				else:
					input.change_type(
						input_data.type, input_data.value if input_data.value else null,
						'',
						not input_data.is_static
					)
			else:
				input.reset_in_props()
				input.set_in_prop(input_data.value if input_data.value else null, not input_data.is_static)
				input.root.reset_size()
			
			if input_data.is_static:
				(input.get_node('%CNameInput') as HBoxContainer).set('theme_override_constants/separation', 0)
				(input.get_node('%Connector') as TextureRect).visible = false
			else:
				(input.get_node('%CNameInput') as HBoxContainer).set('theme_override_constants/separation', 8)
				(input.get_node('%Connector') as TextureRect).visible = true

		idx += 1

	idx = 0

	# clearing outputs and change to new
	for output: HenCnodeInOut in _cnode.get_node('%OutputContainer').get_children():
		output.visible = false

		if idx < io.outputs.size():
			output.visible = true
			
			var output_data: HenVCInOutData = io.outputs[idx]
			
			output.input_ref = output_data

			output.change_name(output_data.name)
			output.change_type(
				output_data.type,
				output_data.value if output_data.value else null,
				output_data.sub_type if output_data.sub_type else &''
			)

		idx += 1
	
	for connection: HenVCConnectionData in io.connections:
		if connection.line_ref is HenConnectionLine:
			connection.line_ref = connection.line_ref
		else:
			connection.line_ref = pool.get_line_from_pool()

			if not connection.line_ref:
				continue

		connection.line_ref.to_pool_visible = connection.to.state.is_showing
		connection.line_ref.from_pool_visible = connection.from.state.is_showing

		# drawing inputs
		if connection.line_ref.to_pool_visible:
			var input: HenCnodeInOut = connection.to.cnode_instance.get_node('%InputContainer').get_child(
				connection.to.io.inputs.find(connection.to.io.get_input(connection.to_id))
			)

			connection.line_ref.to_cnode = connection.to.cnode_instance
			connection.line_ref.output = input.get_node('%Connector')

			input.remove_in_prop()

			# connection.line_ref.conn_size = (input.get_node('%Connector') as TextureRect).size / 2
			connection.line_ref.update_colors(connection.from_type, connection.to_type)

			if not connection.to.cnode_instance.is_connected('on_move', connection.line_ref.update_line):
				connection.to.cnode_instance.connect('on_move', connection.line_ref.update_line)


		# drawing outputs
		if connection.line_ref.from_pool_visible:
			var output: HenCnodeInOut = connection.from.cnode_instance.get_node('%OutputContainer').get_child(
				connection.from.io.outputs.find(connection.from.io.get_output(connection.from_id))
			)

			connection.line_ref.from_cnode = connection.from.cnode_instance
			connection.line_ref.input = output.get_node('%Connector')

			connection.line_ref.update_colors(connection.from_type, connection.to_type)

			if not connection.from.cnode_instance.is_connected('on_move', connection.line_ref.update_line):
				connection.from.cnode_instance.connect('on_move', connection.line_ref.update_line)
		
	
	# cleaning from flows
	var from_flow_container: HBoxContainer = _cnode.get_node('%FromFlowContainer')

	for from_flow: HenFromFlow in from_flow_container.get_children():
		(from_flow.get_node('%Arrow') as TextureRect).visible = false
		from_flow.visible = false

	# cleaning flows
	var flow_container: HBoxContainer = _cnode.get_node('%FlowContainer')

	for flow_c: PanelContainer in flow_container.get_children():
		var connector: HenFlowConnector = flow_c.get_node('FlowSlot/Control/Connector')

		connector.root = _cnode
		flow_c.visible = false
		(flow_c.get_node('FlowSlot/Label') as Label).visible = false

	# Showing Flows
	match identity.type:
		HenVirtualCNode.Type.DEFAULT:
			var container = flow_container.get_child(0)
			var label: Label = container.get_node('FlowSlot/Label')
			
			container.visible = true
			(from_flow_container.get_child(0) as HenFromFlow).visible = true

			label.visible = false
			label.text = ''
		HenVirtualCNode.Type.IF:
			(from_flow_container.get_child(0) as HenFromFlow).visible = true
		HenVirtualCNode.Type.STATE:
			(from_flow_container.get_child(0) as HenFromFlow).visible = true
			
	idx = 0

	for from_flow_connection: HenVCFromFlowConnectionData in flow.from_flow_connections:
		# showing from flow connections
		var my_from_flow_container = from_flow_container.get_child(idx)
		var label: Label = my_from_flow_container.get_node('%Label')

		if from_flow_connection.name:
			label.visible = true
			label.text = from_flow_connection.name
		else:
			label.visible = false

		my_from_flow_container.id = from_flow_connection.id
		my_from_flow_container.visible = true

		if from_flow_connection.from_connections.is_empty():
			idx += 1
			continue

		for from_connection: HenVCFlowConnectionData in from_flow_connection.from_connections:
			var line: HenFlowConnectionLine

			if from_connection.line_ref:
				line = from_connection.line_ref
			else:
				line = pool.get_flow_line_from_pool()
				from_connection.line_ref = line

			# signal to update flow connection line
			if not _cnode.is_connected('on_move', line.update_line):
				_cnode.connect('on_move', line.update_line)

			line.from_flow_idx = idx
			line.to_cnode = _cnode
			line.from_virtual_pos = from_connection.from_pos
			line.to_pool_visible = true

		(from_flow_container.get_child(idx).get_node('%Arrow') as TextureRect).visible = true

		idx += 1

	idx = 0

	for flow_connection: HenVCFlowConnectionData in flow.flow_connections:
		# showing flow connections
		var my_flow_container = flow_container.get_child(idx)
		var connector: HenFlowConnector = my_flow_container.get_node('FlowSlot/Control/Connector')

		connector.id = flow_connection.id

		if flow_connection.name:
			var my_flow_label: Label = (my_flow_container.get_node('FlowSlot/Label') as Label)
			my_flow_label.visible = true
			my_flow_label.text = flow_connection.name
		
		
		my_flow_container.visible = true


		if not flow_connection.to or not flow_connection.to.get_ref():
			idx += 1
			continue
		
		var line: HenFlowConnectionLine


		if flow_connection.line_ref:
			line = flow_connection.line_ref
		else:
			line = pool.get_flow_line_from_pool()
			flow_connection.line_ref = line
		
		# signal to update flow connection line
		if not _cnode.is_connected('on_move', line.update_line):
			_cnode.connect('on_move', line.update_line)

		line.from_connector = _cnode.get_node('%FlowContainer').get_child(idx).get_node('FlowSlot/Control/Connector')
		line.to_virtual_pos = flow_connection.to_pos
		line.from_pool_visible = true

		idx += 1

	_cnode.reset_size()
	_cnode.pivot_offset = _cnode.size / 2
	visual.size = _cnode.size

	if state.invalid:
		_cnode.modulate = Color(1, 1, 1, .3)
	else:
		_cnode.modulate = Color.WHITE

	# drawing the connections	
	await RenderingServer.frame_pre_draw

	for connection: HenVCConnectionData in io.connections:
		if not connection.line_ref: continue
		connection.line_ref.update_line()

	for connection: HenVCFlowConnectionData in flow.flow_connections:
		if not connection.line_ref: continue
		connection.line_ref.update_line()

	for connection: HenVCFromFlowConnectionData in flow.from_flow_connections:
		if not connection.from_connections.is_empty():
			for from_connection: HenVCFlowConnectionData in connection.from_connections:
				if from_connection.line_ref:
					from_connection.line_ref.update_line()


func configure_cnode_to_hide(_cnode: HenCnode) -> void:
	state.is_showing = false

	for signal_data: Dictionary in _cnode.get_signal_connection_list('on_move'):
		_cnode.disconnect('on_move', signal_data.callable as Callable)
	
	for connection: HenVCConnectionData in io.connections:
		if not connection.line_ref:
			continue
		
		connection.line_ref.to_pool_visible = connection.to.state.is_showing
		connection.line_ref.from_pool_visible = connection.from.state.is_showing

		# input positions
		if connection.from.state.is_showing:
			var pos: Vector2 = HenGlobal.CAM.get_relative_vec2(connection.line_ref.output.global_position as Vector2) + connection.line_ref.conn_size
			connection.to_old_pos = pos
		else:
			connection.line_ref.last_from_pos = connection.line_ref.points[0]

		# output positions
		if connection.to.state.is_showing:
			var pos: Vector2 = HenGlobal.CAM.get_relative_vec2(connection.line_ref.input.global_position as Vector2) + connection.line_ref.conn_size
			connection.from_old_pos = pos
		else:
			connection.line_ref.last_to_pos = connection.line_ref.points[-1]

		if not connection.from.state.is_showing and not connection.to.state.is_showing:
			connection.line_ref.visible = false
			connection.line_ref = null


	for flow_connection: HenVCFlowConnectionData in flow.flow_connections:
		if flow_connection.line_ref:
			flow_connection.line_ref.from_pool_visible = false
		
			if (flow_connection.to.get_ref() as HenVirtualCNode).state.is_showing:
				var pos: Vector2 = HenGlobal.CAM.get_relative_vec2(flow_connection.line_ref.from_connector.global_position) + flow_connection.line_ref.from_connector.size / 2
				flow_connection.from_pos = pos
				flow_connection.line_ref.from_virtual_pos = pos
			else:
				flow_connection.line_ref.visible = false
				flow_connection.line_ref = null

	var idx: int = 0
	var from_flow_container: HBoxContainer = _cnode.get_node('%FromFlowContainer')

	for from_flow_connection: HenVCFromFlowConnectionData in flow.from_flow_connections:
		for from_connection: HenVCFlowConnectionData in from_flow_connection.from_connections:
			if from_connection.line_ref:
				var line: HenFlowConnectionLine = from_connection.line_ref

				if line:
					line.to_pool_visible = false

					if (from_connection.from.get_ref() as HenVirtualCNode).state.is_showing:
						var pos: Vector2 = HenGlobal.CAM.get_relative_vec2((from_flow_container.get_child(idx) as HenFromFlow).global_position)
						from_connection.to_pos = pos
						line.to_virtual_pos = pos
					else:
						line.visible = false
						from_connection.line_ref = null
			
		idx += 1

	_cnode.visible = false
