class_name HenFormatter extends Node

const X_GAP: int = 100
const Y_GAP: int = 100
const FIRST_LEVEL_Y_GAP: int = 200
const INPUT_X_GAP: int = 50
const REMOTE_INPUT_X_GAP: int = 200
const INPUT_Y_GAP: int = 20
const MIDDLE_Y_GAP: int = 140
const MIDDLE_X_GAP: int = 200


class FormatterData:
	var y_limit: float = 0.
	var list: Array[HenVirtualCNode] = []
	var vc_map: Dictionary = {}
	var list_to_update: Array[HenVirtualCNode] = []
	var original_positions: Dictionary = {}


class VCFormatData:
	var flow_boudings: Dictionary = {}
	var moved: bool = false
	var flow_inputs_positioned_ids: Array[StringName] = []
	var has_multiple_parents: bool = false
	var tree_children: Array[HenVirtualCNode] = []
	var input_owner_id: StringName = ""


# gets or creates format data for a specific node
static func get_format_data(id: StringName, _data: FormatterData) -> VCFormatData:
	if _data.vc_map.has(id):
		return _data.vc_map[id]

	var format_data: VCFormatData = VCFormatData.new()
	_data.vc_map[id] = format_data
	return format_data


# entry point for formatting the virtual node list
static func format_virtual_cnode_list(_virtual_cnode_list: Array[HenVirtualCNode]) -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	if not global.can_format_again:
		return
	
	global.can_format_again = false
	var data: FormatterData = FormatterData.new()
	var virtual_roots: Array[HenVirtualCNode] = []
	var root_boundings: Array[Rect2] = []

	# store original positions before any formatting
	for vc: HenVirtualCNode in _virtual_cnode_list:
		data.original_positions[vc.id] = vc.position

	for vc: HenVirtualCNode in _virtual_cnode_list:
		match vc.sub_type:
			HenVirtualCNode.SubType.VIRTUAL, \
			HenVirtualCNode.SubType.STATE_START, \
			HenVirtualCNode.SubType.FUNC_INPUT, \
			HenVirtualCNode.SubType.FUNC_OUTPUT, \
			HenVirtualCNode.SubType.OVERRIDE_VIRTUAL, \
			HenVirtualCNode.SubType.MACRO_INPUT, \
			HenVirtualCNode.SubType.SIGNAL_ENTER, \
			HenVirtualCNode.SubType.MACRO_OUTPUT:
				var format_data: VCFormatData = get_format_data(vc.id, data)
				format_data.moved = true
				set_position(vc, Vector2.ZERO, data)
				var bounding: Rect2 = start_format(vc, data, format_data)
				virtual_roots.append(vc)
				root_boundings.append(bounding)

	for i: int in range(1, virtual_roots.size()):
		var current_root: HenVirtualCNode = virtual_roots[i]
		var current_bounding: Rect2 = root_boundings[i]
		var previous_bounding: Rect2 = root_boundings[i - 1]

		if current_bounding.position.x < previous_bounding.position.x + previous_bounding.size.x:
			var overlap: float = (previous_bounding.position.x + previous_bounding.size.x) - current_bounding.position.x
			var offset: Vector2 = Vector2(overlap + X_GAP, 0)
			move_flow_tree(current_root, offset, data)
			root_boundings[i] = calculate_tree_bounding(current_root, data)
	
	for vc: HenVirtualCNode in data.list_to_update:
		vc.follow.call_deferred(vc.position)

	global.can_format_again = true


