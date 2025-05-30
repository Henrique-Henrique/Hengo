@tool
class_name HenVirtualCNode extends Object

enum Type {
	DEFAULT,
	IF,
	FOR,
	IMG,
	EXPRESSION,
	STATE,
	STATE_START,
	STATE_EVENT,
	MACRO,
	MACRO_INPUT,
	MACRO_OUTPUT
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
	PASS,
	STATE,
	STATE_START,
	STATE_EVENT,
	SIGNAL_ENTER,
	SIGNAL_CONNECTION,
	SIGNAL_DISCONNECTION,
	MACRO,
	MACRO_INPUT,
	MACRO_OUTPUT,
	OVERRIDE_VIRTUAL
}

var name: String
var name_to_code: String
var id: int
var position: Vector2
var is_showing: bool = false
var cnode_ref: HenCnode
var inputs: Array[InOutData]
var outputs: Array[InOutData]
var size: Vector2
var type: Type
var sub_type: SubType
var route: Dictionary
var route_ref: Dictionary
var category: StringName
var virtual_cnode_list: Array = []
var virtual_sub_type_vc_list: Array = []
var ref_id: int = -1
var ref: Object
var is_deleted: bool = false

var input_connections: Array = []
var output_connections: Array = []
var flow_connections: Array = []
var from_flow_connections: Array = []


class InOutData extends Object:
	var name: String
	var type: StringName
	var sub_type: StringName
	var category: StringName
	var is_ref: bool
	var code_value: String
	var value: Variant
	var data: Variant
	var is_prop: bool
	var is_static: bool
	var ref_id: int = -1
	var ref: Object
	var ref_change_rule: RefChangeRule

	signal update_changes
	signal moved
	signal deleted

	enum RefChangeRule {
		NONE = 0,
		TYPE_CHANGE = 1,
		VALUE_CODE_VALUE_CHANGE = 2,
		IS_PROP = 3
	}

	func _init(_data: Dictionary) -> void:
		name = _data.name
		type = _data.type

		if _data.has('sub_type'): sub_type = _data.sub_type
		if _data.has('category'): category = _data.category
		if _data.has('is_ref'): is_ref = _data.is_ref
		if _data.has('code_value'): code_value = _data.code_value
		if _data.has('value'): value = _data.value
		if _data.has('data'): data = _data.data
		if _data.has('is_prop'): is_prop = _data.is_prop
		if _data.has('is_static'): is_static = _data.is_static
		if _data.has('ref'): set_ref(_data.ref, _data.ref_change_rule if _data.has('ref_change_rule') else RefChangeRule.NONE)

	func set_ref(_ref, _ref_change_rule: RefChangeRule = RefChangeRule.NONE) -> void:
		ref = _ref
		# ref is required to have id to save and load work
		ref_id = _ref.id
		ref_change_rule = _ref_change_rule

		# when param is moved
		if ref.has_signal('moved') and not ref.is_connected('moved', _on_move):
			ref.moved.connect(_on_move)

		if ref.has_signal('deleted') and not ref.is_connected('deleted', _on_delete):
			ref.deleted.connect(_on_delete)

		if _ref.has_signal('data_changed') and not ref.is_connected('data_changed', on_data_changed):
			_ref.data_changed.connect(on_data_changed)
		
		update_changes.emit()
	
	func _on_move(_is_input: bool, _pos: int) -> void:
		moved.emit(_is_input, _pos, self)

	func _on_delete(_is_input: bool) -> void:
		deleted.emit(_is_input, self)

	func remove_ref() -> void:
		ref_id = -1

		if ref:
			for signal_connetion: Dictionary in ref.get_signal_connection_list('data_changed'):
				signal_connetion.signal.disconnect(signal_connetion.callable)
		
		ref_change_rule = RefChangeRule.NONE
		update_changes.emit()

	func on_data_changed(_name: String, _value) -> void:
		if ref_change_rule != RefChangeRule.NONE:
			match ref_change_rule:
				RefChangeRule.TYPE_CHANGE:
					if _name != 'type':
						return
				RefChangeRule.VALUE_CODE_VALUE_CHANGE:
					if not ['value', 'code_value'].has(_name):
						return
				RefChangeRule.IS_PROP:
					if _name == 'type':
						# if new type is diffent, reset input
						if not HenUtils.is_type_relation_valid(_value, type):
						# if _value != 'Variant' and type != 'Variant' and _value != type:
							reset_input_value()
							remove_ref()
							return
					
					if not ['value', 'code_value'].has(_name):
						return


		set(_name, _value)

		if sub_type != '@dropdown':
			match _name:
				'type':
					reset_input_value()

		update_changes.emit()


	func get_save() -> Dictionary:
		var dt: Dictionary = {
			name = name,
			type = type
		}

		if sub_type: dt.sub_type = sub_type
		if category: dt.category = category
		if is_ref: dt.is_ref = is_ref
		if code_value: dt.code_value = code_value
		if value: dt.value = value
		if data: dt.data = data
		if is_prop: dt.is_prop = is_prop
		if is_static: dt.is_static = is_static
		if ref_id > 0: dt.ref_id = ref_id
		if ref_change_rule != RefChangeRule.NONE: dt.ref_change_rule = int(ref_change_rule)

		return dt
	

	func reset_input_value() -> void:
		category = &'default_value'
		is_prop = false

		if HenGlobal.script_config.type == type:
			code_value = '_ref.'
			is_ref = true
			return
		
		match type:
			'String', 'NodePath', 'StringName':
				code_value = '""'
			'int':
				code_value = '0'
			'float':
				code_value = '0.'
			'Vector2':
				code_value = 'Vector2(0, 0)'
			'bool':
				code_value = 'false'
			'Variant':
				code_value = 'null'
			_:
				if HenEnums.VARIANT_TYPES.has(type):
					code_value = type + '()'
				elif ClassDB.can_instantiate(type):
					code_value = type + '.new()'

		match type:
			'String', 'NodePath', 'StringName':
				value = ''
			_:
				value = code_value


