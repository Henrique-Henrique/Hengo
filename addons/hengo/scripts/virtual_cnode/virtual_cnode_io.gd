@tool
@abstract
class_name HenVirtualCNodeIO extends HenVirtualCNodeFlow

@export var inputs: Array[HenVCInOutData]:
	set(value):
		inputs = value
		for io in inputs:
			_connect_io(io, true)

@export var outputs: Array[HenVCInOutData]:
	set(value):
		outputs = value
		for io in outputs:
			_connect_io(io, false)

@export var input_code_value_map: Dictionary = {}

signal io_hovered(_context: Dictionary)
signal expression_saved(_context: Dictionary)
signal method_picker_requested(_context: Dictionary)
signal changed_code_value(_id: StringName, _context: Dictionary)


func get_input(_id: StringName, _save_data: HenSaveData) -> HenVCInOutData:
	for input: HenVCInOutData in get_inputs(_save_data):
		if input.id == _id:
			return input
	
	return null


func get_output(_id: StringName, _save_data: HenSaveData) -> HenVCInOutData:
	for output: HenVCInOutData in get_outputs(_save_data):
		if output.id == _id:
			return output
	
	return null


func on_connection_command_requested(_context: Dictionary) -> void:
	var connection: HenVCConnectionReturn
	var r_data: CNodeInOutConnectionData = _context.remote_data

	# determines creation direction based on type
	if _context.type == "in":
		connection = create_input_connection(
			_context.local_port_id,
			r_data.in_out.id,
			self,
			r_data.vc
		)
	else:
		connection = (r_data.vc as HenVirtualCNode).create_input_connection(
			r_data.in_out.id,
			_context.local_port_id,
			r_data.vc,
			self
		)

	# executes history logic if connection command is valid
	if connection:
		var global: HenGlobal = Engine.get_singleton(&'Global')
		
		global.history.create_action('Add Connection')
		global.history.add_do_method(connection.add)
		global.history.add_do_reference(connection)
		global.history.add_undo_method(connection.remove)
		global.history.commit_action()


func create_input_connection(_id: StringName, _from_id: StringName, _to: HenVirtualCNode, _from: HenVirtualCNode) -> HenVCConnectionReturn:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var input: HenVCInOutData = get_input(_id, global.SAVE_DATA)
	var output: HenVCInOutData = _from.get_output(_from_id, global.SAVE_DATA)

	if not input or not output:
		return
	
	if not HenUtils.is_type_relation_valid(output.type, input.type):
		return

	var connection: HenVCConnectionData = HenVCConnectionData.new()

	connection.from_type = output.type
	connection.from_id = output.id
	connection.from_node_id = _from.id
	connection.to_node_id = _to.id
	connection.to_type = input.type
	connection.to_id = input.id

	return HenVCConnectionReturn.new(connection, _id)


func get_input_connection(_id: StringName, _virtual_cnode: HenVirtualCNode) -> HenVCConnectionData:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	for input_connection: HenVCConnectionData in global.SAVE_DATA.get_connection_from_vc(_virtual_cnode):
		if input_connection.get_to(global.SAVE_DATA) == _virtual_cnode and input_connection.to_id == _id:
			return input_connection

	return null


func clear_in_out(_is_input: bool) -> void:
	if _is_input:
		inputs.clear()
	else:
		outputs.clear()


func input_has_connection(_id: StringName, _save_data: HenSaveData) -> bool:
	for input_connection: HenVCConnectionData in _save_data.get_connections_by_id(id):
		if input_connection.to_id == _id and input_connection.to_node_id == id:
			return true

	return false


func output_has_connection(_id: StringName, _save_data: HenSaveData) -> bool:
	for output_connection: HenVCConnectionData in _save_data.get_connections_by_id(id):
		if output_connection.from_id == _id and output_connection.from_node_id == id:
			return true

	return false


func get_input_connection_command(_id: StringName, _save_data: HenSaveData) -> HenVCConnectionReturn:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	for connection: HenVCConnectionData in global.SAVE_DATA.get_connections_by_id(id):
		if connection.to_id == _id:
			return HenVCConnectionReturn.new(connection)

	return null


func remove_io_connection(_ref: HenVCInOutData) -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var connection_remove: Array = []

	for connection: HenVCConnectionData in global.SAVE_DATA.get_connections_by_id(id):
		if _ref.id == connection.to_id:
			connection_remove.append(connection)

	for connection: HenVCConnectionData in connection_remove:
		global.SAVE_DATA.remove_connection(connection)

		if connection.line_ref:
			connection.line_ref.visible = false

		connection.get_from(global.SAVE_DATA).cnode_need_update.emit()
	
	cnode_need_update.emit()


func on_in_out_moved(_is_input: bool, _pos: int, _in_ou_ref: HenVCInOutData) -> void:
	var is_input: bool = _is_input
	var index_slice: int = 0

	match sub_type:
		HenVirtualCNode.SubType.FUNC_INPUT, HenVirtualCNode.SubType.SIGNAL_ENTER, HenVirtualCNode.SubType.MACRO_INPUT:
			if is_input: is_input = false
			else: return
		HenVirtualCNode.SubType.FUNC_OUTPUT, HenVirtualCNode.SubType.MACRO_OUTPUT:
			if not is_input: is_input = true
			else: return
		HenVirtualCNode.SubType.SIGNAL_CONNECTION:
			# they have reference input, so start from 1
			index_slice = 1

	var new_idx: int = _pos + index_slice

	if is_input:
		HenUtils.move_array_item_to_idx(inputs, _in_ou_ref, new_idx)
	else:
		HenUtils.move_array_item_to_idx(outputs, _in_ou_ref, _pos + index_slice)

	cnode_need_update.emit()


