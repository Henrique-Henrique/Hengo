@tool
class_name HenClipboard

# properties to skip during serialization (runtime-only properties)
const SKIP_PROPERTIES: Array[String] = [
	'cnode_instance',
	'is_showing',
	'is_deleted',
	'parent_route_id',
	'route_type',
]

# required properties that must always be serialized even if empty
const REQUIRED_PROPERTIES: Array[String] = [
	'id',
	'name',
	'type',
]

# copies selected virtual cnodes to clipboard
static func copy(_nodes: Array[HenVirtualCNode]) -> int:
	if _nodes.is_empty():
		return 0

	var global: HenGlobal = Engine.get_singleton(&'Global')
	var selected_ids: Dictionary = {}
	var nodes_data: Array = []
	var connections_data: Array = []
	var flow_connections_data: Array = []
	var added_conn_ids: Dictionary = {}
	var added_flow_conn_ids: Dictionary = {}

	for vc: HenVirtualCNode in _nodes:
		selected_ids[vc.id] = true

	for vc: HenVirtualCNode in _nodes:
		var node_data: Dictionary = _serialize_virtual_cnode(vc)
		nodes_data.append(node_data)

	# collect all connections between selected nodes
	for vc: HenVirtualCNode in _nodes:
		for conn: HenVCConnectionData in global.SAVE_DATA.get_connection_from_vc(vc):
			if added_conn_ids.has(conn.id):
				continue

			if selected_ids.has(conn.from_node_id) and selected_ids.has(conn.to_node_id):
				connections_data.append(_serialize_resource(conn))
				added_conn_ids[conn.id] = true

	# collect all flow connections between selected nodes
	for vc: HenVirtualCNode in _nodes:
		for flow_conn: HenVCFlowConnectionData in global.SAVE_DATA.get_flow_connection_from_vc(vc):
			if added_flow_conn_ids.has(flow_conn.id):
				continue

			if selected_ids.has(flow_conn.from_node_id) and selected_ids.has(flow_conn.to_node_id):
				flow_connections_data.append(_serialize_resource(flow_conn))
				added_flow_conn_ids[flow_conn.id] = true

	global.clipboard = {
		nodes = nodes_data,
		connections = connections_data,
		flow_connections = flow_connections_data
	}

	return nodes_data.size()