class FlowConnection extends Object:
	var name: String: set = _on_change_name
	var id: int
	var ref: Object
	
	signal update_changes
	signal data_changed
	signal moved
	signal deleted

	func _on_change_name(_name: String) -> void:
		name = _name
		data_changed.emit('value', _name)
		data_changed.emit('code_value', _name)

	func _init(_data: Dictionary = {}) -> void:
		name = _data.name if _data.has('name') else ''
		id = _data.id if _data.has('id') else HenGlobal.get_new_node_counter()

		if _data.has('ref'): set_ref(_data.ref)

	func set_ref(_ref) -> void:
		ref = _ref
		# when param is moved
		if ref.has_signal('moved'):
			ref.moved.connect(_on_move)

		if ref.has_signal('deleted'):
			ref.deleted.connect(_on_delete)
		
		if _ref.has_signal('data_changed'):
			_ref.data_changed.connect(on_data_changed)
	

	func _on_move(_pos: int) -> void:
		moved.emit(self is FromFlowConnection, _pos, self)

	func _on_delete() -> void:
		deleted.emit(self is FromFlowConnection, self)
	
	func on_data_changed(_name: String, _value) -> void:
		set(_name, _value)
		update_changes.emit()


class FlowConnectionData extends FlowConnection:
	var line_ref: HenFlowConnectionLine
	var from_idx: int
	var from_pos: Vector2
	var to_pos: Vector2
	var from: HenVirtualCNode
	var to: HenVirtualCNode
	var to_idx: int
	var to_from_ref: FromFlowConnection

	func get_save() -> Dictionary:
		return {
			idx = from_idx,
			to_id = to.id,
			to_idx = to_idx
		}
		

class FromFlowConnection extends FlowConnection:
	var from_connections: Array[FlowConnectionData]


class ConnectionData extends Object:
	var idx: int
	var line_ref: HenConnectionLine
	var type: StringName


class InputConnectionData extends ConnectionData:
	var from: HenVirtualCNode
	var from_idx: int
	var from_ref: OutputConnectionData
	var from_old_pos: Vector2
	var from_type: StringName
	var input_ref: InOutData


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
	var output_ref: InOutData


class FlowConnectionReturn:
	var flow_connection: FlowConnectionData
	
	var to: HenVirtualCNode
	var to_idx: int
	var from: HenVirtualCNode
	var from_idx: int
	var to_from_ref: FromFlowConnection

	# old
	var old_to: HenVirtualCNode
	var old_to_idx: int
	var old_from_idx: int
	var old_from: HenVirtualCNode
	var old_to_from_ref: FromFlowConnection

	func _init(_flow: FlowConnectionData, _from_idx: int, _to: HenVirtualCNode, _to_idx: int, _from: HenVirtualCNode, _to_from_ref: FromFlowConnection) -> void:
		from_idx = _from_idx
		flow_connection = _flow
		to = _to
		to_idx = _to_idx
		from = _from
		to_from_ref = _to_from_ref

	func add() -> void:
		# remove other flow connection
		if flow_connection.to:
			flow_connection.to_from_ref.from_connections.erase(flow_connection)

			if flow_connection.line_ref:
				flow_connection.line_ref.visible = false
				flow_connection.line_ref = null
			
			old_to = flow_connection.to
			old_from_idx = flow_connection.from_idx
			old_to_idx = flow_connection.to_idx
			old_from = flow_connection.from
			old_to_from_ref = flow_connection.to_from_ref

		flow_connection.from_idx = from_idx
		flow_connection.to = to
		flow_connection.to_idx = to_idx
		flow_connection.from = from
		flow_connection.to_from_ref = to_from_ref
		flow_connection.line_ref = null

		flow_connection.to_from_ref.from_connections.append(flow_connection)

		flow_connection.from.update()
		flow_connection.to.update()

	func remove() -> void:
		flow_connection.to = null
		flow_connection.to_from_ref.from_connections.erase(flow_connection)

		if flow_connection.line_ref:
			flow_connection.line_ref.visible = false
		
		flow_connection.line_ref = null

		# adding old flow connection
		if old_to:
			flow_connection.from_idx = old_from_idx
			flow_connection.to = old_to
			flow_connection.to_idx = old_to_idx
			flow_connection.from = old_from
			flow_connection.to_from_ref = old_to_from_ref

			old_to_from_ref.from_connections.append(flow_connection)
			old_to.update()

		old_to = null

		flow_connection.from.update()

		
class ConnectionReturn:
	var input_connection: InputConnectionData
	var output_connection: OutputConnectionData
	var from: HenVirtualCNode
	var to: HenVirtualCNode

	var old_inputs_connections: Array

	func _init(_in: InputConnectionData, _out: OutputConnectionData, _from: HenVirtualCNode, _to: HenVirtualCNode) -> void:
		input_connection = _in
		output_connection = _out
		from = _from
		to = _to
	

	func add(_update: bool = true) -> void:
		# removing old inputs
		old_inputs_connections.append_array(to.input_connections)

		for connection: InputConnectionData in to.input_connections:
			connection.from.output_connections.erase(connection.from_ref)

			if connection.line_ref:
				connection.line_ref.visible = false
				connection.line_ref = null
				connection.from_ref.line_ref = null

		to.input_connections.clear()

		from.output_connections.append(output_connection)
		to.input_connections.append(input_connection)

		if _update:
			from.update()
			to.update()

	func remove() -> void:
		from.output_connections.erase(output_connection)
		to.input_connections.erase(input_connection)

		if input_connection.line_ref:
			input_connection.line_ref.visible = false
			input_connection.line_ref = null
			output_connection.line_ref = null

		# add old input connections
		to.input_connections.append_array(old_inputs_connections)
	
		for connection: InputConnectionData in old_inputs_connections:
			connection.from.output_connections.append(connection.from_ref)

		old_inputs_connections.clear()

		input_connection.input_ref.reset_input_value()

		from.update()
		to.update()