func on_in_out_deleted(_is_input: bool, _in_ou_ref: HenVCInOutData) -> void:
	var is_input: bool = _is_input

	match sub_type:
		HenVirtualCNode.SubType.FUNC_INPUT, HenVirtualCNode.SubType.SIGNAL_ENTER, HenVirtualCNode.SubType.MACRO_INPUT:
			if is_input: is_input = false
			else: return
		HenVirtualCNode.SubType.FUNC_OUTPUT, HenVirtualCNode.SubType.MACRO_OUTPUT:
			if not is_input: is_input = true
			else: return

	#TODO remove connections
	if is_input:
		inputs.erase(_in_ou_ref)
	else:
		outputs.erase(_in_ou_ref)

	remove_io_connection(_in_ou_ref)
	cnode_need_update.emit()


func on_in_out_added(_is_input: bool, _data: Dictionary, _check_types: bool = true) -> HenVCInOutData:
	# restrict creation by sub_type
	if _check_types:
		match sub_type:
			HenVirtualCNode.SubType.FUNC_INPUT, HenVirtualCNode.SubType.MACRO_INPUT:
				if not _is_input: return
				_is_input = false
			HenVirtualCNode.SubType.FUNC_OUTPUT, HenVirtualCNode.SubType.MACRO_OUTPUT:
				if _is_input: return
				_is_input = true
			HenVirtualCNode.SubType.SIGNAL_ENTER:
				_is_input = false


	var in_out: HenVCInOutData = create_io(_is_input, _data)

	cnode_need_update.emit()
	return in_out


func create_io(_is_input: bool, _data: Dictionary) -> HenVCInOutData:
	# injecting values from map into data
	if _is_input and input_code_value_map.has(_data.get(&'id', -1)):
		var map_value: Dictionary = input_code_value_map.get(_data.id)

		if map_value.get(&'type') == _data.get(&'type'):
			_data.value = map_value.get(&'value')
			_data.code_value = map_value.get(&'code_value', '')

	var in_out: HenVCInOutData = HenVCInOutData.create(_data)


	if _is_input:
		inputs.append(in_out)
	else:
		outputs.append(in_out)

	_connect_io(in_out, _is_input)

	return in_out


func _on_changed_code_value(_id: StringName, _context: Dictionary, _is_input: bool) -> void:
	if _is_input:
		input_code_value_map.set(_id, _context)
	
	changed_code_value.emit(_id, _context)


func on_need_update() -> void:
	cnode_need_update.emit()


func on_in_out_type_changed(_old_type: StringName, _type: StringName, _ref: HenVCInOutData) -> void:
	if HenUtils.is_type_relation_valid(_old_type, _type):
		remove_io_connection(_ref)


func get_inputs(_save_data: HenSaveData) -> Array[HenVCInOutData]:
	var res = get_res(_save_data)

	if res and res is HenSaveResType:
		var new_data_list: Array = (res as HenSaveResType).get_inputs(sub_type)

		for i: int in new_data_list.size():
			var data: Dictionary = new_data_list[i]

			if i < inputs.size():
				var existing: HenVCInOutData = inputs[i]
				# prevents recursion: only assign if value actually changed
				if existing.id != str(data.get('id')): existing.id = str(data.get('id'))
				if existing.name != data.get('name'): existing.name = data.get('name')
				if existing.type != data.get('type'): existing.type = data.get('type')
			else:
				create_io(true, data)
		
		if inputs.size() > new_data_list.size():
			inputs.resize(new_data_list.size())
			
	return inputs


func get_outputs(_save_data: HenSaveData) -> Array[HenVCInOutData]:
	var res = get_res(_save_data)
	if res and res is HenSaveResType:
		var new_data_list: Array = (res as HenSaveResType).get_outputs(sub_type)

		for i: int in new_data_list.size():
			var data: Dictionary = new_data_list[i]

			if i < outputs.size():
				var existing: HenVCInOutData = outputs[i]
				# prevents recursion: only assign if value actually changed
				if existing.id != data.get('id'): existing.id = data.get('id')
				if existing.name != data.get('name'): existing.name = data.get('name')
				if existing.type != data.get('type'): existing.type = data.get('type')
			else:
				create_io(false, data)
		
		# safer and faster way to remove excess elements
		if outputs.size() > new_data_list.size():
			outputs.resize(new_data_list.size())
	
	return outputs


func _connect_io(_io: HenVCInOutData, _is_input: bool) -> void:
	if not _io.connection_request.is_connected(on_connection_command_requested): _io.connection_request.connect(on_connection_command_requested)
	if not _io.io_hovered.is_connected(io_hovered.emit): _io.io_hovered.connect(io_hovered.emit)
	if not _io.expression_saved.is_connected(expression_saved.emit): _io.expression_saved.connect(expression_saved.emit)
	if not _io.method_picker_requested.is_connected(method_picker_requested.emit): _io.method_picker_requested.connect(method_picker_requested.emit)
	if not _io.changed_code_value.is_connected(_on_changed_code_value): _io.changed_code_value.connect(_on_changed_code_value.bind(_is_input))