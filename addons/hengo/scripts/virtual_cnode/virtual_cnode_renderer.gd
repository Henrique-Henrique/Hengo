@tool
class_name HenVirtualCNodeRenderer extends HenVirtualCNodeIO


func configure_cnode_to_show(_vc: HenVirtualCNode, _cnode: HenCnode) -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	_cnode.position = position
	_cnode.visible = true
	_cnode.category = category
	_cnode.id = id
	_cnode.can_follow = false
	_cnode.set_process(false)
	_cnode.selected = false
	_cnode.moving = false

	var res = _vc.get_res()

	if res:
		_cnode.change_name(res.get(&'name'))
	else:
		_cnode.change_name(name)

	var idx: int = 0

	_cnode.update_title_color(sub_type)

	# sync
	var _inputs: Array[HenVCInOutData] = get_inputs()
	var _outputs: Array[HenVCInOutData] = get_outputs()


	# clearing inputs and change to new
	for input: HenCnodeInOut in _cnode.get_node('%InputContainer').get_children():
		input.visible = false

		if idx < _inputs.size():
			input.visible = true
			
			var input_data: HenVCInOutData = _inputs[idx]

			input.reset_signals(input_data)
			input.change_name(input_data.name)

			input.io_type = input_data.type
			input.sub_type = input_data.sub_type

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

		if idx < _outputs.size():
			output.visible = true
			
			var output_data: HenVCInOutData = _outputs[idx]
			
			output.reset_signals(output_data)
			
			output.change_name(output_data.name)
			output.change_type(
				output_data.type,
				output_data.value if output_data.value else null,
				output_data.sub_type if output_data.sub_type else &''
			)

		idx += 1

	for connection: HenVCConnectionData in global.SAVE_DATA.get_connections_by_id(id):
		var from: HenVirtualCNode = connection.get_from()
		var to: HenVirtualCNode = connection.get_to()

		if not from or not to:
			if not connection.line_ref: continue

			connection.line_ref.visible = false
			connection.line_ref = null
			continue

		var output_arr: Array[HenVCInOutData] = from.get_outputs()
		var input_arr: Array[HenVCInOutData] = to.get_inputs()

		var output_ref: HenVCInOutData = from.get_output(connection.from_id)
		var input_ref: HenVCInOutData = to.get_input(connection.to_id)

		var from_idx: int = output_arr.find(output_ref)
		var to_idx: int = input_arr.find(input_ref)

		if from_idx < 0 or to_idx < 0:
			if not connection.line_ref: continue

			connection.line_ref.visible = false
			connection.line_ref = null
			continue
		
		if is_instance_valid(connection.line_ref) and connection.line_ref is HenConnectionLine:
			connection.line_ref = connection.line_ref
		else:
			connection.line_ref = HenPool.get_line_from_pool()

			if not connection.line_ref:
				continue
		
		connection.line_ref.to_pool_visible = to.is_showing_on_screen()
		connection.line_ref.from_pool_visible = from.is_showing_on_screen()
		connection.line_ref.from = weakref(from)
		connection.line_ref.to = weakref(to)
		connection.line_ref.from_idx = from_idx
		connection.line_ref.to_idx = to_idx

		# drawing inputs
		if connection.line_ref.to_pool_visible:
			var input: HenCnodeInOut = to.cnode_instance.get_node('%InputContainer').get_child(
				to_idx
			)

			connection.line_ref.output = input.get_node('%Connector')
			input.remove_in_prop()
			connection.line_ref.update_colors(connection.from_type, connection.to_type)

			if not to.cnode_instance.is_connected('on_move', connection.line_ref.update_line):
				to.cnode_instance.connect('on_move', connection.line_ref.update_line)


		# drawing outputs
		if connection.line_ref.from_pool_visible:
			var output: HenCnodeInOut = from.cnode_instance.get_node('%OutputContainer').get_child(
				from_idx
			)

			connection.line_ref.input = output.get_node('%Connector')
			connection.line_ref.update_colors(connection.from_type, connection.to_type)

			if not from.cnode_instance.is_connected('on_move', connection.line_ref.update_line):
				from.cnode_instance.connect('on_move', connection.line_ref.update_line)
		
	
	# cleaning from flows
	var from_flow_container: HBoxContainer = _cnode.get_node('%FromFlowContainer')

	for from_flow: HenFromFlow in from_flow_container.get_children():
		(from_flow.get_node('%Arrow') as TextureRect).visible = false
		from_flow.visible = false

	# cleaning flows
	var flow_container: HBoxContainer = _cnode.get_node('%FlowContainer')

	for flow_c: PanelContainer in flow_container.get_children():
		flow_c.visible = false

		(flow_c.get_node('FlowSlot/Label') as Label).visible = false

	# Showing Flows
	match type:
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

	for flow_input: HenVCFlow in flow_inputs:
		# showing from flow connections
		var flow_input_instance: HenFromFlow = from_flow_container.get_child(idx)
		var label: Label = flow_input_instance.get_node('%Label')

		if flow_input.name:
			label.visible = true
			label.text = flow_input.name
		else:
			label.visible = false
		
		flow_input_instance.reset_signals(_vc, flow_input)
		flow_input_instance.id = flow_input.id
		flow_input_instance.visible = true

		var has_connection: bool = flow_input_has_connection(flow_input.id, _cnode.id)
		(from_flow_container.get_child(idx).get_node('%Arrow') as TextureRect).visible = has_connection
		idx += 1

	idx = 0

	
	for flow_output: HenVCFlow in flow_outputs:
		# showing flow connections
		var my_flow_container = flow_container.get_child(idx)
		var connector: HenFlowConnector = my_flow_container.get_node('FlowSlot/Control/Connector')

		connector.reset_signals(_vc, flow_output)
		connector.id = flow_output.id
		connector.owner = _cnode

		if flow_output.name:
			var my_flow_label: Label = (my_flow_container.get_node('FlowSlot/Label') as Label)
			my_flow_label.visible = true
			my_flow_label.text = flow_output.name
		
		my_flow_container.visible = true

		idx += 1

	var flow_connections: Array = global.SAVE_DATA.get_flow_connections_by_id(id)

	for connection: HenVCFlowConnectionData in flow_connections:
		if is_instance_valid(connection.line_ref) and connection.line_ref is HenFlowConnectionLine:
			connection.line_ref = connection.line_ref
		else:
			connection.line_ref = HenPool.get_flow_line_from_pool()

			if not connection.line_ref:
				continue

		var from: HenVirtualCNode = connection.get_from()
		var to: HenVirtualCNode = connection.get_to()

		connection.line_ref.to_pool_visible = to.is_showing_on_screen()
		connection.line_ref.from_pool_visible = from.is_showing_on_screen()
		connection.line_ref.from = weakref(from)
		connection.line_ref.to = weakref(to)
		connection.line_ref.from_idx = from.flow_outputs.find(from.get_flow_output(connection.from_id))
		connection.line_ref.to_idx = to.flow_inputs.find(to.get_flow_input(connection.to_id))

		# drawing inputs
		if connection.line_ref.to_pool_visible:
			var flow_idx = to.flow_inputs.find(to.get_flow_input(connection.to_id))
			connection.line_ref.output = to.cnode_instance.get_node('%FromFlowContainer').get_child(flow_idx).get_node('%Arrow')

			if not to.cnode_instance.is_connected('on_move', connection.line_ref.update_line):
				to.cnode_instance.connect('on_move', connection.line_ref.update_line)

		# drawing outputs
		if connection.line_ref.from_pool_visible:
			var flow_idx = from.flow_outputs.find(from.get_flow_output(connection.from_id))
			connection.line_ref.input = from.cnode_instance.get_node('%FlowContainer').get_child(flow_idx).get_node('FlowSlot/Control/Connector')

			if not from.cnode_instance.is_connected('on_move', connection.line_ref.update_line):
				from.cnode_instance.connect('on_move', connection.line_ref.update_line)


	_cnode.reset_size()
	_cnode.pivot_offset = _cnode.size / 2
	size = _cnode.size

	if invalid:
		_cnode.modulate = Color(1, 1, 1, .3)
	else:
		_cnode.modulate = Color.WHITE

	# drawing the connections	
	await RenderingServer.frame_pre_draw

	for connection: HenVCConnectionData in global.SAVE_DATA.get_connections_by_id(id):
		if not connection.line_ref: continue
		connection.line_ref.update_line()

	for connection: HenVCFlowConnectionData in flow_connections:
		if not connection.line_ref: continue
		connection.line_ref.update_line()


