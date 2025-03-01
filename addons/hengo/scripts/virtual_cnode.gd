@tool
class_name HenVirtualCNode extends RefCounted

enum Type {
	DEFAULT,
	IF,
	IMG,
	EXPRESSION,
}

enum SubType {
	FUNC,
	VOID,
	VAR,
	LOCAL_VAR,
	DEBUG_VALUE,
	USER_FUNC,
	SET_VAR,
	SET_PROP,
	GET_PROP,
	VIRTUAL,
	FUNC_INPUT,
	CAST,
	IF,
	RAW_CODE,
	SELF_GO_TO_VOID,
	FOR,
	FOR_ARR,
	FOR_ITEM,
	FUNC_OUTPUT,
	CONST,
	SINGLETON,
	GO_TO_VOID,
	IMG,
	EXPRESSION,
	SET_LOCAL_VAR,
	IN_PROP,
	NOT_CONNECTED,
	DEBUG,
	DEBUG_PUSH,
	DEBUG_FLOW_START,
	START_DEBUG_STATE,
	DEBUG_STATE,
	BREAK,
	CONTINUE,
	PASS
}

var name: String
var id: int
var position: Vector2
var is_showing: bool = false
var cnode_ref: HenCnode
var inputs: Array
var outputs: Array
var size: Vector2
var type: Type
var sub_type: SubType

var input_connections: Array = []
var output_connections: Array = []
# var flow_connection: FlowConnectionData
# var from_vcnode: HenVirtualCNode
var flow_connections: Array = []
var from_flow_connections: Array = []


class FlowConnectionData:
	var line_ref: HenFlowConnectionLine
	var from_pos: Vector2
	var to_pos: Vector2
	var to: HenVirtualCNode
	var to_idx: int

	func get_save() -> Dictionary:
		return {
			to_id = to.id,
			to_idx = to_idx
		}


class FromFlowConnection:
	var from: HenVirtualCNode
	var from_connection: FlowConnectionData


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

	func get_save() -> Dictionary:
		return {
			idx = idx,
			from_vc_id = from.id,
			from_idx = from_idx,
		}


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

				line_data.line_ref.conn_size = (input.get_node('%Connector') as TextureRect).size / 2
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


				line_data.line_ref.conn_size = (output.get_node('%Connector') as TextureRect).size / 2
				line_data.line_ref.update_colors(line_data.type, line_data.to_type)

				if not cnode_ref.is_connected('on_move', line_data.line_ref.update_line):
					cnode_ref.connect('on_move', line_data.line_ref.update_line)

			
			# cleaning from flows
			var from_flow_container: HBoxContainer = cnode_ref.get_node('%FromFlowContainer')

			for from_flow: HenFromFlow in from_flow_container.get_children():
				(from_flow.get_node('%Arrow') as TextureRect).visible = false
				from_flow.visible = false

			# cleaning flows
			var flow_container: HBoxContainer = cnode_ref.get_node('%FlowContainer')

			for flow_c: PanelContainer in flow_container.get_children():
				var connector: HenFlowConnector = flow_c.get_node('FlowSlot/Control/Connector')

				connector.idx = flow_c.get_index()
				connector.root = cnode_ref
				flow_c.visible = false

			# Showing Flows
			match type as Type:
				Type.DEFAULT:
					var container = flow_container.get_child(0)
					var label: Label = container.get_node('FlowSlot/Label')
					
					container.visible = true
					(from_flow_container.get_child(0) as HenFromFlow).visible = true

					label.visible = false
					label.text = ''
					cnode_ref.reset_size()
				Type.IF:
					var true_container = flow_container.get_child(0)
					var false_container = flow_container.get_child(1)
					
					(from_flow_container.get_child(0) as HenFromFlow).visible = true

					true_container.visible = true
					false_container.visible = true

					(true_container.get_node('FlowSlot/Label') as Label).visible = true
					(true_container.get_node('FlowSlot/Label') as Label).text = 'true'
					(false_container.get_node('FlowSlot/Label') as Label).text = 'false'
					
					cnode_ref.reset_size()

			idx = 0
			for from_flow_connection: FromFlowConnection in from_flow_connections:
				if not from_flow_connection.from:
					idx += 1
					continue

				var line: HenFlowConnectionLine

				if from_flow_connection.from_connection.line_ref:
					line = from_flow_connection.from_connection.line_ref
				else:
					line = HenPool.get_flow_line_from_pool()
					from_flow_connection.from_connection.line_ref = line

				# signal to update flow connection line
				if not cnode_ref.is_connected('on_move', line.update_line):
					cnode_ref.connect('on_move', line.update_line)

				line.from_flow_idx = idx
				line.to_cnode = cnode_ref
				line.from_virtual_pos = from_flow_connection.from_connection.from_pos
				line.to_pool_visible = true

				(cnode_ref.get_node('%FromFlowContainer').get_child(idx).get_node('%Arrow') as TextureRect).visible = true

				idx += 1

			idx = 0

			for flow_connection: FlowConnectionData in flow_connections:
				if not flow_connection.to:
					idx += 1
					continue
				
				var line: HenFlowConnectionLine


				if flow_connection.line_ref:
					line = flow_connection.line_ref
				else:
					line = HenPool.get_flow_line_from_pool()
					flow_connection.line_ref = line
				
				# signal to update flow connection line
				if not cnode_ref.is_connected('on_move', line.update_line):
					cnode_ref.connect('on_move', line.update_line)

				line.from_connector = cnode_ref.get_node('%FlowContainer').get_child(idx).get_node('FlowSlot/Control/Connector')
				line.to_virtual_pos = flow_connection.to_pos
				line.from_pool_visible = true
			
				idx += 1

				
			cnode.reset_size()
			size = cnode.size

			# drawing the connections	
			await RenderingServer.frame_post_draw

			for connection: InputConnectionData in input_connections:
				if not connection.line_ref: continue
				connection.line_ref.update_line()
			
			for connection: OutputConnectionData in output_connections:
				if not connection.line_ref: continue
				connection.line_ref.update_line()

			for connection: FlowConnectionData in flow_connections:
				if not connection.line_ref: continue
				connection.line_ref.update_line()

			for connection: FromFlowConnection in from_flow_connections:
				if connection.from_connection:
					if connection.from_connection.line_ref:
						connection.from_connection.line_ref.update_line()
			

			break


