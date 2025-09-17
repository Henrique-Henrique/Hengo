class_name HenFormatter extends Node

const Y_GAP = 250
const Y_FIRST_CHILD_GAP = 400


class FormatterData:
	var x_limit: float = 0.
	var list: Array[HenVirtualCNode] = []
	var depth_map: Dictionary = {} # maps vc to its depth level


static func format_virtual_cnode_list(_virtual_cnode_list: Array) -> void: # Array[HenVirtualCNode]
	var data: FormatterData = FormatterData.new()
	var x_gap: float = 50.

	for vc: HenVirtualCNode in _virtual_cnode_list:
		if vc.identity.sub_type == HenVirtualCNode.SubType.VIRTUAL:
			start_navigation(vc, data, 0) # start with depth 0
			vc.set_position(Vector2.ZERO)
	
	data.list.reverse()

	for vc: HenVirtualCNode in data.list:
		# set y position based on depth layer with special gap for first child and middle children
		var depth: int = data.depth_map.get(vc, 0)
		var y_position: float
		
		if depth == 1:
			y_position = Y_FIRST_CHILD_GAP
		else:
			y_position = Y_FIRST_CHILD_GAP + (depth - 1) * Y_GAP
		
		if vc.flow.flow_outputs.size() == 1:
			var flow_connection: HenVCFlowConnectionData = vc.get_flow_output_connection(vc.flow.flow_outputs[0].id)

			if flow_connection:
				# center horizontally relative to the target node
				var target_x: float = flow_connection.get_to().visual.position.x + flow_connection.get_to().visual.size.x / 2
				var centered_x: float = target_x - vc.visual.size.x / 2
				vc.set_position(Vector2(centered_x, y_position))
			else:
				vc.set_position(Vector2(data.x_limit - vc.visual.size.x, y_position))
		else:
			position_vc_with_multiple_outputs(vc, data, x_gap, y_position)
		
		data.x_limit = minf(data.x_limit, data.x_limit - (vc.visual.size.x + x_gap))


static func position_vc_with_multiple_outputs(_vc: HenVirtualCNode, _data: FormatterData, _x_gap: float, _y_position: float) -> void:
	var output_count: int = _vc.flow.flow_outputs.size()
	
	if output_count < 2:
		_vc.set_position(Vector2(_data.x_limit - _vc.visual.size.x - _x_gap, _y_position))
		return
	
	var connections: Array[HenVCFlowConnectionData] = []
	for i in range(output_count):
		connections.append(_vc.get_flow_output_connection(_vc.flow.flow_outputs[i].id))
	
	var middle_indices: Array[int] = []
	if output_count % 2 == 1:
		middle_indices.append(int(output_count / 2.))
	else:
		middle_indices.append(int(output_count / 2.) - 1)
		middle_indices.append(int(output_count / 2.))
	
	var middle_connections: Array[HenVCFlowConnectionData] = []
	for idx in middle_indices:
		if connections[idx]:
			middle_connections.append(connections[idx])
	
	if middle_connections.size() == middle_indices.size():
		var positions: Array[float] = []
		for conn in middle_connections:
			# use center of target node
			var target_center: float = conn.get_to().visual.position.x + conn.get_to().visual.size.x / 2
			positions.append(target_center)
		
		var avg_position: float = positions.reduce(func(a, b): return a + b) / positions.size()
		var centered_x: float = avg_position - _vc.visual.size.x / 2
		_vc.set_position(Vector2(centered_x, _y_position))
		return
	elif middle_connections.size() == 1:
		# center relative to the single middle connection
		var target_center: float = middle_connections[0].get_to().visual.position.x + middle_connections[0].get_to().visual.size.x / 2
		var centered_x: float = target_center - _vc.visual.size.x / 2
		_vc.set_position(Vector2(centered_x, _y_position))
		return
	
	var left_connection: HenVCFlowConnectionData = connections[0]
	var right_connection: HenVCFlowConnectionData = connections[output_count - 1]
	
	if left_connection and right_connection:
		var left_to: HenVirtualCNode = left_connection.get_to()
		var right_to: HenVirtualCNode = right_connection.get_to()
		
		# center between the centers of left and right target nodes
		var left_center: float = left_to.visual.position.x + left_to.visual.size.x / 2
		var right_center: float = right_to.visual.position.x + right_to.visual.size.x / 2
		var avg_center: float = (left_center + right_center) / 2
		var centered_x: float = avg_center - _vc.visual.size.x / 2
		
		_vc.set_position(Vector2(centered_x, _y_position))
		return
	
	if right_connection:
		_vc.set_position(Vector2(_data.x_limit - _vc.visual.size.x - _x_gap, _y_position))
	elif left_connection:
		var to: HenVirtualCNode = left_connection.get_to()
		_vc.set_position(Vector2(to.visual.position.x + to.visual.size.x + _x_gap, _y_position))
	else:
		_vc.set_position(Vector2(_data.x_limit - _vc.visual.size.x - _x_gap, _y_position))


static func is_middle_child(_vc: HenVirtualCNode, _data: FormatterData) -> bool:
	# check if this node is a middle child (not first or last output)
	for parent_vc: HenVirtualCNode in _data.list:
		if parent_vc == _vc:
			continue
			
		var parent_outputs: Array = parent_vc.flow.flow_outputs
		if parent_outputs.size() < 3: # need at least 3 outputs to have middle ones
			continue
			
		var connections: Array[HenVCFlowConnectionData] = []
		for i in range(parent_outputs.size()):
			connections.append(parent_vc.get_flow_output_connection(parent_outputs[i].id))
		
		# check if this vc is connected to a middle output (not first or last)
		for i in range(1, connections.size() - 1):
			if connections[i] and connections[i].get_to() == _vc:
				return true
	
	return false


static func should_add_vc_to_list(_vc: HenVirtualCNode) -> bool:
	var output_count: int = _vc.flow.flow_outputs.size()
	
	if output_count < 2:
		return false
	
	var connections: Array[HenVCFlowConnectionData] = []
	for i in range(output_count):
		connections.append(_vc.get_flow_output_connection(_vc.flow.flow_outputs[i].id))
	
	# check if first and last connections exist but middle ones don't
	var first_connection: HenVCFlowConnectionData = connections[0]
	var last_connection: HenVCFlowConnectionData = connections[output_count - 1]
	
	if not first_connection or not last_connection:
		return false
	
	# check if any middle connection exists
	for i in range(1, output_count - 1):
		if connections[i]:
			return false
	
	return true


static func start_navigation(_vc: HenVirtualCNode, _data: FormatterData, _depth: int) -> void:
	# check if this node is a middle child and adjust depth accordingly
	var is_middle: bool = is_middle_child(_vc, _data)
	var adjusted_depth: int = _depth + (1 if is_middle else 0)
	
	# set depth for this node if not already set or if current depth is greater
	if not _data.depth_map.has(_vc) or _data.depth_map[_vc] < adjusted_depth:
		_data.depth_map[_vc] = adjusted_depth
	
	_data.list.append(_vc)

	for flow: HenVCFlow in _vc.flow.flow_outputs:
		var flow_connection: HenVCFlowConnectionData = _vc.get_flow_output_connection(flow.id)

		if flow_connection:
			# pass the adjusted depth to children
			start_navigation(flow_connection.get_to(), _data, adjusted_depth + 1)
		elif _vc.flow.flow_outputs.size() > 1:
			if should_add_vc_to_list(_vc):
				_data.list.append(_vc)
			
			if flow == _vc.flow.flow_outputs[-1]:
				_data.list.append(_vc)