class VCNodeReturn:
	var v_cnode: HenVirtualCNode
	var old_inputs_connections: Array
	var old_outputs_connections: Array
	var old_flow_connections: Array
	var old_from_flow_connections: Array

	func _init(_v_cnode: HenVirtualCNode) -> void:
		v_cnode = _v_cnode


	func add() -> void:
		if not v_cnode.route_ref.ref.virtual_cnode_list.has(v_cnode):
			v_cnode.route_ref.ref.virtual_cnode_list.append(v_cnode)

		if v_cnode.sub_type == SubType.MACRO:
			var _ref: HenSideBar.MacroData = v_cnode.ref

			if not _ref.macro_ref_list.has(v_cnode):
				_ref.macro_ref_list.append(v_cnode)

		v_cnode.input_connections.append_array(old_inputs_connections)
		v_cnode.output_connections.append_array(old_outputs_connections)

		# inputs
		for input_connection: InputConnectionData in old_inputs_connections:
			input_connection.from.output_connections.append(input_connection.from_ref)

		# outputs
		for input_connection: OutputConnectionData in old_outputs_connections:
			input_connection.to.input_connections.append(input_connection.to_ref)

		# flow connection
		for flow_connection: FlowConnectionData in old_flow_connections:
			if flow_connection.to:
				flow_connection.to_from_ref.from_connections.append(flow_connection)
				flow_connection.to.update()


		# from flow connections
		for from_flow_connection: FromFlowConnection in old_from_flow_connections:
			for flow_connection: FlowConnectionData in from_flow_connection.from_connections:
				flow_connection.to = v_cnode
				flow_connection.from.update()

		old_inputs_connections.clear()
		old_outputs_connections.clear()
		old_from_flow_connections.clear()
		old_flow_connections.clear()

		v_cnode.is_deleted = false
		v_cnode.update()
	

	func remove() -> void:
		v_cnode.route_ref.ref.virtual_cnode_list.erase(v_cnode)

		if v_cnode.sub_type == SubType.MACRO:
			(v_cnode.ref as HenSideBar.MacroData).macro_ref_list.erase(v_cnode)

		old_inputs_connections.append_array(v_cnode.input_connections)
		old_outputs_connections.append_array(v_cnode.output_connections)
		old_flow_connections.append_array(v_cnode.flow_connections)
		old_from_flow_connections.append_array(v_cnode.from_flow_connections)

		# inputs
		for input_connection: InputConnectionData in v_cnode.input_connections:
			input_connection.from.output_connections.erase(input_connection.from_ref)

			if input_connection.line_ref:
				input_connection.line_ref.visible = false

				# remove the line reference from both inputs
				input_connection.line_ref = null
				input_connection.from_ref.line_ref = null

		# outputs
		for input_connection: OutputConnectionData in v_cnode.output_connections:
			input_connection.to.input_connections.erase(input_connection.to_ref)

			if input_connection.line_ref:
				input_connection.line_ref.visible = false

				# remove the line reference from both inputs
				input_connection.line_ref = null
				input_connection.to_ref.line_ref = null

		# flow connections
		for flow_connection: FlowConnectionData in v_cnode.flow_connections:
			if flow_connection.line_ref:
				flow_connection.line_ref.visible = false
				flow_connection.line_ref = null
			
			if flow_connection.to:
				flow_connection.to_from_ref.from_connections.erase(flow_connection)

		# from flow connections
		for from_flow_connection: FromFlowConnection in v_cnode.from_flow_connections:
			for from_connection: FlowConnectionData in from_flow_connection.from_connections:
				if from_connection.line_ref:
					from_connection.line_ref.visible = false
					from_connection.line_ref = null

				from_connection.to = null

		v_cnode.input_connections.clear()
		v_cnode.output_connections.clear()
		v_cnode.hide()
		v_cnode.is_deleted = true


