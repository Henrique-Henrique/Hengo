@tool
class_name HenVirtualCNode extends RefCounted


var name: String
var id: int
var position: Vector2
var is_showing: bool = false
var cnode_ref: HenCnode
var inputs: Array
var outputs: Array
var size: Vector2

var input_connections: Array = []
var output_connections: Array = []


class ConnectionData:
	var idx: int
	var line_ref: HenConnectionLine
	var type: StringName


class InputConnectionData extends ConnectionData:
	var from: HenVirtualCNode
	var from_idx: int
	var from_ref: OutputConnectionData
	var from_old_pos: Vector2
	var from_type: StringName


class OutputConnectionData extends ConnectionData:
	var to: HenVirtualCNode
	var to_idx: int
	var to_ref: InputConnectionData
	var to_old_pos: Vector2
	var to_type: StringName


func check_visibility(_rect: Rect2) -> void:
	is_showing = _rect.intersects(
		Rect2(
			position,
			size
		)
	)

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

			for line_data: InputConnectionData in input_connections:
				if line_data.from_ref.line_ref is HenConnectionLine:
					line_data.line_ref = line_data.from_ref.line_ref
				else:
					line_data.line_ref = HenPool.get_line_from_pool(
						line_data.from.cnode_ref if line_data.from.cnode_ref else null,
						null,
						line_data.from.cnode_ref.get_node('%OutputContainer').get_child(line_data.from_idx).get_node('%Connector') if line_data.from.cnode_ref else null,
						null
					)

					if not line_data.line_ref:
						continue
				
				
				line_data.line_ref.from_virtual_pos = line_data.from_old_pos

				
				var input: HenCnodeInOut = cnode_ref.get_node('%InputContainer').get_child(line_data.idx)
				line_data.line_ref.to_cnode = cnode_ref
				line_data.line_ref.output = input.get_node('%Connector')
				line_data.line_ref.to_pool_visible = true
				line_data.line_ref.visible = true

				input.remove_in_prop()

				await RenderingServer.frame_pre_draw

				line_data.line_ref.conn_size = (input.get_node('%Connector') as TextureRect).size / 2

				line_data.line_ref.update_line()
				line_data.line_ref.update_colors(line_data.from_type, line_data.type)

				if not cnode_ref.is_connected('on_move', line_data.line_ref.update_line):
					cnode_ref.connect('on_move', line_data.line_ref.update_line)


			for line_data: OutputConnectionData in output_connections:
				if line_data.to_ref.line_ref is HenConnectionLine:
					line_data.line_ref = line_data.to_ref.line_ref
				else:
					line_data.line_ref = HenPool.get_line_from_pool(
						null,
						line_data.to.cnode_ref if line_data.to and line_data.to.cnode_ref else null,
						null,
						line_data.to.cnode_ref.get_node('%InputContainer').get_child(line_data.to_idx).get_node('%Connector') if line_data.to and line_data.to.cnode_ref else null
					)

					if not line_data.line_ref:
						continue
				
				line_data.line_ref.to_virtual_pos = line_data.to_old_pos


				var output: HenCnodeInOut = cnode_ref.get_node('%OutputContainer').get_child(line_data.idx)
				line_data.line_ref.from_cnode = cnode_ref
				line_data.line_ref.input = output.get_node('%Connector')
				line_data.line_ref.from_pool_visible = true
				line_data.line_ref.visible = true

				await RenderingServer.frame_pre_draw

				line_data.line_ref.conn_size = (output.get_node('%Connector') as TextureRect).size / 2

				line_data.line_ref.update_line()
				line_data.line_ref.update_colors(line_data.type, line_data.to_type)

				if not cnode_ref.is_connected('on_move', line_data.line_ref.update_line):
					cnode_ref.connect('on_move', line_data.line_ref.update_line)

			
			cnode.reset_size()

			size = cnode.size

			break


func hide() -> void:
	if cnode_ref:
		for signal_data: Dictionary in cnode_ref.get_signal_connection_list('on_move'):
			cnode_ref.disconnect('on_move', signal_data.callable)
		
		for line_data: InputConnectionData in input_connections:
			if not line_data.line_ref:
				continue
			
			line_data.line_ref.to_pool_visible = false

			if line_data.from.is_showing:
				var pos: Vector2 = HenGlobal.CNODE_CAM.get_relative_vec2(line_data.line_ref.output.global_position) + line_data.line_ref.conn_size
				line_data.from_ref.to_old_pos = pos

				if not line_data.from_ref.line_ref:
					continue
				
				line_data.from_ref.line_ref.to_virtual_pos = pos
			else:
				line_data.line_ref.visible = false

			line_data.line_ref = null

		for line_data: OutputConnectionData in output_connections:
			if not line_data.line_ref:
				continue
			
			line_data.line_ref.from_pool_visible = false

			if line_data.to.is_showing:
				var pos: Vector2 = HenGlobal.CNODE_CAM.get_relative_vec2(line_data.line_ref.input.global_position) + line_data.line_ref.conn_size
				line_data.to_ref.from_old_pos = pos
				line_data.to_ref.line_ref.from_virtual_pos = pos
			else:
				line_data.line_ref.visible = false
			
			line_data.line_ref = null


		cnode_ref.visible = false
		cnode_ref.virtual_ref = null
		cnode_ref = null


func reset() -> void:
	is_showing = false
	
	if cnode_ref:
		for line_data: InputConnectionData in input_connections:
			line_data.from_ref.to_old_pos = HenGlobal.CNODE_CAM.get_relative_vec2(line_data.line_ref.output.global_position) + line_data.line_ref.conn_size

		for line_data: OutputConnectionData in output_connections:
			line_data.to_ref.from_old_pos = HenGlobal.CNODE_CAM.get_relative_vec2(line_data.line_ref.input.global_position) + line_data.line_ref.conn_size

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


static func instantiate_virtual_cnode_and_add(_config: Dictionary) -> HenVirtualCNode:
	var v_cnode: HenVirtualCNode = instantiate_virtual_cnode(_config)
	v_cnode.show()
	return v_cnode
