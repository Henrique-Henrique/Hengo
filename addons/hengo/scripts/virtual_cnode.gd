@tool
class_name HenVirtualCNode extends RefCounted


var name: String
var id: int
var position: Vector2
var is_showing: bool = false
var cnode_ref: HenCnode
var inputs: Array
var outputs: Array

var input_connections: Array = []
var output_connections: Array = []


func check_visibility(_rect: Rect2) -> void:
	is_showing = _rect.has_point(position)

	if is_showing and cnode_ref == null:
		show()
	elif not is_showing:
		hide()


func show() -> void:
	for cnode: HenCnode in HenGlobal.cnode_pool:
		if not cnode.visible:
			cnode.position = position
			cnode.visible = true
			cnode.route_ref = HenRouter.current_route
			cnode.change_name(name)
			cnode.virtual_ref = self

			var idx: int = 0

			# clearing inputs and change to new
			for input: HenCnodeInOut in cnode.get_node('%InputContainer').get_children():
				input.visible = false

				if idx < inputs.size():
					input.visible = true
					
					var input_data: Dictionary = inputs[idx]
					input.change_name(input_data.name)
					input.change_type(input_data.type)

				idx += 1

			idx = 0

			# clearing outputs and change to new
			for output: HenCnodeInOut in cnode.get_node('%OutputContainer').get_children():
				output.visible = false

				if idx < outputs.size():
					output.visible = true
					
					var output_data: Dictionary = outputs[idx]
					output.change_name(output_data.name)
					output.change_type(output_data.type)

				idx += 1
			
			cnode_ref = cnode

			# TODO change line config when cnode_ref change
			for line_data: Dictionary in output_connections:
				if not line_data.has('line_ref'):
					if not cnode_ref or not line_data.to.cnode_ref:
						continue
					
					for line: HenConnectionLine in HenGlobal.connection_line_pool:
						if not line.visible:
							line.from_cnode = cnode_ref
							line.to_cnode = line_data.to.cnode_ref
							line.input = cnode_ref.get_node('%OutputContainer').get_child(line_data.idx).get_node('%Connector')
							line.output = line_data.to.cnode_ref.get_node('%InputContainer').get_child(line_data.to_idx).get_node('%Connector')

							line.visible = true
							line_data.line_ref = line
							await RenderingServer.frame_post_draw
							line.update_line()

							if not cnode_ref.is_connected('on_move', line_data.line_ref.update_line):
								cnode_ref.connect('on_move', line_data.line_ref.update_line)
							
							if not line_data.to.cnode_ref.is_connected('on_move', line_data.line_ref.update_line):
								line_data.to.cnode_ref.connect('on_move', line_data.line_ref.update_line)

							break
					
					continue

				line_data.line_ref.from_cnode = cnode_ref
				line_data.line_ref.to_cnode = line_data.to.cnode_ref
				line_data.line_ref.input = cnode_ref.get_node('%OutputContainer').get_child(line_data.idx).get_node('%Connector')
				line_data.line_ref.output = line_data.to.cnode_ref.get_node('%InputContainer').get_child(line_data.to_idx).get_node('%Connector')
				line_data.line_ref.visible = true
				line_data.line_ref.update_line()

				if not cnode_ref.is_connected('on_move', line_data.line_ref.update_line):
					cnode_ref.connect('on_move', line_data.line_ref.update_line)
				
				if not line_data.to.cnode_ref.is_connected('on_move', line_data.line_ref.update_line):
					line_data.to.cnode_ref.connect('on_move', line_data.line_ref.update_line)
			
			cnode.reset_size()
			break


func hide() -> void:
	if cnode_ref:
		for output: HenCnodeInOut in cnode_ref.get_node('%OutputContainer').get_children():
			for line: HenConnectionLine in output.to_connection_lines:
				line.position.y += 30

		for line_data: Dictionary in output_connections:
			if not line_data.has('line_ref'):
				continue
			
			if not (line_data.line_ref as HenConnectionLine).to_cnode.visible:
				line_data.line_ref.visible = false
				
				if cnode_ref:
					for signal_data: Dictionary in cnode_ref.get_signal_connection_list('on_move'):
						cnode_ref.disconnect('on_move', signal_data.callable)

				if line_data.to.cnode_ref:
					for signal_data: Dictionary in line_data.to.cnode_ref.get_signal_connection_list('on_move'):
						line_data.to.cnode_ref.disconnect('on_move', signal_data.callable)

				line_data.erase('line_ref')

		print(output_connections)

		cnode_ref.visible = false
		cnode_ref.virtual_ref = null
		cnode_ref = null


func reset() -> void:
	is_showing = false
	
	cnode_ref.virtual_ref = null
	cnode_ref = null


static func instantiate_virtual_cnode(_config: Dictionary) -> HenVirtualCNode:
	# adding virtual cnode to list
	var v_cnode: HenVirtualCNode = HenVirtualCNode.new()

	v_cnode.name = _config.name
	v_cnode.id = HenGlobal.get_new_node_counter() if not _config.has('hash') else _config.hash

	if _config.has('pos'):
		v_cnode.position = str_to_var(_config.pos)
	elif _config.has('position'):
		v_cnode.position = _config.position

	v_cnode.inputs = _config.inputs if _config.has('inputs') else []
	v_cnode.outputs = _config.outputs if _config.has('outputs') else []

	if not HenGlobal.vc_list.has(_config.route.id):
		HenGlobal.vc_list[_config.route.id] = []
	
	HenGlobal.vc_list[_config.route.id].append(v_cnode)

	return v_cnode


static func instantiate_virtual_cnode_and_add(_config: Dictionary) -> void:
	var v_cnode: HenVirtualCNode = instantiate_virtual_cnode(_config)
	v_cnode.show()