func check_visibility(_rect: Rect2 = HenGlobal.CAM.get_rect()) -> void:
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
	is_showing = true

	for cnode: HenCnode in HenGlobal.cnode_pool:
		if not cnode.visible:
			cnode.position = position
			cnode.visible = true
			cnode.route_ref = HenRouter.current_route
			cnode.change_name(name)
			cnode.virtual_ref = self
			cnode.category = category

			var idx: int = 0

			# clearing inputs and change to new
			for input: HenCnodeInOut in cnode.get_node('%InputContainer').get_children():
				input.visible = false

				if idx < inputs.size():
					input.reset()
					input.visible = true
					
					var input_data: InOutData = inputs[idx]

					input.change_name(input_data.name)

					input.input_ref = input_data
					input.custom_data = input_data.data
					input.category = input_data.category
					input.sub_type = input_data.sub_type
					
					if input_data.type:
						if input_data.is_prop:
							input.reset_in_props()
							input.add_prop_ref(input_data.value if input_data.value else null, 0)
						else:
							input.change_type(
								input_data.type, input_data.value if input_data.value else null,
								'',
								not input_data.is_static
							)
					else:
						input.reset_in_props()
						input.set_in_prop(input_data.value if input_data.value else null, not input_data.is_static)
						input.root.reset_size()
					
					if input_data.is_static:
						(input.get_node('%CNameInput') as HBoxContainer).set('theme_override_constants/separation', 0)
						(input.get_node('%Connector') as TextureRect).visible = false
					else:
						(input.get_node('%CNameInput') as HBoxContainer).set('theme_override_constants/separation', 8)
						(input.get_node('%Connector') as TextureRect).visible = true

				idx += 1

			idx = 0

			# clearing outputs and change to new
			for output: HenCnodeInOut in cnode.get_node('%OutputContainer').get_children():
				output.visible = false

				if idx < outputs.size():
					output.visible = true
					
					var output_data: InOutData = outputs[idx]
					
					output.input_ref = output_data
					output.custom_data = output_data.data
					output.category = output_data.category
					output.sub_type = output_data.sub_type

					output.change_name(output_data.name)
					output.change_type(
						output_data.type,
						output_data.value if output_data.value else null,
						output_data.sub_type if output_data.sub_type else &''
					)

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
				(flow_c.get_node('FlowSlot/Label') as Label).visible = false

			# Showing Flows
			match type as Type:
				Type.DEFAULT:
					var container = flow_container.get_child(0)
					var label: Label = container.get_node('FlowSlot/Label')
					
					container.visible = true
					(from_flow_container.get_child(0) as HenFromFlow).visible = true

					label.visible = false
					label.text = ''
				Type.IF:
					(from_flow_container.get_child(0) as HenFromFlow).visible = true
				Type.STATE:
					(from_flow_container.get_child(0) as HenFromFlow).visible = true
					
			idx = 0

			for from_flow_connection: FromFlowConnection in from_flow_connections:
				# showing from flow connections
				var my_from_flow_container = from_flow_container.get_child(idx)
				var label: Label = my_from_flow_container.get_node('%Label')

				if from_flow_connection.name:
					label.visible = true
					label.text = from_flow_connection.name
				else:
					label.visible = false

				my_from_flow_container.visible = true

				if from_flow_connection.from_connections.is_empty():
					idx += 1
					continue

				for from_connection: FlowConnectionData in from_flow_connection.from_connections:
					var line: HenFlowConnectionLine

					if from_connection.line_ref:
						line = from_connection.line_ref
					else:
						line = HenPool.get_flow_line_from_pool()
						from_connection.line_ref = line

					# signal to update flow connection line
					if not cnode_ref.is_connected('on_move', line.update_line):
						cnode_ref.connect('on_move', line.update_line)

					line.from_flow_idx = idx
					line.to_cnode = cnode_ref
					line.from_virtual_pos = from_connection.from_pos
					line.to_pool_visible = true

				(cnode_ref.get_node('%FromFlowContainer').get_child(idx).get_node('%Arrow') as TextureRect).visible = true

				idx += 1

			idx = 0


			for flow_connection: FlowConnectionData in flow_connections:
				# showing flow connections
				var my_flow_container = flow_container.get_child(idx)
				
				if flow_connection.name:
					var my_flow_label: Label = (my_flow_container.get_node('FlowSlot/Label') as Label)
					my_flow_label.visible = true
					my_flow_label.text = flow_connection.name
				
				my_flow_container.visible = true

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
			cnode.pivot_offset = cnode.size / 2
			size = cnode.size

			cnode.modulate = Color.WHITE

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
				if not connection.from_connections.is_empty():
					for from_connection: FlowConnectionData in connection.from_connections:
						if from_connection.line_ref:
							from_connection.line_ref.update_line()
			

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
				var pos: Vector2 = HenGlobal.CAM.get_relative_vec2(line_data.line_ref.output.global_position) + line_data.line_ref.conn_size
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
				var pos: Vector2 = HenGlobal.CAM.get_relative_vec2(line_data.line_ref.input.global_position) + line_data.line_ref.conn_size
				line_data.to_ref.from_old_pos = pos
				line_data.to_ref.line_ref.from_virtual_pos = pos
			else:
				line_data.line_ref.visible = false
			
			line_data.line_ref = null


		for flow_connection: FlowConnectionData in flow_connections:
			if flow_connection.line_ref:
				flow_connection.line_ref.from_pool_visible = false
			
				if flow_connection.to.is_showing:
					var pos: Vector2 = HenGlobal.CAM.get_relative_vec2(flow_connection.line_ref.from_connector.global_position) + flow_connection.line_ref.from_connector.size / 2
					flow_connection.from_pos = pos
					flow_connection.line_ref.from_virtual_pos = pos
				else:
					flow_connection.line_ref.visible = false
					flow_connection.line_ref = null

		var idx: int = 0
		var from_flow_container: HBoxContainer = cnode_ref.get_node('%FromFlowContainer')

		for from_flow_connection: FromFlowConnection in from_flow_connections:
			for from_connection: FlowConnectionData in from_flow_connection.from_connections:
				if from_connection.line_ref:
					var line: HenFlowConnectionLine = from_connection.line_ref

					if line:
						line.to_pool_visible = false

						if from_connection.from.is_showing:
							var pos: Vector2 = HenGlobal.CAM.get_relative_vec2((from_flow_container.get_child(idx) as HenFromFlow).global_position)
							from_connection.to_pos = pos
							line.to_virtual_pos = pos
						else:
							line.visible = false
							from_connection.line_ref = null
				
			idx += 1


		cnode_ref.visible = false
		cnode_ref.virtual_ref = null
		cnode_ref = null


func update() -> void:
	if is_deleted or (not route_ref or not HenRouter.current_route or route_ref.id != HenRouter.current_route.id):
		hide()
		return

	hide()
	check_visibility()


func get_save() -> Dictionary:
	var data: Dictionary = {
		id = id,
		type = type,
		sub_type = sub_type,
		name = name,
		position = var_to_str(position),
		size = var_to_str(size),
		input_connections = [],
		output_connections = [],
		flow_connections = []
	}

	if ref_id > 0:
		data.ref_id = ref_id

	if not inputs.is_empty():
		data.inputs = []

		for input: InOutData in inputs:
			data.inputs.append(input.get_save())
	
	if not outputs.is_empty():
		data.outputs = []

		for output: InOutData in outputs:
			data.outputs.append(output.get_save())

	if category:
		data.category = category

	for flow_connection: FlowConnectionData in flow_connections:
		if not flow_connection.to: continue
		data.flow_connections.append(flow_connection.get_save())

	for input: InputConnectionData in input_connections:
		data.input_connections.append(input.get_save())

	if not virtual_cnode_list.is_empty():
		data.virtual_cnode_list = []

		for v_cnode: HenVirtualCNode in virtual_cnode_list:
			data.virtual_cnode_list.append(v_cnode.get_save())
	
	# these types don't need to save the flow connections, are hengo's native
	match type:
		Type.IF, Type.FOR, Type.DEFAULT:
			if not flow_connections.is_empty():
				var flows: Array = []

				for flow_connection: FlowConnectionData in flow_connections:
					if flow_connection.name:
						flows.append({name = flow_connection.name})
				
				if not flows.is_empty(): data.to_flow = flows
		Type.STATE:
			data.to_flow = []
			for flow_connection: FlowConnectionData in flow_connections:
					if flow_connection.name:
						data.to_flow.append({name = flow_connection.name, id = flow_connection.id})

	return data


func add_flow_connection(_idx: int, _to_idx: int, _to: HenVirtualCNode) -> FlowConnectionReturn:
	var flow_connection: FlowConnectionData = flow_connections[_idx]
	var flow_from_connection: FromFlowConnection = _to.from_flow_connections[_to_idx]

	return FlowConnectionReturn.new(flow_connection, _idx, _to, _to_idx, self, flow_from_connection)


func get_flow_connection(_idx: int) -> FlowConnectionReturn:
	if _idx > flow_connections.size():
		return null

	var flow_connection: FlowConnectionData = flow_connections[_idx]

	if not flow_connection.to:
		return null

	return FlowConnectionReturn.new(flow_connection, _idx, flow_connection.to, flow_connection.to_idx, self, flow_connection.to_from_ref)


