@tool
extends Button

# imports
const _Global = preload('res://addons/hengo/scripts/global.gd')
const _CNode = preload('res://addons/hengo/scripts/cnode.gd')

const VIRTUAL_DISTANCE = 500
const CNODE_FLOW_DISTANCE = 100
const IF_FLOW_DISTANCE = 200


var all_nodes: Array[Array] = []
var max_depth: int = 0

func _ready() -> void:
	pressed.connect(_on_press)


func parse_virtual(_cnode: _CNode, _flow: String, _id: int = 0, _h_id: int = 0) -> void:
	max_depth = max(max_depth, _id)

	match _cnode.type:
		'if':
			all_nodes.append([_cnode, 'if', _id, _h_id])

			if _cnode.flow_to.has('false_flow'):
				parse_virtual(_cnode.flow_to['false_flow'], 'false_flow', _id + 1, _h_id + 1)

			if _cnode.flow_to.has('then_flow'):
				parse_virtual(_cnode.flow_to['then_flow'], 'then_flow', _id + 1, _h_id)
			
			if _cnode.flow_to.has('true_flow'):
				parse_virtual(_cnode.flow_to['true_flow'], 'true_flow', _id + 1, _h_id - 1)
		
		_:
			all_nodes.append([_cnode, _flow, _id, _h_id])

			if _cnode.flow_to.has('cnode'):
				parse_virtual(_cnode.flow_to['cnode'], _flow, _id + 1, _h_id)


func _on_press() -> void:
	# var last_virtual: _CNode = null
	# var cnodes: Array = _Global.CNODE_CONTAINER.get_children()

	# test
	for node in _Global.CNODE_CAM.get_children():
		if node is ReferenceRect:
			node.queue_free()

	
	# var start: int = Time.get_ticks_usec()

	for state in _Global.STATE_CONTAINER.get_children():
		for cnode in [state.virtual_cnode_list[1]]:
			all_nodes = []
			parse_virtual(cnode, 'cnode')

			all_nodes.reverse()

			# var true_min_x: float = INF
			# var false_max_x: float = -INF

			# var ata: Array = []

			var x_depth: int = 0
			
			var old_cn: _CNode = all_nodes[0][0]
			var old_flow: String = all_nodes[0][1]
			var old_depth: int = all_nodes[0][2]
				
			var max_x: float = -INF
			var max_x_depth: int = all_nodes[0][3]
			var old_x_depth: int = max_x_depth


			old_cn.position = Vector2.ZERO

			for arr in all_nodes:
				var cn: _CNode = arr[0]
				var flow: String = arr[1]
				var depth: int = arr[2]
				var h_depth: int = arr[3]
					

				var pos: Vector2 = Vector2(0, 205 * depth)

				if cn == old_cn:
					cn.move(pos)
				
					old_cn = cn
					old_flow = flow
					old_depth = depth
					old_x_depth = h_depth

					max_x = max(max_x, pos.x + cn.size.x)
					max_x_depth = max(max_x_depth, h_depth)
					continue

				if depth > old_depth:
					match flow:
						'true_flow':
							pos.x = max_x + max(200 * (abs(h_depth) - 1), 200)
						_:
							pos.x = max_x + 200 * abs(abs(h_depth) - abs(max_x_depth))
							# pos.x = (max_x + max(200 * (abs(h_depth) + abs(max_x_depth)), 200 * abs(max_x_depth))) if h_depth > 0 else max_x + 200

				elif depth < old_depth:
					match flow:
						'if':

							if cn.flow_to.has('then_flow'):
								pos.x = cn.flow_to.then_flow.position.x
							elif cn.flow_to.has('false_flow'):
								pos.x = cn.flow_to.false_flow.position.x - 200
							elif cn.flow_to.has('true_flow'):
								pos.x = cn.flow_to.true_flow.position.x + 200
						_:
							pos.x = old_cn.position.x
				else:
					match flow:
						'if':
							pos.x = max_x + max(200 * (abs(h_depth) - 1), 200)
						'true_flow':
							pos.x -= 200 * abs(h_depth)
						'then_flow':
							pos.x = old_cn.position.x + 200 * 2
						'false_flow':
							pos.x = old_cn.position.x + 200 * 2

				cn.move(pos)
				
				old_cn = cn
				old_flow = flow
				old_depth = depth
				old_x_depth = h_depth

				max_x = max(max_x, pos.x + cn.size.x)
				max_x_depth = max(max_x_depth, h_depth)


func _format_cnode_flow(_cnode: _CNode, _key: String, _increment: Vector2 = Vector2.ZERO) -> void:
	var cn: _CNode = _cnode.flow_to[_key]
	var pos: Vector2 = _cnode.position

	pos += _increment

	pos.x += (_cnode.size.x - cn.size.x) / 2
	pos.y += _cnode.size.y + CNODE_FLOW_DISTANCE

	cn.move(pos)


func debug_rect(_pos: Vector2, _size: Vector2, _color: Color = Color.RED) -> void:
	var ref = ReferenceRect.new()
	ref.position = _pos
	ref.size = _size
	ref.border_color = _color
	ref.border_width = 3
	ref.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_Global.CNODE_CAM.add_child(ref)