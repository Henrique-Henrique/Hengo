class_name HenFormatter extends Node

const Y_GAP = 250


class FormatterData:
	var x_limit: float = 0.
	var list: Array[HenVirtualCNode] = []


static func format_virtual_cnode_list(_virtual_cnode_list: Array) -> void: # Array[HenVirtualCNode]
	var data: FormatterData = FormatterData.new()
	var x_gap: float = 200.

	for vc: HenVirtualCNode in _virtual_cnode_list:
		if vc.identity.sub_type == HenVirtualCNode.SubType.VIRTUAL:
			start_navigation(vc, data)
			vc.set_position(Vector2.ZERO)
			# break
	
	data.list.reverse()

	for vc: HenVirtualCNode in data.list:
		if vc.flow.flow_outputs.size() == 1:
			var flow_connection: HenVCFlowConnectionData = vc.get_flow_output_connection(vc.flow.flow_outputs[0].id)

			if flow_connection:
				vc.set_position(Vector2(flow_connection.get_to().visual.position.x, vc.visual.position.y))
			else:
				vc.set_position(Vector2(data.x_limit - vc.visual.size.x, vc.visual.position.y))
		else:
			if vc.flow.flow_outputs.size() == 3:
				var left_flow_connection: HenVCFlowConnectionData = vc.get_flow_output_connection(vc.flow.flow_outputs[0].id)
				var middle_flow_connection: HenVCFlowConnectionData = vc.get_flow_output_connection(vc.flow.flow_outputs[1].id)
				var right_flow_connection: HenVCFlowConnectionData = vc.get_flow_output_connection(vc.flow.flow_outputs[2].id)

				if middle_flow_connection:
					vc.set_position(Vector2(middle_flow_connection.get_to().visual.position.x, vc.visual.position.y))
				elif left_flow_connection and right_flow_connection:
					var left_to: HenVirtualCNode = left_flow_connection.get_to()
					var right_to: HenVirtualCNode = right_flow_connection.get_to()

					vc.set_position(
						Vector2(
							((left_to.visual.position.x + right_to.visual.position.x) / 2),
							vc.visual.position.y
						) - Vector2(vc.visual.size.x / 4, 0)
					)
				elif right_flow_connection:
					vc.set_position(Vector2(data.x_limit - vc.visual.size.x, vc.visual.position.y))
				elif left_flow_connection:
					var to: HenVirtualCNode = left_flow_connection.get_to()
					vc.set_position(Vector2(to.visual.position.x + to.visual.size.x, vc.visual.position.y))

			else:
				vc.set_position(Vector2(data.x_limit - vc.visual.size.x, vc.visual.position.y))
		
		# data.x_limit -= vc.visual.size.x + x_gap
		data.x_limit = minf(data.x_limit, data.x_limit - (vc.visual.size.x + x_gap))


static func start_navigation(_vc: HenVirtualCNode, _data: FormatterData) -> void:
	_data.list.append(_vc)

	for flow: HenVCFlow in _vc.flow.flow_outputs:
		var flow_connection: HenVCFlowConnectionData = _vc.get_flow_output_connection(flow.id)

		if flow_connection:
			start_navigation(flow_connection.get_to(), _data)


static func clean_rects() -> void:
	for rect in HenGlobal.HENGO_ROOT.get_node('%CommentContainer').get_children():
		if rect is ReferenceRect:
			rect.queue_free()
		
	
static func create_rect(_position: Vector2, _size: Vector2) -> void:
	var rect: ReferenceRect = ReferenceRect.new()
	rect.position = _position
	rect.size = _size
	rect.border_width = 4
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.process_mode = Control.PROCESS_MODE_DISABLED
	HenGlobal.HENGO_ROOT.get_node('%CommentContainer').add_child(rect)