func remove_input_connection(_idx: int) -> void:
	for connection: InputConnectionData in input_connections:
		if connection.idx == _idx:
			connection.from.output_connections.erase(connection.from_ref)
			connection.line_ref.visible = false
			input_connections.erase(connection)
			break


func get_input_connection(_idx: int) -> ConnectionReturn:
	for connection: InputConnectionData in input_connections:
		if connection.idx == _idx:
			return ConnectionReturn.new(connection, connection.from_ref, connection.from, self)

	return null


func create_connection(_idx: int, _from_idx: int, _from: HenVirtualCNode, _line: HenConnectionLine = null) -> ConnectionReturn:
	# cleaning others connections
	# if _remove_old: remove_input_connection(_idx)
	var input_connection: InputConnectionData = InputConnectionData.new()
	var output_connection: OutputConnectionData = OutputConnectionData.new()

	var input: InOutData = inputs[_idx]
	var output: InOutData = _from.outputs[_from_idx]

	# output
	output_connection.idx = _from_idx
	output_connection.line_ref = _line
	output_connection.type = output.type
	
	output_connection.to_idx = _idx
	output_connection.to = self
	output_connection.to_ref = input_connection
	output_connection.to_type = input.type
	output_connection.output_ref = output

	# inputs
	input_connection.idx = _idx
	input_connection.line_ref = _line
	input_connection.type = input.type
	
	input_connection.from = _from
	input_connection.from_idx = _from_idx
	input_connection.from_ref = output_connection
	input_connection.from_type = output.type
	input_connection.input_ref = input

	return ConnectionReturn.new(input_connection, output_connection, _from, self)


func add_connection(_idx: int, _from_idx: int, _from: HenVirtualCNode, _line: HenConnectionLine = null) -> void:
	create_connection(_idx, _from_idx, _from, _line).add(false)


func get_flow_token_list(_input_idx: int, _token_list: Array = []) -> Array:
	var stack: Array = []
	var token_list: Array = _token_list

	stack.append({node = self, idx = _input_idx})

	while not stack.is_empty():
		var current: Dictionary = stack.pop_back()
		var vc: HenVirtualCNode = current.node
		var idx: int = current.idx

		if current.has('flow_id'):
			token_list = HenCodeGeneration.flows_refs[current.flow_id]


		match vc.sub_type:
			HenVirtualCNode.SubType.IF:
				token_list.append(vc.get_if_token(stack))
			HenVirtualCNode.SubType.FOR, HenVirtualCNode.SubType.FOR_ARR:
				token_list.append(vc.get_for_token(stack))
			HenVirtualCNode.SubType.MACRO:
				token_list.append(vc.get_macro_token(idx))
			HenVirtualCNode.SubType.MACRO_OUTPUT:
				if HenGlobal.USE_MACRO_REF:
					var flow: FlowConnectionData = HenGlobal.MACRO_REF.flow_connections[idx]

					if flow.to:
						stack.append({node = flow.to, idx = flow.to_idx})
					
					HenGlobal.USE_MACRO_REF = false
			_:
				token_list.append(vc.get_token())

	
				if vc.flow_connections[0].to:
					stack.append({node = vc.flow_connections[0].to, idx = vc.flow_connections[0].to_idx})

	return _token_list


func get_macro_token(_input_idx: int) -> Dictionary:
	var flow_tokens: Array
	var input_flow: FlowConnectionData = (ref as HenSideBar.MacroData).input_ref.flow_connections[_input_idx]

	if input_flow.to:
		HenGlobal.USE_MACRO_REF = true
		HenGlobal.MACRO_REF = self
		HenGlobal.MACRO_USE_SELF = route_ref.type != HenRouter.ROUTE_TYPE.STATE
		HenGlobal.USE_MACRO_USE_SELF = true
		flow_tokens = input_flow.to.get_flow_token_list(input_flow.to_idx)
		HenGlobal.USE_MACRO_USE_SELF = false

	return {
		type = HenVirtualCNode.SubType.MACRO,
		flow_tokens = flow_tokens,
		use_self = false
	}


func get_if_token(_stack: Array) -> Dictionary:
	var true_flow_id: int = HenCodeGeneration.get_flow_id()
	var false_flow_id: int = HenCodeGeneration.get_flow_id()

	HenCodeGeneration.flows_refs[true_flow_id] = []
	HenCodeGeneration.flows_refs[false_flow_id] = []

	# this causing stack overflow when using a lot of if cnodes
	if flow_connections[0].to:
		var flow: FlowConnectionData = flow_connections[0]
		_stack.append({node = flow.to, idx = flow.to_idx, flow_id = true_flow_id})
		
	if flow_connections[1].to:
		var flow: FlowConnectionData = flow_connections[1]
		_stack.append({node = flow.to, idx = flow.to_idx, flow_id = false_flow_id})

	return {
		type = HenVirtualCNode.SubType.IF,
		true_flow_id = true_flow_id,
		false_flow_id = false_flow_id,
		condition = get_input_token(0),
		use_self = false
	}


func get_for_token(_stack: Array) -> Dictionary:
	var body_flow_id: int = HenCodeGeneration.get_flow_id()
	var then_flow_id: int = HenCodeGeneration.get_flow_id()

	HenCodeGeneration.flows_refs[body_flow_id] = []
	HenCodeGeneration.flows_refs[then_flow_id] = []

	if flow_connections[0].to:
		var flow: FlowConnectionData = flow_connections[0]
		_stack.append({node = flow.to, idx = flow.to_idx, flow_id = body_flow_id})
		
	if flow_connections[1].to:
		var flow: FlowConnectionData = flow_connections[1]
		_stack.append({node = flow.to, idx = flow.to_idx, flow_id = then_flow_id})

	return {
		type = sub_type,
		id = id,
		body_flow_id = body_flow_id,
		then_flow_id = then_flow_id,
		params = get_input_token_list(),
		index_name = outputs[0].name.to_snake_case(),
		use_self = false
	}