# handles recursive flow branch positioning
static func start_format(_vc: HenVirtualCNode, _data: FormatterData, _format_data: VCFormatData) -> Rect2:
	var input_rect: Rect2 = start_map_inputs(_vc, _data)
	var min_pos: Vector2 = _vc.position
	var max_pos: Vector2 = _vc.position + _vc.size
	
	min_pos = min_pos.min(input_rect.position)
	max_pos = max_pos.max(input_rect.position + input_rect.size)

	var global: HenGlobal = Engine.get_singleton('Global') as HenGlobal
	var flow_outputs: Array[HenVCFlow] = _vc.get_flow_outputs(global.SAVE_DATA)
	var branches_base_y: float = max(_vc.position.y + _vc.size.y, _data.y_limit)

	if flow_outputs.size() == 1:
		var flow_connection: HenVCFlowConnectionData = _vc.get_flow_output_connection(flow_outputs[0].id)
		if flow_connection:
			var from: HenVirtualCNode = flow_connection.get_from(global.SAVE_DATA)
			var to: HenVirtualCNode = flow_connection.get_to(global.SAVE_DATA)
			var to_format_data: VCFormatData = get_format_data(to.id, _data)

			if to_format_data.flow_inputs_positioned_ids.has(flow_connection.to_id):
				to_format_data.has_multiple_parents = true

			if not to_format_data.moved:
				to_format_data.moved = true
				_format_data.tree_children.append(to)
				
				set_position(to,
					Vector2(
						from.position.x + from.size.x / 2.0,
						branches_base_y + Y_GAP
					) + Vector2(-to.size.x / 2.0, 0),
					_data
				)
				
				start_format(to, _data, to_format_data)
				var child_bounding: Rect2 = calculate_tree_bounding(to, _data)
				min_pos = min_pos.min(child_bounding.position)
				max_pos = max_pos.max(child_bounding.position + child_bounding.size)
				to_format_data.flow_inputs_positioned_ids.append(flow_connection.to_id)

	elif flow_outputs.size() > 1:
		if flow_outputs.size() % 2 == 0:
			var half_size: int = int(flow_outputs.size() / 2.0)
			var flow_boundings: Array[Rect2] = []
			var flow_nodes: Array[HenVirtualCNode] = []
			var left_list: Array[HenVCFlow] = []
			var right_list: Array[HenVCFlow] = []
			var idx: int = 0

			for flow_output: HenVCFlow in flow_outputs:
				if idx < half_size:
					left_list.append(flow_output)
				else:
					right_list.append(flow_output)
				idx += 1

			left_list.reverse()
			var left_x_limit: float = (_vc.position.x + _vc.size.x / 2.0) - MIDDLE_X_GAP
			idx = left_list.size() * -1
			
			for flow_output: HenVCFlow in left_list:
				var flow_connection: HenVCFlowConnectionData = _vc.get_flow_output_connection(flow_output.id)
				if flow_connection:
					var to: HenVirtualCNode = flow_connection.get_to(global.SAVE_DATA)
					var to_format_data: VCFormatData = get_format_data(to.id, _data)

					if to_format_data.flow_inputs_positioned_ids.has(flow_connection.to_id):
						to_format_data.has_multiple_parents = true
					
					if not to_format_data.moved:
						to_format_data.moved = true
						_format_data.tree_children.append(to)
						set_position(to, Vector2(left_x_limit - to.size.x, branches_base_y + FIRST_LEVEL_Y_GAP * (idx * -1)), _data)
						var child_bounding: Rect2 = start_format(to, _data, to_format_data)
						flow_boundings.append(child_bounding)
						flow_nodes.append(to)
						
						if child_bounding.position.x + child_bounding.size.x > left_x_limit:
							var overlap: float = (child_bounding.position.x + child_bounding.size.x) - left_x_limit
							move_flow_tree(to, Vector2(-overlap, 0), _data)
							child_bounding = calculate_tree_bounding(to, _data)
							
						var left_rect: Rect2 = start_map_inputs(to, _data)
						min_pos = min_pos.min(left_rect.position)
						max_pos = max_pos.max(left_rect.position + left_rect.size)
						to_format_data.moved = true
						left_x_limit = min(left_x_limit, child_bounding.position.x - MIDDLE_X_GAP)
						to_format_data.flow_inputs_positioned_ids.append(flow_connection.to_id)
				idx += 1

			idx = right_list.size() * -1
			var right_x_limit: float = (_vc.position.x + _vc.size.x / 2.0) + MIDDLE_X_GAP
			for flow_output: HenVCFlow in right_list:
				var flow_connection: HenVCFlowConnectionData = _vc.get_flow_output_connection(flow_output.id)
				if flow_connection:
					var to: HenVirtualCNode = flow_connection.get_to(global.SAVE_DATA)
					var to_format_data: VCFormatData = get_format_data(to.id, _data)

					if to_format_data.flow_inputs_positioned_ids.has(flow_connection.to_id):
						to_format_data.has_multiple_parents = true

					if not to_format_data.moved:
						to_format_data.moved = true
						_format_data.tree_children.append(to)
						set_position(to, Vector2(right_x_limit, branches_base_y + FIRST_LEVEL_Y_GAP * (idx * -1)), _data)
						var child_bounding: Rect2 = start_format(to, _data, to_format_data)
						flow_boundings.append(child_bounding)
						flow_nodes.append(to)
						
						if child_bounding.position.x < right_x_limit:
							var overlap: float = right_x_limit - child_bounding.position.x
							move_flow_tree(to, Vector2(overlap, 0), _data)
							child_bounding = calculate_tree_bounding(to, _data)
							
						var right_rect: Rect2 = start_map_inputs(to, _data)
						min_pos = min_pos.min(right_rect.position)
						max_pos = max_pos.max(right_rect.position + right_rect.size)
						right_x_limit = max(right_x_limit, child_bounding.position.x + child_bounding.size.x + MIDDLE_X_GAP)
						to_format_data.flow_inputs_positioned_ids.append(flow_connection.to_id)
				idx += 1
		else:
			var half_size: int = int(flow_outputs.size() / 2.0)
			var middle_output: HenVCFlow = flow_outputs[half_size]
			var max_side_y: float = branches_base_y
			var idx: int = 0
			var flow_boundings: Array[Rect2] = []
			var flow_nodes: Array[HenVirtualCNode] = []
			var left_list: Array[HenVCFlow] = []
			var right_list: Array[HenVCFlow] = []

			for flow_output: HenVCFlow in flow_outputs:
				if flow_output == middle_output:
					idx += 1
					continue
				if idx < half_size:
					left_list.append(flow_output)
				else:
					right_list.append(flow_output)
				idx += 1

			left_list.reverse()
			idx = left_list.size() * -1
			var left_x_limit: float = (_vc.position.x + _vc.size.x / 2.0) - MIDDLE_X_GAP
			
			for flow_output: HenVCFlow in left_list:
				var flow_connection: HenVCFlowConnectionData = _vc.get_flow_output_connection(flow_output.id)
				if flow_connection:
					var to: HenVirtualCNode = flow_connection.get_to(global.SAVE_DATA)
					var to_format_data: VCFormatData = get_format_data(to.id, _data)

					if to_format_data.flow_inputs_positioned_ids.has(flow_connection.to_id):
						to_format_data.has_multiple_parents = true
					
					if not to_format_data.moved:
						to_format_data.moved = true
						_format_data.tree_children.append(to)
						set_position(to, Vector2(left_x_limit - to.size.x, branches_base_y + FIRST_LEVEL_Y_GAP * (idx * -1)), _data)
						var child_bounding: Rect2 = start_format(to, _data, to_format_data)
						max_side_y = max(max_side_y, child_bounding.position.y + child_bounding.size.y)
						flow_boundings.append(child_bounding)
						flow_nodes.append(to)
						
						if child_bounding.position.x + child_bounding.size.x > left_x_limit:
							var overlap: float = (child_bounding.position.x + child_bounding.size.x) - left_x_limit
							move_flow_tree(to, Vector2(-overlap, 0), _data)
							child_bounding = calculate_tree_bounding(to, _data)
							
						var left_rect: Rect2 = start_map_inputs(to, _data)
						min_pos = min_pos.min(left_rect.position)
						max_pos = max_pos.max(left_rect.position + left_rect.size)
						left_x_limit = min(left_x_limit, child_bounding.position.x - MIDDLE_X_GAP)
						to_format_data.flow_inputs_positioned_ids.append(flow_connection.to_id)
				idx += 1

			idx = right_list.size() * -1
			var right_x_limit: float = (_vc.position.x + _vc.size.x / 2.0) + MIDDLE_X_GAP
			for flow_output: HenVCFlow in right_list:
				var flow_connection: HenVCFlowConnectionData = _vc.get_flow_output_connection(flow_output.id)
				if flow_connection:
					var to: HenVirtualCNode = flow_connection.get_to(global.SAVE_DATA)
					var to_format_data: VCFormatData = get_format_data(to.id, _data)

					if to_format_data.flow_inputs_positioned_ids.has(flow_connection.to_id):
						to_format_data.has_multiple_parents = true

					if not to_format_data.moved:
						to_format_data.moved = true
						_format_data.tree_children.append(to)
						set_position(to, Vector2(right_x_limit, branches_base_y + FIRST_LEVEL_Y_GAP * (idx * -1)), _data)
						var child_bounding: Rect2 = start_format(to, _data, to_format_data)
						max_side_y = max(max_side_y, child_bounding.position.y + child_bounding.size.y)
						flow_boundings.append(child_bounding)
						flow_nodes.append(to)
						
						if child_bounding.position.x < right_x_limit:
							var overlap: float = right_x_limit - child_bounding.position.x
							move_flow_tree(to, Vector2(overlap, 0), _data)
							child_bounding = calculate_tree_bounding(to, _data)
							
						var right_rect: Rect2 = start_map_inputs(to, _data)
						min_pos = min_pos.min(right_rect.position)
						max_pos = max_pos.max(right_rect.position + right_rect.size)
						right_x_limit = max(right_x_limit, child_bounding.position.x + child_bounding.size.x + MIDDLE_X_GAP)
						to_format_data.flow_inputs_positioned_ids.append(flow_connection.to_id)
				idx += 1

			var side_flows: Array[HenVirtualCNode] = []
			var side_boundings: Array[Rect2] = []
			idx = 0
			for flow_output: HenVCFlow in flow_outputs:
				if flow_output == middle_output:
					idx += 1
					continue
				var flow_connection: HenVCFlowConnectionData = _vc.get_flow_output_connection(flow_output.id)
				if flow_connection:
					var to: HenVirtualCNode = flow_connection.get_to(global.SAVE_DATA)
					if _format_data.tree_children.has(to):
						side_flows.append(to)
						side_boundings.append(calculate_tree_bounding(to, _data))
				idx += 1

			for i: int in range(1, side_flows.size()):
				var current_node: HenVirtualCNode = side_flows[i]
				var current_bounding: Rect2 = side_boundings[i]
				var previous_bounding: Rect2 = side_boundings[i - 1]
				if current_bounding.position.x < previous_bounding.position.x + previous_bounding.size.x:
					var overlap: float = (previous_bounding.position.x + previous_bounding.size.x) - current_bounding.position.x
					move_flow_tree(current_node, Vector2(overlap + X_GAP, 0), _data)
					side_boundings[i] = calculate_tree_bounding(current_node, _data)
			
			for i: int in range(side_boundings.size()):
				var child_bounding: Rect2 = side_boundings[i]
				min_pos = min_pos.min(child_bounding.position)
				max_pos = max_pos.max(child_bounding.position + child_bounding.size)

			var middle_connection: HenVCFlowConnectionData = _vc.get_flow_output_connection(middle_output.id)
			if middle_connection:
				var middle_to: HenVirtualCNode = middle_connection.get_to(global.SAVE_DATA)
				var middle_to_format_data: VCFormatData = get_format_data(middle_to.id, _data)

				if middle_to_format_data.flow_inputs_positioned_ids.has(middle_connection.to_id):
					middle_to_format_data.has_multiple_parents = true

				if not middle_to_format_data.moved:
					middle_to_format_data.moved = true
					_format_data.tree_children.append(middle_to)
					set_position(middle_to,
						Vector2(
							(_vc.position.x + _vc.size.x / 2.0) - middle_to.size.x / 2.0,
							max(max_side_y, _data.y_limit) + MIDDLE_Y_GAP
						),
						_data
					)
					var middle_rect: Rect2 = start_map_inputs(middle_to, _data)
					min_pos = min_pos.min(middle_rect.position)
					max_pos = max_pos.max(middle_rect.position + middle_rect.size)
					middle_to_format_data.flow_inputs_positioned_ids.append(middle_connection.to_id)
					var middle_bounding: Rect2 = start_format(middle_to, _data, middle_to_format_data)
					min_pos = min_pos.min(middle_bounding.position)
					max_pos = max_pos.max(middle_bounding.position + middle_bounding.size)

	return Rect2(min_pos, max_pos - min_pos)


