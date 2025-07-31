class_name HenVirtualCNodeRenderer extends RefCounted

var vc: WeakRef

func _init(_vc: HenVirtualCNode) -> void:
	vc = weakref(_vc)


func show() -> void:
	var virtual_cnode: HenVirtualCNode = vc.get_ref()

	if not virtual_cnode:
		return

	virtual_cnode.state.is_showing = true

	for cnode: HenCnode in HenGlobal.cnode_pool:
		if not cnode.visible:
			cnode.position = virtual_cnode.visual.position
			cnode.visible = true
			cnode.route_ref = HenRouter.current_route
			cnode.change_name(virtual_cnode.identity.name)
			cnode.virtual_ref = weakref(virtual_cnode)
			cnode.category = virtual_cnode.identity.category

			var idx: int = 0

			# clearing inputs and change to new
			for input: HenCnodeInOut in cnode.get_node('%InputContainer').get_children():
				input.visible = false

				if idx < virtual_cnode.io.inputs.size():
					input.visible = true
					
					var input_data: HenVCInOutData = virtual_cnode.io.inputs[idx]

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
			for output: HenCnodeInOut in cnode.get_node('%OutputContainer').get_children():
				output.visible = false

				if idx < virtual_cnode.io.outputs.size():
					output.visible = true
					
					var output_data: HenVCInOutData = virtual_cnode.io.outputs[idx]
					
					output.input_ref = output_data

					output.change_name(output_data.name)
					output.change_type(
						output_data.type,
						output_data.value if output_data.value else null,
						output_data.sub_type if output_data.sub_type else &''
					)

				idx += 1
			
			virtual_cnode.references.cnode_ref = cnode


			for connection: HenVCConnectionData.InputConnectionData in virtual_cnode.io.input_connections:
				if connection.from_ref.line_ref is HenConnectionLine:
					connection.line_ref = connection.from_ref.line_ref
				elif connection.line_ref is HenConnectionLine:
					connection.from_ref.line_ref = connection.line_ref
				else:
					connection.line_ref = HenPool.get_line_from_pool(
						connection.from.references.cnode_ref if connection.from.references.cnode_ref else null,
						null,
						connection.from.references.cnode_ref.get_node('%OutputContainer').get_child(
							virtual_cnode.io.outputs.find(
								virtual_cnode.io.get_output(connection.from_id))
							).get_node('%Connector') if connection.from.references.cnode_ref else null,
						null
					)

					if not connection.line_ref:
						continue
				
				connection.line_ref.from_virtual_pos = connection.from_old_pos

				
				var input: HenCnodeInOut = virtual_cnode.references.cnode_ref.get_node('%InputContainer').get_child(
					virtual_cnode.io.inputs.find(virtual_cnode.io.get_input(connection.to_id))
				)
				connection.line_ref.to_cnode = virtual_cnode.references.cnode_ref
				connection.line_ref.output = input.get_node('%Connector')
				connection.line_ref.to_pool_visible = true

				input.remove_in_prop()

				connection.line_ref.conn_size = (input.get_node('%Connector') as TextureRect).size / 2
				connection.line_ref.update_colors(connection.from_type, connection.type)

				if not virtual_cnode.references.cnode_ref.is_connected('on_move', connection.line_ref.update_line):
					virtual_cnode.references.cnode_ref.connect('on_move', connection.line_ref.update_line)


			for connection: HenVCConnectionData.OutputConnectionData in virtual_cnode.io.output_connections:
				if connection.to_ref.line_ref is HenConnectionLine:
					connection.line_ref = connection.to_ref.line_ref
				elif connection.line_ref is HenConnectionLine:
					connection.to_ref.line_ref = connection.line_ref
				else:
					connection.line_ref = HenPool.get_line_from_pool(
						null,
						connection.to.references.cnode_ref if connection.to and connection.to.references.cnode_ref else null,
						null,
						connection.to.references.cnode_ref.get_node('%InputContainer').get_child(
							virtual_cnode.io.inputs.find(virtual_cnode.io.get_input(connection.to_id))
						).get_node('%Connector') if connection.to and connection.to.references.cnode_ref else null
					)

					if not connection.line_ref:
						continue
				
				connection.line_ref.to_virtual_pos = connection.to_old_pos


				var output: HenCnodeInOut = virtual_cnode.references.cnode_ref.get_node('%OutputContainer').get_child(
					virtual_cnode.io.outputs.find(virtual_cnode.io.get_output(connection.from_id))
				)
				connection.line_ref.from_cnode = virtual_cnode.references.cnode_ref
				connection.line_ref.input = output.get_node('%Connector')
				connection.line_ref.from_pool_visible = true

				connection.line_ref.conn_size = (output.get_node('%Connector') as TextureRect).size / 2
				connection.line_ref.update_colors(connection.type, connection.to_type)

				if not virtual_cnode.references.cnode_ref.is_connected('on_move', connection.line_ref.update_line):
					virtual_cnode.references.cnode_ref.connect('on_move', connection.line_ref.update_line)

			
			# cleaning from flows
			var from_flow_container: HBoxContainer = virtual_cnode.references.cnode_ref.get_node('%FromFlowContainer')

			for from_flow: HenFromFlow in from_flow_container.get_children():
				(from_flow.get_node('%Arrow') as TextureRect).visible = false
				from_flow.visible = false

			# cleaning flows
			var flow_container: HBoxContainer = virtual_cnode.references.cnode_ref.get_node('%FlowContainer')

			for flow_c: PanelContainer in flow_container.get_children():
				var connector: HenFlowConnector = flow_c.get_node('FlowSlot/Control/Connector')

				connector.root = virtual_cnode.references.cnode_ref
				flow_c.visible = false
				(flow_c.get_node('FlowSlot/Label') as Label).visible = false

			# Showing Flows
			match virtual_cnode.identity.type:
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

			for from_flow_connection: HenVCFromFlowConnectionData in virtual_cnode.flow.from_flow_connections:
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
						line = HenPool.get_flow_line_from_pool()
						from_connection.line_ref = line

					# signal to update flow connection line
					if not virtual_cnode.references.cnode_ref.is_connected('on_move', line.update_line):
						virtual_cnode.references.cnode_ref.connect('on_move', line.update_line)

					line.from_flow_idx = idx
					line.to_cnode = virtual_cnode.references.cnode_ref
					line.from_virtual_pos = from_connection.from_pos
					line.to_pool_visible = true

				(from_flow_container.get_child(idx).get_node('%Arrow') as TextureRect).visible = true

				idx += 1

			idx = 0


			for flow_connection: HenVCFlowConnectionData in virtual_cnode.flow.flow_connections:
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
					line = HenPool.get_flow_line_from_pool()
					flow_connection.line_ref = line
				
				# signal to update flow connection line
				if not virtual_cnode.references.cnode_ref.is_connected('on_move', line.update_line):
					virtual_cnode.references.cnode_ref.connect('on_move', line.update_line)

				line.from_connector = virtual_cnode.references.cnode_ref.get_node('%FlowContainer').get_child(idx).get_node('FlowSlot/Control/Connector')
				line.to_virtual_pos = flow_connection.to_pos
				line.from_pool_visible = true

				idx += 1

				
			cnode.reset_size()
			cnode.pivot_offset = cnode.size / 2
			virtual_cnode.visual.size = cnode.size

			if virtual_cnode.state.invalid:
				virtual_cnode.references.cnode_ref.modulate = Color(1, 1, 1, .3)
			else:
				virtual_cnode.references.cnode_ref.modulate = Color.WHITE

			# drawing the connections	
			await RenderingServer.frame_post_draw

			for connection: HenVCConnectionData.InputConnectionData in virtual_cnode.io.input_connections:
				if not connection.line_ref: continue
				connection.line_ref.update_line()
			
			for connection: HenVCConnectionData.OutputConnectionData in virtual_cnode.io.output_connections:
				if not connection.line_ref: continue
				connection.line_ref.update_line()

			for connection: HenVCFlowConnectionData in virtual_cnode.flow.flow_connections:
				if not connection.line_ref: continue
				connection.line_ref.update_line()

			for connection: HenVCFromFlowConnectionData in virtual_cnode.flow.from_flow_connections:
				if not connection.from_connections.is_empty():
					for from_connection: HenVCFlowConnectionData in connection.from_connections:
						if from_connection.line_ref:
							from_connection.line_ref.update_line()

			break