func get_input_token(_idx: int) -> Dictionary:
	var connection: InputConnectionData
	for input_connection: InputConnectionData in input_connections:
		if input_connection.idx == _idx:
			connection = input_connection
			break

	var input: InOutData = inputs[_idx]

	if connection and connection.from:
		match connection.from.sub_type:
			SubType.MACRO_INPUT:
				if HenGlobal.USE_MACRO_REF:
					var data: Dictionary = HenGlobal.MACRO_REF.get_input_token(connection.from_idx)
					return data
			SubType.MACRO:
				HenGlobal.USE_MACRO_USE_SELF = true
				HenGlobal.MACRO_USE_SELF = route_ref.type != HenRouter.ROUTE_TYPE.STATE
				var data: Dictionary = (connection.from.ref as HenSideBar.MacroData).output_ref.get_input_token(connection.from_idx)
				HenGlobal.USE_MACRO_USE_SELF = false
				return data
			_:
				var data: Dictionary = connection.from.get_token(connection.from_idx)
				data.prop_name = input.name

				if HenGlobal.USE_MACRO_REF:
					data.value += '_' + str(HenGlobal.MACRO_REF.id)

				if input.is_ref:
					data.is_ref = input.is_ref
					
				return data
	elif input.code_value:
		var data: Dictionary = {
			type = HenVirtualCNode.SubType.IN_PROP,
			prop_name = input.name,
			value = input.code_value,
			use_self = (route_ref.type != HenRouter.ROUTE_TYPE.STATE) if not HenGlobal.USE_MACRO_USE_SELF else HenGlobal.MACRO_USE_SELF
		}

		if HenGlobal.USE_MACRO_REF:
			if input.category == 'class_props':
				data.value += '_' + str(HenGlobal.MACRO_REF.id)

		if input.is_ref:
			data.is_ref = input.is_ref

		if input.category:
			match input.category:
				'default_value':
					if not input.is_ref:
						data.use_self = true

					data.use_value = true
				'class_props':
					data.use_value = true
				'state_transition':
					print('t=>', data)
					data.value = '&"{0}"'.format([data.value.to_snake_case()])

		return data
	
	return {type = HenVirtualCNode.SubType.NOT_CONNECTED, input_type = inputs[_idx].type, use_self = true}


func get_input_token_list(_get_name: bool = false) -> Array:
	var input_tokens: Array = []
	var idx: int = 0

	for connection: InOutData in inputs:
		input_tokens.append(get_input_token(idx))
		idx += 1

	return input_tokens

# getting cnode outputs
func get_output_token_list() -> Array:
	return outputs.map(
		func(x: InOutData) -> Dictionary:
			return {name = x.name, type = x.type}
	)


func get_token(_id: int = 0) -> Dictionary:
	var token: Dictionary = {
		type = sub_type,
		use_self = (route_ref.type != HenRouter.ROUTE_TYPE.STATE) if not HenGlobal.USE_MACRO_USE_SELF else HenGlobal.MACRO_USE_SELF,
	}

	if category:
		token.category = category

	match sub_type:
		HenVirtualCNode.SubType.VOID, HenVirtualCNode.SubType.GO_TO_VOID, HenVirtualCNode.SubType.SELF_GO_TO_VOID:
			token.merge({
				name = name.to_snake_case() if not name_to_code else name_to_code,
				params = get_input_token_list()
			})
		HenVirtualCNode.SubType.FUNC, HenVirtualCNode.SubType.USER_FUNC:
			token.merge({
				name = name.to_snake_case(),
				params = get_input_token_list(),
				id = _id if outputs.size() > 1 else -1,
			})
		HenVirtualCNode.SubType.VAR, HenVirtualCNode.SubType.LOCAL_VAR:
			token.merge({
				name = outputs[0].name.to_snake_case(),
			})
		HenVirtualCNode.SubType.DEBUG_VALUE:
			token.merge({
				value = get_input_token_list()[0],
				# id = HenCodeGeneration.get_debug_counter(_node)
			})
		HenVirtualCNode.SubType.SET_VAR, HenVirtualCNode.SubType.SET_LOCAL_VAR:
			token.merge({
				name = inputs[0].name.to_snake_case(),
				value = get_input_token_list()[0],
			})
		HenVirtualCNode.SubType.VIRTUAL, HenVirtualCNode.SubType.FUNC_INPUT, HenVirtualCNode.SubType.OVERRIDE_VIRTUAL:
			token.merge({
				param = outputs[_id].name.to_snake_case(),
			})
		HenVirtualCNode.SubType.FOR, HenVirtualCNode.SubType.FOR_ARR:
			return {
				id = id,
				type = HenVirtualCNode.SubType.FOR_ITEM,
				name = outputs[0].name.to_snake_case(),
				use_self = true
			}
		HenVirtualCNode.SubType.IMG:
			token.merge({
				name = name.to_snake_case(),
				params = get_input_token_list()
			})
		HenVirtualCNode.SubType.RAW_CODE:
			token.merge({
				code = get_input_token_list()[0],
			})
		HenVirtualCNode.SubType.SINGLETON:
			token.merge({
				name = name,
				params = get_input_token_list(),
				id = _id if outputs.size() > 1 else -1,
			})
		HenVirtualCNode.SubType.GET_PROP:
			var dt: Dictionary = {
				value = outputs[0].code_value.to_snake_case()
			}

			if outputs[0].data:
				dt.data = get_input_token(0)

			token.merge(dt)
		HenVirtualCNode.SubType.SET_PROP:
			var dt: Dictionary = {}

			if inputs[0].is_ref:
				dt.data = get_input_token(0)
				dt.name = get_input_token(1).value
				dt.value = get_input_token(2)
			else:
				dt.name = inputs[0].code_value.to_snake_case()
				dt.value = get_input_token(1)

			token.merge(dt)
		HenVirtualCNode.SubType.EXPRESSION:
			token.merge({
				params = get_input_token_list(true),
				exp = inputs[0].value
			})
		HenVirtualCNode.SubType.SIGNAL_CONNECTION:
			token.merge({
				params = get_input_token_list(true),
				signal_name = (ref as HenSideBar.SignalData).signal_name_to_code,
				name = (ref as HenSideBar.SignalData).name
			})
		HenVirtualCNode.SubType.SIGNAL_DISCONNECTION:
			token.merge({
				params = get_input_token_list(true),
				signal_name = (ref as HenSideBar.SignalData).signal_name_to_code,
				name = (ref as HenSideBar.SignalData).name.to_snake_case()
			})

	return token