func hide() -> void:
	is_showing = false
	
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


		for flow_connection: FlowConnectionData in flow_connections:
			if flow_connection.line_ref:
				flow_connection.line_ref.from_pool_visible = false

				if flow_connection.to.is_showing:
					var pos: Vector2 = HenGlobal.CNODE_CAM.get_relative_vec2(flow_connection.line_ref.from_connector.global_position) + flow_connection.line_ref.from_connector.size / 2
					flow_connection.from_pos = pos
					flow_connection.line_ref.from_virtual_pos = pos
				else:
					flow_connection.line_ref.visible = false
					flow_connection.line_ref = null

		var idx: int = 0
		var from_flow_container: HBoxContainer = cnode_ref.get_node('%FromFlowContainer')

		for from_flow_connection: FromFlowConnection in from_flow_connections:
			if from_flow_connection.from_connection and from_flow_connection.from_connection.line_ref:
				var line: HenFlowConnectionLine = from_flow_connection.from_connection.line_ref

				if line:
					line.to_pool_visible = false

					if from_flow_connection.from.is_showing:
						var pos: Vector2 = HenGlobal.CNODE_CAM.get_relative_vec2((from_flow_container.get_child(idx) as HenFromFlow).global_position)
						from_flow_connection.from_connection.to_pos = pos
						line.to_virtual_pos = pos
					else:
						line.visible = false
						from_flow_connection.from_connection.line_ref = null
			
			idx += 1


		cnode_ref.visible = false
		cnode_ref.virtual_ref = null
		cnode_ref = null


func get_save() -> Dictionary:
	var data: Dictionary = {
		id = id,
		type = type,
		sub_type = sub_type,
		name = name,
		position = var_to_str(position),
		inputs = inputs,
		outputs = outputs,
		size = var_to_str(size),
		input_connections = [],
		output_connections = [],
		flow_connections = []
	}

	for flow_connection: FlowConnectionData in flow_connections:
		if not flow_connection.to: continue
		data.flow_connections.append(flow_connection.get_save())

	for input: InputConnectionData in input_connections:
		data.input_connections.append(input.get_save())

	return data


func add_flow_connection(_idx: int, _to_idx: int, _to: HenVirtualCNode, _line: HenFlowConnectionLine = null) -> void:
	var flow_data: FlowConnectionData = flow_connections[_idx]
	var from_flow: FromFlowConnection = _to.from_flow_connections[_to_idx]

	flow_data.to = _to
	flow_data.line_ref = _line
	flow_data.to_idx = _to_idx

	from_flow.from = self
	from_flow.from_connection = flow_data


func add_connection(_idx: int, _from_idx: int, _from: HenVirtualCNode, _line: HenConnectionLine = null) -> void:
	var input_connection: InputConnectionData = InputConnectionData.new()
	var output_connection: OutputConnectionData = OutputConnectionData.new()

	# output
	output_connection.idx = _from_idx
	output_connection.line_ref = _line
	output_connection.type = _from.outputs[_from_idx].type
	
	output_connection.to_idx = _idx
	output_connection.to = self
	output_connection.to_ref = input_connection
	output_connection.to_type = inputs[_idx].type

	# inputs
	input_connection.idx = _idx
	input_connection.line_ref = _line
	input_connection.type = inputs[_idx].type
	
	input_connection.from = _from
	input_connection.from_idx = _from_idx
	input_connection.from_ref = output_connection
	input_connection.from_type = _from.outputs[_from_idx].type

	_from.output_connections.append(output_connection)
	input_connections.append(input_connection)


static func instantiate_virtual_cnode(_config: Dictionary) -> HenVirtualCNode:
	# adding virtual cnode to list
	var v_cnode: HenVirtualCNode = HenVirtualCNode.new()

	v_cnode.type = _config.type as Type if _config.has('type') else Type.DEFAULT
	v_cnode.sub_type = _config.sub_type
	v_cnode.name = _config.name
	v_cnode.id = HenGlobal.get_new_node_counter() if not _config.has('id') else _config.id

	if _config.has('position'):
		v_cnode.position = _config.position if _config.position is Vector2 else str_to_var(_config.position)


	match v_cnode.type:
		Type.DEFAULT:
			v_cnode.flow_connections.append(FlowConnectionData.new())
			v_cnode.from_flow_connections.append(FromFlowConnection.new())
		Type.IF:
			v_cnode.flow_connections.append(FlowConnectionData.new())
			v_cnode.flow_connections.append(FlowConnectionData.new())

			v_cnode.from_flow_connections.append(FromFlowConnection.new())


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