func configure_cnode_to_hide(_cnode: HenCnode) -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	is_showing = false

	_cnode.can_follow = false
	_cnode.set_process(false)


	for signal_data: Dictionary in _cnode.get_signal_connection_list('on_move'):
		_cnode.disconnect('on_move', signal_data.callable as Callable)
	
	# io
	for connection: HenVCConnectionData in global.SAVE_DATA.get_connections_by_id(id):
		if not is_instance_valid(connection.line_ref):
			connection.line_ref = null
			continue
		
		var from: HenVirtualCNode = connection.get_from()
		var to: HenVirtualCNode = connection.get_to()

		connection.line_ref.to_pool_visible = to.is_showing_on_screen()
		connection.line_ref.from_pool_visible = from.is_showing_on_screen()

		# input positions
		if connection.line_ref.from_pool_visible:
			var pos: Vector2 = (Engine.get_singleton(&'Global') as HenGlobal).CAM.get_relative_vec2(connection.line_ref.output.global_position as Vector2) + connection.line_ref.conn_size
			connection.to_old_pos = pos
		else:
			connection.line_ref.last_from_pos = connection.line_ref.points[0] if connection.line_ref.points.size() > 0 else Vector2.ZERO

		# output positions
		if connection.line_ref.to_pool_visible:
			var pos: Vector2 = (Engine.get_singleton(&'Global') as HenGlobal).CAM.get_relative_vec2(connection.line_ref.input.global_position as Vector2) + connection.line_ref.conn_size
			connection.from_old_pos = pos
		else:
			connection.line_ref.last_to_pos = connection.line_ref.points[-1] if connection.line_ref.points.size() > 0 else Vector2.ZERO

		if not connection.line_ref.from_pool_visible and not connection.line_ref.to_pool_visible:
			connection.line_ref.visible = false
			connection.line_ref = null

	# flow
	for connection: HenVCFlowConnectionData in global.SAVE_DATA.get_flow_connections_by_id(id):
		if not is_instance_valid(connection.line_ref):
			connection.line_ref = null
			continue

		var from: HenVirtualCNode = connection.get_from()
		var to: HenVirtualCNode = connection.get_to()

		connection.line_ref.to_pool_visible = to.is_showing_on_screen()
		connection.line_ref.from_pool_visible = from.is_showing_on_screen()

		# input positions
		if connection.line_ref.from_pool_visible:
			var pos: Vector2 = (Engine.get_singleton(&'Global') as HenGlobal).CAM.get_relative_vec2(connection.line_ref.input.global_position as Vector2)
			connection.to_old_pos = pos
		else:
			connection.line_ref.last_from_pos = connection.line_ref.points[0] if connection.line_ref.points.size() > 0 else Vector2.ZERO

		# output positions
		if connection.line_ref.to_pool_visible:
			var pos: Vector2 = (Engine.get_singleton(&'Global') as HenGlobal).CAM.get_relative_vec2(connection.line_ref.output.global_position as Vector2)
			connection.from_old_pos = pos
		else:
			connection.line_ref.last_to_pos = connection.line_ref.points[-1] if connection.line_ref.points.size() > 0 else Vector2.ZERO

		if not connection.line_ref.from_pool_visible and not connection.line_ref.to_pool_visible:
			connection.line_ref.visible = false
			connection.line_ref = null

	_cnode.visible = false