func get_history_obj() -> VCNodeReturn:
	return VCNodeReturn.new(self)


func create_flow_connection() -> void:
	flow_connections.append(FlowConnectionData.new({name = 'Flow ' + str(flow_connections.size())}))


func clear_in_out(_is_input: bool) -> void:
	#TODO clear connections
	if _is_input:
		inputs.clear()
	else:
		outputs.clear()


func _on_change_name(_name: String) -> void:
	# restrict name change by sub_type
	match sub_type:
		SubType.FUNC_INPUT, SubType.FUNC_OUTPUT:
			return

	name = _name
	update()


func _on_in_out_moved(_is_input: bool, _pos: int, _in_ou_ref: InOutData) -> void:
	var is_input: bool = _is_input
	var index_slice: int = 0

	match sub_type:
		SubType.FUNC_INPUT, SubType.SIGNAL_ENTER, SubType.MACRO_INPUT:
			if is_input: is_input = false
			else: return
		SubType.FUNC_OUTPUT, SubType.MACRO_OUTPUT:
			if not is_input: is_input = true
			else: return
		SubType.SIGNAL_CONNECTION:
			# they have reference input, so start from 1
			index_slice = 1

	if is_input:
		HenUtils.move_array_item_to_idx(inputs, _in_ou_ref, _pos + index_slice)
	else:
		HenUtils.move_array_item_to_idx(outputs, _in_ou_ref, _pos + index_slice)
	
	update()


func _on_in_out_deleted(_is_input: bool, _in_ou_ref: InOutData) -> void:
	var is_input: bool = _is_input

	match sub_type:
		SubType.FUNC_INPUT, SubType.SIGNAL_ENTER, SubType.MACRO_INPUT:
			if is_input: is_input = false
			else: return
		SubType.FUNC_OUTPUT, SubType.MACRO_OUTPUT:
			if not is_input: is_input = true
			else: return

	#TODO remove connections
	if is_input:
		inputs.erase(_in_ou_ref)
	else:
		outputs.erase(_in_ou_ref)
	
	update()


func _on_in_out_added(_is_input: bool, _data: Dictionary) -> InOutData:
	# restrict creation by sub_type
	match sub_type:
		SubType.FUNC_INPUT, SubType.SIGNAL_ENTER, SubType.MACRO_INPUT:
			if not _is_input: return
			_is_input = not _is_input
		SubType.FUNC_OUTPUT, SubType.MACRO_OUTPUT:
			if _is_input: return
			_is_input = not _is_input
		SubType.SIGNAL_DISCONNECTION:
			return

	if _data.has('ref_id'):
		_data.ref = HenGlobal.SIDE_BAR_LIST_CACHE[int(_data.ref_id)]
	
	var in_out: InOutData = InOutData.new(_data)

	in_out.moved.connect(_on_in_out_moved)
	in_out.deleted.connect(_on_in_out_deleted)
	in_out.update_changes.connect(_on_in_out_data_changed)

	if _is_input:
		inputs.append(in_out)
	else:
		outputs.append(in_out)
	
	update()

	return in_out


func _on_in_out_data_changed() -> void:
	update()


func _on_in_out_reset(_is_input: bool, _new_inputs: Array, _subtype_filter: Array = []) -> void:
	var is_input: bool = _is_input

	match sub_type:
		SubType.SIGNAL_ENTER:
			if is_input: is_input = false
			else: return
	
	# filtering sub_types
	if not _subtype_filter.is_empty():
		if not _subtype_filter.has(sub_type):
			return
	
	clear_in_out(is_input)

	for input_data: Dictionary in _new_inputs:
		var in_out: InOutData = _on_in_out_added(is_input, input_data)

		match sub_type:
			SubType.SIGNAL_CONNECTION:
				in_out.reset_input_value()

	update()


func _on_flow_added(_is_input: bool, _data: Dictionary) -> void:
	# restrict creation by sub_type
	match sub_type:
		SubType.MACRO_INPUT:
			if not _is_input: return
			_is_input = not _is_input
		SubType.MACRO_OUTPUT:
			if _is_input: return
			_is_input = not _is_input

	var flow: FlowConnection

	if _is_input:
		flow = FromFlowConnection.new(_data)
		from_flow_connections.append(flow)
	else:
		flow = FlowConnectionData.new(_data)
		flow_connections.append(flow)
	
	
	if _data.has('id'):
		HenGlobal.SIDE_BAR_LIST_CACHE[_data.id] = flow

	flow.moved.connect(_on_flow_moved)
	flow.deleted.connect(_on_flow_deleted)
	flow.update_changes.connect(_on_in_out_data_changed)

	update()

func _on_flow_moved(_is_input: bool, _pos: int, _flow_ref: FlowConnection) -> void:
	var index_slice: int = 0

	if _is_input:
		HenUtils.move_array_item_to_idx(from_flow_connections, _flow_ref, _pos + index_slice)
	else:
		HenUtils.move_array_item_to_idx(flow_connections, _flow_ref, _pos + index_slice)
	
	update()


func _on_flow_deleted(_is_input: bool, _flow_ref: FlowConnection) -> void:
	if _is_input:
		from_flow_connections.erase(_flow_ref)
	else:
		flow_connections.erase(_flow_ref)
	
	update()


