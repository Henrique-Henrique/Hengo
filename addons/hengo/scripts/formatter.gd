@tool
class_name HenFormatter extends Node

static var start_position: Vector2
static var arr: Array = []
static var min_x: float
static var max_x: float

static func format(_virtual_cnode: HenCnode, _old_cnode: HenCnode) -> void:
	# reseting positions
	# _virtual_cnode.position.x = start_position.x - _virtual_cnode.size.x / 2
	_virtual_cnode.position.y = _old_cnode.position.y + _old_cnode.size.y + 200
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
			if _virtual_cnode.flow_to.has('cnode'):
				format(_virtual_cnode.flow_to.cnode, _virtual_cnode)


static func format_y() -> void:
	arr.reverse()

	if arr[0] is Array:
		arr.remove_at(0)

	print(arr.duplicate().map(func(x): return x.hash if x is HenCnode else x[0].hash))

	var first_cnode: HenCnode = arr[0] as HenCnode
	
	first_cnode.can_move_to_format = false
	min_x = first_cnode.position.x
	max_x = first_cnode.position.x + first_cnode.size.x


	for cnode in arr:
		if cnode is HenCnode:
			var flow_line: HenFlowConnectionLine = cnode.from_lines[0]
			var from_cnode: HenCnode = flow_line.from_connector.root

			print(cnode.hash, ' | ', flow_line.flow_type, ' > ', from_cnode.can_move_to_format)

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
			
			flow_line.update_line()
		elif cnode is Array:
			var cnode_ref: HenCnode = cnode[0]

			cnode_ref.position.x = min_x - cnode_ref.size.x
			cnode_ref.can_move_to_format = false
			min_x = min(min_x, cnode_ref.position.x)