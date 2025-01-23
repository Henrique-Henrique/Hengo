@tool
class_name HenFormatter extends Node

static var start_position: Vector2
static var arr: Array = []
static var min_x: float
static var max_x: float

static func format(_virtual_cnode: HenCnode, _old_cnode: HenCnode) -> void:
	# reseting positions
	_virtual_cnode.position.y = _old_cnode.position.y + _old_cnode.size.y + 120

	_virtual_cnode.can_move_to_format = true
	arr.append(_virtual_cnode)

	match _virtual_cnode.type:
		HenCnode.TYPE.IF:
			if _virtual_cnode.flow_to.has('true_flow'):
				format(_virtual_cnode.flow_to.true_flow, _virtual_cnode)

			# if _virtual_cnode.flow_to.has('then_flow'):
			# 	format(_virtual_cnode.flow_to.then_flow)

			if _virtual_cnode.flow_to.has('false_flow'):
				format(_virtual_cnode.flow_to.false_flow, _virtual_cnode)
			else:
				arr.append([_virtual_cnode])
		_:
			# print(
			# 	format_inputs(_virtual_cnode, _virtual_cnode.position.y + _virtual_cnode.size.y)
			# )


			# var max_y: float = format_inputs(_virtual_cnode, _virtual_cnode.position.y + _virtual_cnode.size.y)

			if _virtual_cnode.flow_to.has('cnode'):
				# _virtual_cnode.flow_to.cnode.position.y = max_y + 80
				format(_virtual_cnode.flow_to.cnode, _virtual_cnode)


static func format_y() -> void:
	arr.reverse()
	print(arr)
	print(arr.duplicate().map(func(x): return x.hash if x is HenCnode else x[0].hash))

	if arr[0] is Array:
		var first_cnode: HenCnode = arr[0][0] as HenCnode
		
		first_cnode.can_move_to_format = false
		#TODO change this
		min_x = HenGlobal.CNODE_CONTAINER.get_child(0).position.x + HenGlobal.CNODE_CONTAINER.get_child(0).size.x
		max_x = min_x
	else:
		var first_cnode: HenCnode = arr[0] as HenCnode
		
		first_cnode.can_move_to_format = false
		min_x = first_cnode.position.x
		max_x = first_cnode.position.x + first_cnode.size.x


	for cnode in arr:
		if cnode is HenCnode:
			var flow_line: HenFlowConnectionLine = cnode.from_lines[0]
			var from_cnode: HenCnode = flow_line.from_connector.root

			print(cnode.hash, ' | ', flow_line.flow_type, ' > ', from_cnode.can_move_to_format, ' = ', cnode.can_move_to_format)

			match flow_line.flow_type:
				'false_flow':
					if cnode.can_move_to_format:
						cnode.position.x = min_x - cnode.size.x
						min_x = min(min_x, cnode.position.x)

					if from_cnode.can_move_to_format:
						from_cnode.position.x = min_x - from_cnode.size.x
						from_cnode.can_move_to_format = false
						min_x = min(min_x, from_cnode.position.x)
				'true_flow':
					if cnode.can_move_to_format:
						cnode.position.x = min_x - cnode.size.x
						min_x = min(min_x, cnode.position.x)

					if from_cnode.can_move_to_format:
						from_cnode.position.x = max_x
						from_cnode.can_move_to_format = false
						max_x = max(max_x, from_cnode.position.x + from_cnode.size.x)
				'cnode':
					if cnode.can_move_to_format:
						cnode.position.x = min_x - cnode.size.x
						min_x = min(min_x, cnode.position.x)

					if from_cnode.can_move_to_format:
						from_cnode.position.x = cnode.position.x
						from_cnode.can_move_to_format = false
						min_x = min(min_x, from_cnode.position.x)
					

			# var parent_y: float = format_inputs(from_cnode, from_cnode.position.y + from_cnode.size.y)

			# print(parent_y, '  /  ', from_cnode.hash)

			# if parent_y > cnode.position.y:
			# 	cnode.position.y = parent_y - 80
			
			# format_inputs(cnode, cnode.position.y + cnode.size.y)

			# print('diff ', parent_y > cnode.position.y)

			
			flow_line.update_line()

		elif cnode is Array:
			var cnode_ref: HenCnode = cnode[0]

			cnode_ref.position.x = min_x - cnode_ref.size.x
			cnode_ref.can_move_to_format = false
			min_x = min(min_x, cnode_ref.position.x)
		

# static func format_inputs(_cnode: HenCnode, _max_y: float) -> float:
# 	var is_first: bool = true

# 	for input: HenCnodeInOut in _cnode.get_node('%InputContainer').get_children():
# 		if input.in_connected_from:
# 			input.in_connected_from.position.x = _cnode.position.x - input.in_connected_from.size.x - 60

# 			if is_first:
# 				input.in_connected_from.position.y = _cnode.position.y
# 				is_first = false
# 			else:
# 				input.in_connected_from.position.y = _max_y + 20

# 			_max_y = max(_max_y, input.in_connected_from.position.y + input.in_connected_from.size.y)

# 			var input_tree_max_y: float = format_inputs(input.in_connected_from, _max_y)
# 			_max_y = max(_max_y, input_tree_max_y)

# 	return _max_y