# moves a flow tree and its owned inputs
static func move_flow_tree(_vc: HenVirtualCNode, _offset: Vector2, _data: FormatterData) -> void:
	set_position(_vc, _vc.position + _offset, _data)
	var global: HenGlobal = Engine.get_singleton(&'Global')
	
	for input: HenVCInOutData in _vc.get_inputs(global.SAVE_DATA):
		var connection: HenVCConnectionData = _vc.get_input_connection(input.id, _vc)
		if connection:
			var input_node: HenVirtualCNode = connection.get_from(global.SAVE_DATA)
			var input_format_data: VCFormatData = get_format_data(input_node.id, _data)
			
			if input_format_data.moved and input_format_data.input_owner_id == _vc.id:
				move_flow_tree(input_node, _offset, _data)

	for flow_output: HenVCFlow in _vc.get_flow_outputs(global.SAVE_DATA):
		var flow_connection: HenVCFlowConnectionData = _vc.get_flow_output_connection(flow_output.id)
		if flow_connection:
			var to: HenVirtualCNode = flow_connection.get_to(global.SAVE_DATA)
			var format_data: VCFormatData = get_format_data(_vc.id, _data)
			if not format_data.tree_children.has(to):
				continue

			move_flow_tree(to, _offset, _data)


# calculates the bounding box of a node tree
static func calculate_tree_bounding(_vc: HenVirtualCNode, _data: FormatterData) -> Rect2:
	var min_pos: Vector2 = _vc.position
	var max_pos: Vector2 = _vc.position + _vc.size

	var input_rect: Rect2 = start_map_inputs(_vc, _data)
	min_pos = min_pos.min(input_rect.position)
	max_pos = max_pos.max(input_rect.position + input_rect.size)

	var global: HenGlobal = Engine.get_singleton(&'Global')

	for flow_output: HenVCFlow in _vc.get_flow_outputs(global.SAVE_DATA):
		var flow_connection: HenVCFlowConnectionData = _vc.get_flow_output_connection(flow_output.id)
		if flow_connection:
			var to: HenVirtualCNode = flow_connection.get_to(global.SAVE_DATA)
			var format_data: VCFormatData = get_format_data(_vc.id, _data)
			if not format_data.tree_children.has(to):
				continue
			var child_bounding: Rect2 = calculate_tree_bounding(to, _data)
			min_pos = min_pos.min(child_bounding.position)
			max_pos = max_pos.max(child_bounding.position + child_bounding.size)

	return Rect2(min_pos, max_pos - min_pos)