static func instantiate_virtual_cnode(_config: Dictionary) -> HenVirtualCNode:
	# adding virtual cnode to list
	var v_cnode: HenVirtualCNode = HenVirtualCNode.new()

	v_cnode.name = _config.name
	v_cnode.type = _config.type as Type if _config.has('type') else Type.DEFAULT
	v_cnode.sub_type = _config.sub_type
	v_cnode.id = HenGlobal.get_new_node_counter() if not _config.has('id') else _config.id
	v_cnode.route_ref = _config.route
	
	if _config.has('name_to_code'): v_cnode.name_to_code = _config.name_to_code


	match _config.route.type:
		HenRouter.ROUTE_TYPE.BASE:
			(_config.route.ref as HenLoader.BaseRouteRef).virtual_cnode_list.append(v_cnode)
		HenRouter.ROUTE_TYPE.STATE:
			(_config.route.ref as HenVirtualCNode).virtual_cnode_list.append(v_cnode)
		HenRouter.ROUTE_TYPE.FUNC:
			var ref: HenSideBar.FuncData = _config.route.ref
			
			ref.virtual_cnode_list.append(v_cnode)

			match v_cnode.sub_type:
				SubType.FUNC_INPUT:
					ref.input_ref = v_cnode
				SubType.FUNC_OUTPUT:
					ref.output_ref = v_cnode
		HenRouter.ROUTE_TYPE.SIGNAL:
			var ref: HenSideBar.SignalData = _config.route.ref
			
			ref.virtual_cnode_list.append(v_cnode)

			match v_cnode.sub_type:
				SubType.SIGNAL_ENTER:
					ref.signal_enter = v_cnode
		HenRouter.ROUTE_TYPE.MACRO:
			var ref: HenSideBar.MacroData = _config.route.ref
			
			ref.virtual_cnode_list.append(v_cnode)

			match v_cnode.sub_type:
				SubType.MACRO_INPUT:
					ref.input_ref = v_cnode
				SubType.MACRO_OUTPUT:
					ref.output_ref = v_cnode

	
	if _config.has('ref_id'):
		_config.ref = HenGlobal.SIDE_BAR_LIST_CACHE[int(_config.ref_id)]

	if _config.has('ref'):
		# ref is required to have id to save and load work
		v_cnode.ref = _config.ref
		v_cnode.ref_id = _config.ref.id

		if _config.ref.has_signal('name_changed'):
			_config.ref.name_changed.connect(v_cnode._on_change_name)

		if _config.ref.has_signal('in_out_added'):
			_config.ref.in_out_added.connect(v_cnode._on_in_out_added)

		if _config.ref.has_signal('in_out_reseted'):
			_config.ref.in_out_reseted.connect(v_cnode._on_in_out_reset)

		if _config.ref.has_signal('flow_added'):
			_config.ref.flow_added.connect(v_cnode._on_flow_added)


	if _config.has('category'):
		v_cnode.category = _config.category

	if _config.has('position'):
		v_cnode.position = _config.position if _config.position is Vector2 else str_to_var(_config.position)

	match v_cnode.sub_type:
		SubType.VIRTUAL:
			_config.route.ref.virtual_sub_type_vc_list.append(v_cnode)
		SubType.MACRO, SubType.MACRO_INPUT, SubType.MACRO_OUTPUT:
			var _ref: HenSideBar.MacroData = _config.ref

			_config.from_flow = _ref.inputs.map(func(x: HenSideBar.MacroData.MacroInOut) -> Dictionary: return x.get_data())
			_config.to_flow = _ref.outputs.map(func(x: HenSideBar.MacroData.MacroInOut) -> Dictionary: return x.get_data())

			if v_cnode.sub_type == SubType.MACRO:
				(v_cnode.ref as HenSideBar.MacroData).macro_ref_list.append(v_cnode)


	match v_cnode.type:
		Type.DEFAULT:
			if not _config.has('to_flow'): v_cnode.flow_connections.append(FlowConnectionData.new())
			v_cnode.from_flow_connections.append(FromFlowConnection.new())
		Type.IF:
			v_cnode.flow_connections.append(FlowConnectionData.new({name = 'True'}))
			v_cnode.flow_connections.append(FlowConnectionData.new({name = 'False'}))
			v_cnode.from_flow_connections.append(FromFlowConnection.new())
		Type.FOR:
			v_cnode.flow_connections.append(FlowConnectionData.new({name = 'Body'}))
			v_cnode.flow_connections.append(FlowConnectionData.new({name = 'Then'}))
			v_cnode.from_flow_connections.append(FromFlowConnection.new())
		Type.STATE:
			v_cnode.route = {
				name = v_cnode.name,
				type = HenRouter.ROUTE_TYPE.STATE,
				id = HenUtilsName.get_unique_name(),
				ref = v_cnode
			}

			HenRouter.line_route_reference[v_cnode.route.id] = []
			
			if not _config.has('virtual_cnode_list'):
				HenVirtualCNode.instantiate_virtual_cnode({
					name = 'enter',
					sub_type = HenVirtualCNode.SubType.VIRTUAL,
					route = v_cnode.route,
					position = Vector2.ZERO
				})

				HenVirtualCNode.instantiate_virtual_cnode({
					name = 'update',
					sub_type = HenVirtualCNode.SubType.VIRTUAL,
					outputs = [ {
						name = 'delta',
						type = 'float'
					}],
					route = v_cnode.route,
					position = Vector2(400, 0)
				})

			v_cnode.from_flow_connections.append(FromFlowConnection.new())

			if _config.has('to_flow'):
				for flow: Dictionary in _config.to_flow:
					v_cnode._on_flow_added(false, flow)
		Type.STATE_START:
			v_cnode.flow_connections.append(FlowConnectionData.new({name = 'On Start'}))
			v_cnode.from_flow_connections.append(FromFlowConnection.new())
		Type.STATE_EVENT:
			v_cnode.flow_connections.append(FlowConnectionData.new())
		_:
			if _config.has('to_flow'):
				for flow: Dictionary in _config.to_flow:
					v_cnode._on_flow_added(false, flow)

			if _config.has('from_flow'):
				for flow: Dictionary in _config.from_flow:
					v_cnode._on_flow_added(true, flow)
			

	if _config.has('inputs'):
		for input_data: Dictionary in _config.inputs:
			var input: InOutData = v_cnode._on_in_out_added(v_cnode.sub_type != SubType.MACRO_OUTPUT, input_data)

			if not input_data.has('code_value'):
				input.reset_input_value()

	if _config.has('outputs'):
		for output_data: Dictionary in _config.outputs:
			v_cnode._on_in_out_added(v_cnode.sub_type == SubType.MACRO_INPUT, output_data)

	return v_cnode


static func instantiate_virtual_cnode_and_add(_config: Dictionary) -> HenVirtualCNode:
	var v_cnode: HenVirtualCNode = instantiate_virtual_cnode(_config)
	v_cnode.update()
	return v_cnode


static func instantiate(_config: Dictionary) -> VCNodeReturn:
	var v_cnode: HenVirtualCNode = instantiate_virtual_cnode(_config)
	return VCNodeReturn.new(v_cnode)