func hide() -> void:
	var virtual_cnode: HenVirtualCNode = vc.get_ref()

	if not virtual_cnode:
		return

	virtual_cnode.state.is_showing = false

	
	if virtual_cnode.references.cnode_ref:
		for signal_data: Dictionary in virtual_cnode.references.cnode_ref.get_signal_connection_list('on_move'):
			virtual_cnode.references.cnode_ref.disconnect('on_move', signal_data.callable as Callable)
		
		for line_data: HenVCConnectionData.InputConnectionData in virtual_cnode.io.input_connections:
			if not line_data.line_ref:
				continue
			
			line_data.line_ref.to_pool_visible = false

			if line_data.from.state.is_showing:
				var pos: Vector2 = HenGlobal.CAM.get_relative_vec2(line_data.line_ref.output.global_position as Vector2) + line_data.line_ref.conn_size
				line_data.from_ref.to_old_pos = pos

				if not line_data.from_ref.line_ref:
					continue
				
				line_data.from_ref.line_ref.to_virtual_pos = pos
			else:
				line_data.line_ref.visible = false

			line_data.line_ref = null


		for line_data: HenVCConnectionData.OutputConnectionData in virtual_cnode.io.output_connections:
			if not line_data.line_ref:
				continue
			
			line_data.line_ref.from_pool_visible = false

			if line_data.to.state.is_showing:
				var pos: Vector2 = HenGlobal.CAM.get_relative_vec2(line_data.line_ref.input.global_position as Vector2) + line_data.line_ref.conn_size
				line_data.to_ref.from_old_pos = pos
				line_data.to_ref.line_ref.from_virtual_pos = pos
			else:
				line_data.line_ref.visible = false
			
			line_data.line_ref = null


		for flow_connection: HenVCFlowConnectionData in virtual_cnode.flow.flow_connections:
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
		var from_flow_container: HBoxContainer = virtual_cnode.references.cnode_ref.get_node('%FromFlowContainer')

		for from_flow_connection: HenVCFromFlowConnectionData in virtual_cnode.flow.from_flow_connections:
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


		virtual_cnode.references.cnode_ref.visible = false
		virtual_cnode.references.cnode_ref.virtual_ref = null
		virtual_cnode.references.cnode_ref = null


func update() -> void:
	var virtual_cnode: HenVirtualCNode = vc.get_ref()

	if not virtual_cnode:
		return
	
	if virtual_cnode.state.is_deleted or (not virtual_cnode.route_info.route_ref or not HenRouter.current_route or virtual_cnode.route_info.route_ref.id != HenRouter.current_route.id):
		hide()
		return

	hide()
	virtual_cnode.visual.check_visibility()