# pastes nodes from clipboard with new ids
static func paste(_target_pos: Vector2) -> int:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var router: HenRouter = Engine.get_singleton(&'Router')

	if global.clipboard.is_empty():
		return 0

	var nodes_data: Array = global.clipboard.get('nodes', [])
	var connections_data: Array = global.clipboard.get('connections', [])
	var flow_connections_data: Array = global.clipboard.get('flow_connections', [])

	if nodes_data.is_empty():
		return 0

	var route: HenRouteData = router.current_route
	if not route:
		return 0

	var node_id_map: Dictionary = {}
	var io_id_map: Dictionary = {}
	var pasted_nodes: Array[HenVirtualCNode] = []
	
	# finding top left position
	var top_left: Vector2 = Vector2(INF, INF)
	for node_data: Dictionary in nodes_data:
		var pos: Vector2 = _deserialize_value(node_data.get('position'), TYPE_VECTOR2)
		if pos.x < top_left.x:
			top_left.x = pos.x
		if pos.y < top_left.y:
			top_left.y = pos.y
			
	var paste_offset: Vector2 = _target_pos - top_left

	for vc: HenVirtualCNode in global.SELECTED_VIRTUAL_CNODE:
		vc.unselect()
	global.SELECTED_VIRTUAL_CNODE.clear()

	# first pass: create all nodes
	for node_data: Dictionary in nodes_data:
		var old_id: int = node_data.get('id')
		var new_id: int = global.get_new_node_counter()
		node_id_map[old_id] = new_id

		var old_pos: Vector2 = _deserialize_value(node_data.get('position'), TYPE_VECTOR2)
		var new_pos: Vector2 = old_pos + paste_offset
		var has_res_data: bool = node_data.has('res_data') and not node_data.get('res_data').is_empty()

		var config: Dictionary = {
			id = new_id,
			position = new_pos,
			route = route
		}

		# copy all serialized properties except special ones
		for key: String in node_data:
			if key in ['id', 'position', 'inputs', 'outputs', 'flow_inputs', 'flow_outputs', 'input_code_value_map']:
				continue
			config[key] = node_data[key]

		if has_res_data:
			var inputs_data: Array = node_data.get('inputs', [])
			for input: Dictionary in inputs_data:
				var input_id: int = input.get('id', 0)
				io_id_map[input_id] = input_id

			var outputs_data: Array = node_data.get('outputs', [])
			for output: Dictionary in outputs_data:
				var output_id: int = output.get('id', 0)
				io_id_map[output_id] = output_id
		else:
			# process inputs with new ids
			var inputs_data: Array = node_data.get('inputs', [])
			var new_inputs: Array = []
			for input: Dictionary in inputs_data:
				var old_input_id: int = input.get('id', 0)
				var new_input_id: int = global.get_new_node_counter()
				io_id_map[old_input_id] = new_input_id

				var new_input: Dictionary = input.duplicate()
				new_input['id'] = new_input_id
				new_inputs.append(new_input)

			# process outputs with new ids
			var outputs_data: Array = node_data.get('outputs', [])
			var new_outputs: Array = []
			for output: Dictionary in outputs_data:
				var old_output_id: int = output.get('id', 0)
				var new_output_id: int = global.get_new_node_counter()
				io_id_map[old_output_id] = new_output_id

				var new_output: Dictionary = output.duplicate()
				new_output['id'] = new_output_id
				new_outputs.append(new_output)

			if not new_inputs.is_empty():
				config.inputs = new_inputs

			if not new_outputs.is_empty():
				config.outputs = new_outputs

			# handle input_code_value_map with new ids
			if node_data.has('input_code_value_map'):
				var old_map: Dictionary = node_data.get('input_code_value_map')
				var new_map: Dictionary = {}
				for old_key: Variant in old_map:
					var old_key_int: int = int(old_key)
					if io_id_map.has(old_key_int):
						new_map[io_id_map[old_key_int]] = old_map[old_key]
				config.input_code_value_map = new_map

		var v_cnode: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode(config)
		pasted_nodes.append(v_cnode)
		v_cnode.select()

	# second pass: create connections
	for conn_data: Dictionary in connections_data:
		var old_from_node_id: int = conn_data.get('from_node_id', 0)
		var old_to_node_id: int = conn_data.get('to_node_id', 0)
		var old_from_id: int = conn_data.get('from_id', 0)
		var old_to_id: int = conn_data.get('to_id', 0)

		if not node_id_map.has(old_from_node_id) or not node_id_map.has(old_to_node_id):
			continue

		if not io_id_map.has(old_from_id) or not io_id_map.has(old_to_id):
			continue

		var connection: HenVCConnectionData = HenVCConnectionData.new()
		connection.from_node_id = node_id_map[old_from_node_id]
		connection.to_node_id = node_id_map[old_to_node_id]
		connection.from_id = io_id_map[old_from_id]
		connection.to_id = io_id_map[old_to_id]
		connection.from_type = conn_data.get('from_type', &'')
		connection.to_type = conn_data.get('to_type', &'')

		global.SAVE_DATA.add_connection(connection)

	# third pass: create flow connections
	for flow_conn_data: Dictionary in flow_connections_data:
		var old_from_node_id: int = flow_conn_data.get('from_node_id', 0)
		var old_to_node_id: int = flow_conn_data.get('to_node_id', 0)
		var old_from_id: int = flow_conn_data.get('from_id', 0)
		var old_to_id: int = flow_conn_data.get('to_id', 0)

		if not node_id_map.has(old_from_node_id) or not node_id_map.has(old_to_node_id):
			continue

		var flow_connection: HenVCFlowConnectionData = HenVCFlowConnectionData.new()
		flow_connection.from_node_id = node_id_map[old_from_node_id]
		flow_connection.to_node_id = node_id_map[old_to_node_id]
		flow_connection.from_id = old_from_id
		flow_connection.to_id = old_to_id

		global.SAVE_DATA.add_flow_connection(flow_connection)

	for v_cnode: HenVirtualCNode in pasted_nodes:
		v_cnode.check_visibility()

	return pasted_nodes.size()


