@tool
class_name HenFormatter extends Node

static var start_position: Vector2
static var arr: Array = []
static var min_x: float
static var max_x: float

# cnodes
const CNODE_X_SPACING = 150
const CNODE_Y_SPACING = 120
# inputs
const INPUT_Y_SPACING = 80
const INPUT_X_SPACING = 60

static func format(_virtual_cnode: HenCnode, _old_cnode: HenCnode, _move: bool = true) -> void:
	# reseting positions
	if _move:
		_virtual_cnode.position.y = _old_cnode.position.y + _old_cnode.size.y + CNODE_Y_SPACING

	_virtual_cnode.can_move_to_format = true

	arr.append(_virtual_cnode)

	match _virtual_cnode.type:
		HenCnode.TYPE.IF:
			var max_y: float = format_inputs_y(_virtual_cnode, _virtual_cnode.position.y + _virtual_cnode.size.y)

			if _virtual_cnode.flow_to.has('true_flow'):
				_virtual_cnode.flow_to.true_flow.position.y = max_y + CNODE_Y_SPACING
				format(_virtual_cnode.flow_to.true_flow, _virtual_cnode, false)

			if _virtual_cnode.flow_to.has('false_flow'):
				format(_virtual_cnode.flow_to.false_flow, _virtual_cnode)
			else:
				arr.append([_virtual_cnode])
		_:
			var max_y: float = format_inputs_y(_virtual_cnode, _virtual_cnode.position.y + _virtual_cnode.size.y)

			if _virtual_cnode.flow_to.has('cnode'):
				_virtual_cnode.flow_to.cnode.position.y = max_y + CNODE_Y_SPACING

				format(_virtual_cnode.flow_to.cnode, _virtual_cnode, false)


static func format_y() -> void:
	arr.reverse()
	# print(arr)
	# print(arr.duplicate().map(func(x): return x.hash if x is HenCnode else x[0].hash))

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
			if cnode.from_lines.is_empty():
				cnode.move(Vector2(cnode.flow_to.cnode.position.x, cnode.position.y))
				continue
			

			var flow_line: HenFlowConnectionLine = cnode.from_lines[0]
			var from_cnode: HenCnode = flow_line.from_connector.root

			# print(cnode.hash, ' | ', flow_line.flow_type, ' > ', from_cnode.can_move_to_format, ' = ', cnode.can_move_to_format, ' _ ')

			if cnode.can_move_to_format:
				cnode.position.x = min_x - cnode.size.x - CNODE_X_SPACING
				min_x = min(min_x, cnode.position.x)

			# format inputs
			min_x = min(min_x, format_inputs_min(cnode, min_x))


			if from_cnode.can_move_to_format:
				match flow_line.flow_type:
					'false_flow':
						from_cnode.position.x = min_x - from_cnode.size.x - CNODE_X_SPACING
						min_x = min(min_x, from_cnode.position.x)
					'true_flow':
						from_cnode.position.x = max_x
						max_x = max(max_x, from_cnode.position.x + from_cnode.size.x)
					'cnode':
						from_cnode.position.x = cnode.position.x - (
							from_cnode.size.x - cnode.size.x
						) / 2
						min_x = min(min_x, from_cnode.position.x)
				
				from_cnode.can_move_to_format = false
				
			
			flow_line.update_line()

		elif cnode is Array:
			var cnode_ref: HenCnode = cnode[0]

			cnode_ref.position.x = min_x - cnode_ref.size.x - CNODE_X_SPACING
			cnode_ref.can_move_to_format = false
			min_x = min(min_x, cnode_ref.position.x)
		

static func format_inputs_y(_cnode: HenCnode, _max_y: float) -> float:
	var is_first: bool = true
	var input_arr: Array

	match _cnode.type:
		HenCnode.TYPE.IF:
			input_arr = [_cnode.get_node('%TitleContainer').get_child(0).get_child(0)]
		_:
			input_arr = _cnode.get_node('%InputContainer').get_children()


	for input: HenCnodeInOut in input_arr:
		if input.in_connected_from:
			if is_first:
				input.in_connected_from.position.y = _cnode.position.y
				is_first = false
			else:
				input.in_connected_from.position.y = _max_y + INPUT_Y_SPACING

			_max_y = max(_max_y, input.in_connected_from.position.y + input.in_connected_from.size.y)
			_max_y = max(_max_y, format_inputs_y(input.in_connected_from, _max_y))

	return _max_y


static func format_inputs_min(_cnode: HenCnode, _min_x: float) -> float:
	var input_arr: Array

	match _cnode.type:
		HenCnode.TYPE.IF:
			input_arr = [_cnode.get_node('%TitleContainer').get_child(0).get_child(0)]
		_:
			input_arr = _cnode.get_node('%InputContainer').get_children()


	for input: HenCnodeInOut in input_arr:
		if input.in_connected_from:
			input.in_connected_from.position.x = _cnode.position.x - input.in_connected_from.size.x - INPUT_X_SPACING

			for line: HenConnectionLine in input.from_connection_lines:
				line.update_line()

			_min_x = min(_min_x, input.in_connected_from.position.x)
			_min_x = min(min_x, format_inputs_min(input.in_connected_from, _min_x))
	
	return _min_x


static func format_comments() -> void:
	for comment: HenComment in HenGlobal.COMMENT_CONTAINER.get_children():
		comment.pin_to_cnodes(true, false)