@tool
@abstract
class_name HenVirtualCNodeRenderer extends HenVirtualCNodeIO


func configure_cnode_to_show(_vc: HenVirtualCNode, _cnode: HenCnode) -> void:
	# configures the cnode visual state, connections, and flows
	var global: HenGlobal = Engine.get_singleton(&'Global')
	_cnode.position = position
	_cnode.visible = true
	_cnode.category = category
	_cnode.id = id
	_cnode.can_follow = false
	_cnode.set_process(false)

	if _vc.selected:
		_cnode.select()
	else:
		_cnode.unselect(0)
		
	_cnode.moving = false

	_cnode.change_name(_vc.get_vc_name(global.SAVE_DATA))

	var idx: int = 0

	_cnode.update_title_color(sub_type)

	# sync
	var _inputs: Array[HenVCInOutData] = get_inputs(global.SAVE_DATA)
	var _outputs: Array[HenVCInOutData] = get_outputs(global.SAVE_DATA)


	# cleaning and configuring rows
	var center_container: VBoxContainer = _cnode.get_node('%CenterContainer')
	var row_idx: int = 0
	
	var input_idx: int = 0
	var output_idx: int = 0
	
	for panel in center_container.get_children():
		var row = panel.get_child(0)
		var input_node = row.get_node_or_null('Input')
		var output_node = row.get_node_or_null('Output')
		
		var is_row_visible: bool = false
		
		# INPUT
		if input_node:
			if input_idx < _inputs.size():
				input_node.visible = true
				is_row_visible = true
				
				var input_inst: HenCnodeInOut = input_node as HenCnodeInOut
				input_inst.set_connected_color(Color.TRANSPARENT)

				var input_data: HenVCInOutData = _inputs[input_idx]
				
				input_inst.reset_signals(input_data)
				input_inst.change_name(input_data.name)
				
				input_inst.io_type = input_data.type
				input_inst.sub_type = input_data.sub_type
				
				if input_data.type:
					if input_data.is_prop:
						input_inst.reset_in_props()
						input_inst.add_prop_ref(input_data.value if input_data.value else null, 0)
					else:
						var default_value
						
						if _vc.sub_type == HenVirtualCNode.SubType.MAKE_TRANSITION:
							var res: HenSaveState = input_data.get_res(global.SAVE_DATA)
							
							if res:
								if res.flow_outputs.size() > 0:
									default_value = res.flow_outputs[0].name
								else:
									default_value = 'INVALID'
						
						input_inst.change_type(
							input_data.type, input_data.value if input_data.value else default_value,
							'',
							not input_data.is_static
						)
				else:
					input_inst.reset_in_props()
					input_inst.set_in_prop(input_data.value if input_data.value else null, not input_data.is_static)
					input_inst.root.reset_size()
				
				if input_data.is_static:
					(input_inst.get_node('%CNameInput') as HBoxContainer).set('theme_override_constants/separation', 0)
					(input_inst.get_node('%Connector') as TextureRect).visible = false
				else:
					(input_inst.get_node('%CNameInput') as HBoxContainer).set('theme_override_constants/separation', 8)
					(input_inst.get_node('%Connector') as TextureRect).visible = true
				
				input_idx += 1
			else:
				input_node.visible = false
				
		# OUTPUT
		if output_node:
			if output_idx < _outputs.size():
				output_node.visible = true
				is_row_visible = true
				
				var output_inst: HenCnodeInOut = output_node as HenCnodeInOut
				output_inst.set_connected_color(Color.TRANSPARENT)

				var output_data: HenVCInOutData = _outputs[output_idx]
				
				output_inst.reset_signals(output_data)
				
				output_inst.change_name(output_data.name)
				output_inst.change_type(
					output_data.type,
					output_data.value if output_data.value else null,
					output_data.sub_type if output_data.sub_type else &''
				)
				
				output_idx += 1
			else:
				output_node.visible = false

		panel.visible = is_row_visible

		if is_row_visible:
			var style: StyleBoxFlat = panel.get_theme_stylebox('panel')
			if row_idx % 2 != 0:
				style.bg_color = Color(0, 0, 0, 0.2)
			else:
				style.bg_color = Color.TRANSPARENT
			
			row_idx += 1

	for connection: HenVCConnectionData in global.SAVE_DATA.get_connections_by_id(id):
		var from: HenVirtualCNode = connection.get_from(global.SAVE_DATA)
		var to: HenVirtualCNode = connection.get_to(global.SAVE_DATA)

		if not from or not to:
			if not connection.line_ref: continue

			connection.line_ref.visible = false
			connection.line_ref = null
			continue

		var output_arr: Array[HenVCInOutData] = from.get_outputs(global.SAVE_DATA)
		var input_arr: Array[HenVCInOutData] = to.get_inputs(global.SAVE_DATA)

		var output_ref: HenVCInOutData = from.get_output(connection.from_id, global.SAVE_DATA)
		var input_ref: HenVCInOutData = to.get_input(connection.to_id, global.SAVE_DATA)

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
		
		connection.line_ref.points = []
		
		connection.line_ref.to_pool_visible = to.is_showing_on_screen()
		connection.line_ref.from_pool_visible = from.is_showing_on_screen()
		connection.line_ref.from = weakref(from)
		connection.line_ref.to = weakref(to)
		connection.line_ref.from_idx = from_idx
		connection.line_ref.to_idx = to_idx

		# drawing inputs
		if connection.line_ref.to_pool_visible:
			var panel = to.cnode_instance.get_node('%CenterContainer').get_child(to_idx)
			var input: HenCnodeInOut = panel.get_child(0).get_node('Input')

			connection.line_ref.output = input.get_node('%Connector')
			input.remove_in_prop()

			var input_color: Color = HenUtils.get_type_parent_color(connection.to_type, 0.2)
			input.set_connected_color(input_color)

			connection.line_ref.update_colors(connection.from_type, connection.to_type)

			if not to.cnode_instance.is_connected('on_move', connection.line_ref.update_line):
				to.cnode_instance.connect('on_move', connection.line_ref.update_line)


		# drawing outputs
		if connection.line_ref.from_pool_visible:
			var panel = from.cnode_instance.get_node('%CenterContainer').get_child(from_idx)
			var output: HenCnodeInOut = panel.get_child(0).get_node('Output')

			connection.line_ref.input = output.get_node('%Connector')
			connection.line_ref.update_colors(connection.from_type, connection.to_type)
			
			var output_color: Color = HenUtils.get_type_parent_color(connection.from_type, 0.2)
			output.set_connected_color(output_color)

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

	for flow_input: HenVCFlow in get_flow_inputs(global.SAVE_DATA):
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

	
	for flow_output: HenVCFlow in get_flow_outputs(global.SAVE_DATA):
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
		
		connection.line_ref.points = []

		var from: HenVirtualCNode = connection.get_from(global.SAVE_DATA)
		var to: HenVirtualCNode = connection.get_to(global.SAVE_DATA)

		if not from or not to:
			if not connection.line_ref: continue

			connection.line_ref.visible = false
			connection.line_ref = null
			continue

		var from_idx: int = from.get_flow_outputs(global.SAVE_DATA).find(from.get_flow_output(connection.from_id, global.SAVE_DATA))
		var to_idx: int = to.get_flow_inputs(global.SAVE_DATA).find(to.get_flow_input(connection.to_id, global.SAVE_DATA))

		if from_idx < 0 or to_idx < 0:
			if not connection.line_ref: continue

			connection.line_ref.visible = false
			connection.line_ref = null
			continue

		connection.line_ref.to_pool_visible = to.is_showing_on_screen()
		connection.line_ref.from_pool_visible = from.is_showing_on_screen()
		connection.line_ref.from = weakref(from)
		connection.line_ref.to = weakref(to)
		connection.line_ref.from_idx = from_idx
		connection.line_ref.to_idx = to_idx

		# drawing inputs
		if connection.line_ref.to_pool_visible:
			var flow_idx = to.get_flow_inputs(global.SAVE_DATA).find(to.get_flow_input(connection.to_id, global.SAVE_DATA))
			connection.line_ref.output = to.cnode_instance.get_node('%FromFlowContainer').get_child(flow_idx).get_node('%Arrow')

			if not to.cnode_instance.is_connected('on_move', connection.line_ref.update_line):
				to.cnode_instance.connect('on_move', connection.line_ref.update_line)

		# drawing outputs
		if connection.line_ref.from_pool_visible:
			var flow_idx = from.get_flow_outputs(global.SAVE_DATA).find(from.get_flow_output(connection.from_id, global.SAVE_DATA))
			connection.line_ref.input = from.cnode_instance.get_node('%FlowContainer').get_child(flow_idx).get_node('FlowSlot/Control/Connector')

			if not from.cnode_instance.is_connected('on_move', connection.line_ref.update_line):
				from.cnode_instance.connect('on_move', connection.line_ref.update_line)


	_cnode.reset_size()
	_cnode.pivot_offset = _cnode.size / 2
	size = _cnode.size

	if invalid:
		_cnode.modulate = Color(1, 1, 1, .3)
	elif not _vc.current_errors.is_empty():
		_cnode.modulate = Color('ef4444')
	else:
		_cnode.modulate = Color.WHITE

	await RenderingServer.frame_pre_draw

	for connection: HenVCConnectionData in global.SAVE_DATA.get_connections_by_id(id):
		if not connection.line_ref: continue
		connection.line_ref.update_line()

	for connection: HenVCFlowConnectionData in flow_connections:
		if not connection.line_ref: continue
		connection.line_ref.update_line()


func configure_cnode_to_hide(_cnode: HenCnode) -> void:
	# hides the cnode and cleans up connections
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

		var from: HenVirtualCNode = connection.get_from(global.SAVE_DATA)
		var to: HenVirtualCNode = connection.get_to(global.SAVE_DATA)

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

		var from: HenVirtualCNode = connection.get_from(global.SAVE_DATA)
		var to: HenVirtualCNode = connection.get_to(global.SAVE_DATA)

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