# maps input nodes recursively for layout
static func start_map_inputs(_vc: HenVirtualCNode, _data: FormatterData, _rect: Rect2 = Rect2()) -> Rect2:
	var global: HenGlobal = Engine.get_singleton('Global') as HenGlobal
	var save_data: HenSaveData = global.SAVE_DATA
	var connection_list: Array[HenVCConnectionData] = []

	for input: HenVCInOutData in _vc.get_inputs(save_data):
		var connection: HenVCConnectionData = _vc.get_input_connection(input.id, _vc)
		if connection:
			connection_list.append(connection)

	# pre-check if _vc has any remote input connection and calculate gap based on name
	var to_orig_y: float = _data.original_positions.get(_vc.id, _vc.position).y
	var max_remote_name_len: int = 0
	for conn: HenVCConnectionData in connection_list:
		var from_node: HenVirtualCNode = conn.get_from(save_data)
		var from_orig_y: float = _data.original_positions.get(from_node.id, from_node.position).y
		if from_orig_y + 200 < to_orig_y:
			var vc_name: String = from_node.get_vc_name(save_data)
			max_remote_name_len = max(max_remote_name_len, vc_name.length())

	# calculate gap: base gap + estimated text width (approx 8px per char + icon + padding)
	var x_gap: int = INPUT_X_GAP
	if max_remote_name_len > 0:
		x_gap = INPUT_X_GAP + 40 + (max_remote_name_len * 8)

	_data.y_limit = _vc.position.y

	var current_y_cursor: float = _vc.position.y
	var local_flow_bottom: float = _vc.position.y + _vc.size.y
	var min_pos: Vector2 = _vc.position
	var max_pos: Vector2 = _vc.position + _vc.size

	for connection: HenVCConnectionData in connection_list:
		var from: HenVirtualCNode = connection.get_from(save_data)
		var from_format_data: VCFormatData = get_format_data(from.id, _data)
		
		if from_format_data.moved:
			if from_format_data.input_owner_id == _vc.id:
				var input_bounding: Rect2 = calculate_tree_bounding(from, _data)
				min_pos = min_pos.min(input_bounding.position)
				max_pos = max_pos.max(input_bounding.position + input_bounding.size)
				
				var branch_bottom: float = max(from.position.y + from.size.y, input_bounding.position.y + input_bounding.size.y)
				current_y_cursor = max(current_y_cursor, branch_bottom + INPUT_Y_GAP)
				
				if branch_bottom > _vc.position.y:
					local_flow_bottom = max(local_flow_bottom, branch_bottom)
			continue

		var target_pos: Vector2 = Vector2(
			_vc.position.x - from.size.x - x_gap,
			current_y_cursor
		)
		
		var best_x: float = target_pos.x
		var best_y: float = target_pos.y
		var outgoing_connections: Array = save_data.get_outgoing_connection_from_vc(from)
		
		for parent_conn: HenVCConnectionData in outgoing_connections:
			var parent_node: HenVirtualCNode = parent_conn.get_to(save_data)
			var parent_data: VCFormatData = get_format_data(parent_node.id, _data)
			if not parent_data.moved:
				continue

			# use same x_gap determined for this vc
			if parent_node != _vc and parent_node.position.y < best_y:
				best_y = parent_node.position.y
			
			var parent_target_x: float = parent_node.position.x - from.size.x - x_gap
			if parent_target_x < best_x:
				best_x = parent_target_x

		set_position(from, Vector2(best_x, best_y), _data)
		
		from_format_data.moved = true
		from_format_data.input_owner_id = _vc.id
		
		var input_bounding: Rect2 = start_map_inputs(from, _data)
		var branch_bottom: float = max(from.position.y + from.size.y, input_bounding.position.y + input_bounding.size.y)
		
		current_y_cursor = max(current_y_cursor, branch_bottom + INPUT_Y_GAP)
		
		if branch_bottom > _vc.position.y:
			min_pos = min_pos.min(input_bounding.position)
			max_pos = max_pos.max(input_bounding.position + input_bounding.size)
			local_flow_bottom = max(local_flow_bottom, branch_bottom)

	_data.y_limit = max(_data.y_limit, local_flow_bottom)
	return Rect2(min_pos, max_pos - min_pos)


# updates the node position in the update list
static func set_position(_vc: HenVirtualCNode, _position: Vector2, _data: FormatterData) -> void:
	_vc.position = _position
	if not _data.list_to_update.has(_vc):
		_data.list_to_update.append(_vc)

	
# triggers formatting for the current router route
static func format_current_route() -> void:
	var router: HenRouter = Engine.get_singleton(&'Router')
	if not router.current_route:
		return

	var thread_helper: HenThreadHelper = Engine.get_singleton(&'ThreadHelper')
	thread_helper.add_task(HenFormatter.format_virtual_cnode_list.bind(router.get_current_route_v_cnodes()))