# serializes a virtual cnode using property introspection
static func _serialize_virtual_cnode(_vc: HenVirtualCNode) -> Dictionary:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var data: Dictionary = {}

	for prop: Dictionary in _vc.get_property_list():
		if not (prop.usage & PROPERTY_USAGE_STORAGE):
			continue

		var prop_name: String = prop.name
		if prop_name in SKIP_PROPERTIES:
			continue

		var value = _vc.get(prop_name)
		var is_required: bool = prop_name in REQUIRED_PROPERTIES

		match typeof(value):
			TYPE_NIL:
				if is_required:
					data[prop_name] = null
			TYPE_VECTOR2:
				if value != Vector2.ZERO or is_required:
					data[prop_name] = var_to_str(value)
			TYPE_STRING, TYPE_STRING_NAME:
				if (value != '' and value != &'') or is_required:
					data[prop_name] = value
			TYPE_DICTIONARY:
				if not value.is_empty() or is_required:
					data[prop_name] = value.duplicate()
			TYPE_ARRAY:
				pass
			TYPE_BOOL:
				data[prop_name] = value
			_:
				if value != null or is_required:
					data[prop_name] = value

	var inputs: Array = []
	for input: HenVCInOutData in _vc.get_inputs(global.SAVE_DATA):
		if input != null:
			inputs.append(_serialize_resource(input))
	if not inputs.is_empty():
		data['inputs'] = inputs

	var outputs: Array = []
	for output: HenVCInOutData in _vc.get_outputs(global.SAVE_DATA):
		if output != null:
			outputs.append(_serialize_resource(output))
	if not outputs.is_empty():
		data['outputs'] = outputs

	var flow_inputs: Array = []
	for flow_input: HenVCFlow in _vc.get_flow_inputs(global.SAVE_DATA):
		if flow_input != null:
			flow_inputs.append(_serialize_resource(flow_input))
	if not flow_inputs.is_empty():
		data['flow_inputs'] = flow_inputs

	var flow_outputs: Array = []
	for flow_output: HenVCFlow in _vc.get_flow_outputs(global.SAVE_DATA):
		if flow_output != null:
			flow_outputs.append(_serialize_resource(flow_output))
	if not flow_outputs.is_empty():
		data['flow_outputs'] = flow_outputs

	return data


# serializes a resource using property introspection
static func _serialize_resource(_res: Resource) -> Dictionary:
	if _res == null:
		return {}

	var data: Dictionary = {}

	for prop: Dictionary in _res.get_property_list():
		if not (prop.usage & PROPERTY_USAGE_STORAGE):
			continue

		var prop_name: String = prop.name
		if prop_name in ['line_ref', 'from_old_pos', 'to_old_pos']:
			continue

		var value = _res.get(prop_name)
		var is_required: bool = prop_name in REQUIRED_PROPERTIES

		match typeof(value):
			TYPE_NIL:
				if is_required:
					data[prop_name] = null
			TYPE_VECTOR2:
				if value != Vector2.ZERO or is_required:
					data[prop_name] = var_to_str(value)
			TYPE_STRING, TYPE_STRING_NAME:
				if (value != '' and value != &'') or is_required:
					data[prop_name] = value if value != null else ''
			TYPE_DICTIONARY:
				if not value.is_empty() or is_required:
					data[prop_name] = value.duplicate()
			TYPE_ARRAY:
				if not value.is_empty():
					var has_resources: bool = false
					for item in value:
						if item is Resource:
							has_resources = true
							break

					if has_resources:
						var arr: Array = []
						for item in value:
							if item != null:
								arr.append(_serialize_resource(item))
						data[prop_name] = arr
					else:
						data[prop_name] = value.duplicate()
			_:
				if value != null or is_required:
					data[prop_name] = value

	return data


# deserializes a value back to its original type
static func _deserialize_value(_value, _type: int):
	if _value == null:
		return Vector2.ZERO if _type == TYPE_VECTOR2 else null

	match _type:
		TYPE_VECTOR2:
			if _value is String:
				return str_to_var(_value)
			return _value
		_:
			return _value