@tool
class_name HenVirtualCNode extends Object

enum Type {
	DEFAULT = 0,
	IF = 1,
	FOR = 2,
	IMG = 3,
	EXPRESSION = 4,
	STATE = 5,
	STATE_START = 6,
	STATE_EVENT = 7,
	MACRO = 8,
	MACRO_INPUT = 9,
	MACRO_OUTPUT = 10
}

enum SubType {
	FUNC = 0,
	VOID = 1,
	VAR = 2,
	LOCAL_VAR = 3,
	DEBUG_VALUE = 4,
	USER_FUNC = 5,
	SET_VAR = 6,
	GET_FROM_PROP = 9,
	VIRTUAL = 10,
	FUNC_INPUT = 11,
	CAST = 12,
	IF = 13,
	RAW_CODE = 14,
	SELF_GO_TO_VOID = 15,
	FOR = 16,
	FOR_ARR = 17,
	FOR_ITEM = 18,
	FUNC_OUTPUT = 19,
	CONST = 20,
	GO_TO_VOID = 22,
	IMG = 23,
	EXPRESSION = 24,
	SET_LOCAL_VAR = 25,
	IN_PROP = 26,
	NOT_CONNECTED = 27,
	DEBUG = 28,
	DEBUG_PUSH = 29,
	DEBUG_FLOW_START = 30,
	START_DEBUG_STATE = 31,
	DEBUG_STATE = 32,
	BREAK = 33,
	CONTINUE = 34,
	PASS = 35,
	STATE = 36,
	STATE_START = 37,
	STATE_EVENT = 38,
	SIGNAL_ENTER = 39,
	SIGNAL_CONNECTION = 40,
	SIGNAL_DISCONNECTION = 41,
	MACRO = 42,
	MACRO_INPUT = 43,
	MACRO_OUTPUT = 44,
	OVERRIDE_VIRTUAL = 45,
	FUNC_FROM = 46,
	INVALID = 47,
	DEEP_PROP = 48,
	SET_DEEP_PROP = 49
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
var ref: Object
var can_delete: bool = true
var is_deleted: bool = false
var from_side_bar_id: int = -1
var from_id: int = -1
var invalid: bool = false
var singleton_class: String

var input_connections: Array = []
var output_connections: Array = []
var flow_connections: Array = []
var from_flow_connections: Array = []


class InOutData extends Object:
	var id: int = HenGlobal.get_new_node_counter()
	var name: String
	var type: StringName: set = _on_change_type
	var sub_type: StringName
	var category: StringName
	var is_ref: bool
	var code_value: String
	var value: Variant
	var data: Variant
	var is_prop: bool
	var is_static: bool
	var ref: Object
	var ref_change_rule: RefChangeRule
	var from_id: int = -1

	signal update_changes
	signal moved
	signal deleted
	signal type_changed

	enum RefChangeRule {
		NONE = 0,
		TYPE_CHANGE = 1,
		VALUE_CODE_VALUE_CHANGE = 2,
		IS_PROP = 3
	}

	func _init(_data: Dictionary) -> void:
		name = _data.name
		type = _data.type

		if _data.has('from_id'): from_id = _data.from_id
		if _data.has('id'): id = _data.id
		if _data.has('sub_type'): sub_type = _data.sub_type
		if _data.has('category'): category = _data.category
		if _data.has('is_ref'): is_ref = _data.is_ref
		if _data.has('code_value'): code_value = _data.code_value
		if _data.has('value'): value = _data.value
		if _data.has('data'): data = _data.data
		if _data.has('is_prop'): is_prop = _data.is_prop
		if _data.has('is_static'): is_static = _data.is_static
		if _data.has('ref'): set_ref(_data.ref, _data.ref_change_rule if _data.has('ref_change_rule') else RefChangeRule.NONE)

	
	func _on_change_type(_type: StringName) -> void:
		type_changed.emit(type, _type, self)
		type = _type


	func set_ref(_ref, _ref_change_rule: RefChangeRule = RefChangeRule.NONE) -> void:
		ref = _ref
		ref_change_rule = _ref_change_rule

		# when param is moved
		if ref.has_signal('moved') and not ref.is_connected('moved', _on_move):
			ref.moved.connect(_on_move)

		if ref.has_signal('deleted') and not ref.is_connected('deleted', _on_delete):
			if not ref is HenSideBar.VarData:
				ref.deleted.connect(_on_delete)

		if _ref.has_signal('data_changed') and not ref.is_connected('data_changed', on_data_changed):
			_ref.data_changed.connect(on_data_changed)
		
		update_changes.emit()
	
	func _on_move(_is_input: bool, _pos: int) -> void:
		moved.emit(_is_input, _pos, self)

	func _on_delete(_is_input: bool) -> void:
		deleted.emit(_is_input, self)

	func remove_ref() -> void:
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
			id = id,
			name = name,
			type = type
		}

		if from_id > -1: dt.from_id = from_id
		if sub_type: dt.sub_type = sub_type
		if category: dt.category = category
		if is_ref: dt.is_ref = is_ref
		if code_value: dt.code_value = code_value
		if value: dt.value = value
		if data: dt.data = data
		if is_prop: dt.is_prop = is_prop
		if is_static: dt.is_static = is_static
		if ref: dt.ref_id = ref.id
		if ref_change_rule != RefChangeRule.NONE: dt.ref_change_rule = int(ref_change_rule)

		return dt
	

	func reset_input_value() -> void:
		category = &'default_value'
		is_prop = false

		if HenGlobal.script_config and HenGlobal.script_config.type == type:
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
	var id: int = -1
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
		deleted.emit(self is FlowConnectionData, self)
	
	func on_data_changed(_name: String, _value) -> void:
		set(_name, _value)
		update_changes.emit()


class FlowConnectionData extends FlowConnection:
	var line_ref: HenFlowConnectionLine
	var from_id: int
	var to_id: int
	var from_pos: Vector2
	var to_pos: Vector2
	var from: HenVirtualCNode
	var to: HenVirtualCNode
	var to_from_ref: FromFlowConnection

	func get_save() -> Dictionary:
		return {
			id = id,
			from_id = from_id,
			to_id = to_id,
			to_vc_id = to.id
		}
		

class FromFlowConnection extends FlowConnection:
	var from_connections: Array[FlowConnectionData]


class ConnectionData extends Object:
	# var idx: int
	var from_id: int
	var to_id: int
	var line_ref: HenConnectionLine
	var type: StringName


class InputConnectionData extends ConnectionData:
	var from: HenVirtualCNode
	# var from_idx: int
	var from_ref: OutputConnectionData
	var from_old_pos: Vector2
	var from_type: StringName
	var input_ref: InOutData


	func get_save() -> Dictionary:
		return {
			from_id = from_id,
			to_id = to_id,
			from_vc_id = from.id,
		}


class OutputConnectionData extends ConnectionData:
	var to: HenVirtualCNode
	# var to_idx: int
	var to_ref: InputConnectionData
	var to_old_pos: Vector2
	var to_type: StringName
	var output_ref: InOutData


class FlowConnectionReturn:
	var flow_connection: FlowConnectionData
	
	var to: HenVirtualCNode
	var to_id: int
	var from_id: int
	var from: HenVirtualCNode
	var to_from_ref: FromFlowConnection

	# old
	var old_to: HenVirtualCNode
	var old_to_id: int
	var old_from_id: int
	var old_from: HenVirtualCNode
	var old_to_from_ref: FromFlowConnection

	func _init(_flow: FlowConnectionData, _from_id: int, _to: HenVirtualCNode, _to_id: int, _from: HenVirtualCNode, _to_from_ref: FromFlowConnection) -> void:
		from_id = _from_id
		flow_connection = _flow
		to = _to
		to_id = _to_id
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
			old_from_id = flow_connection.from_id
			old_to_id = flow_connection.to_id
			old_from = flow_connection.from
			old_to_from_ref = flow_connection.to_from_ref

		flow_connection.from_id = from_id
		flow_connection.to = to
		flow_connection.to_id = to_id
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
			flow_connection.from_id = old_from_id
			flow_connection.to = old_to
			flow_connection.to_id = old_to_id
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
	var to_id: int

	var old_inputs_connections: Array

	func _init(_in: InputConnectionData, _out: OutputConnectionData, _from: HenVirtualCNode, _to: HenVirtualCNode, _to_id = -1) -> void:
		input_connection = _in
		output_connection = _out
		from = _from
		to = _to
		to_id = _to_id
	

	func add(_update: bool = true) -> void:
		# removing old inputs
		var remove_connection: Array = []
		
		for connection: InputConnectionData in to.input_connections:
			if connection.to_id != to_id:
				continue

			if connection.line_ref:
				connection.line_ref.visible = false
				connection.line_ref = null
			
			if connection.from_ref.line_ref:
				connection.from_ref.line_ref.visible = false
				connection.from_ref.line_ref = null
			
			remove_connection.append(connection)

		for connection in remove_connection:
			to.input_connections.erase(connection)
			connection.from.output_connections.erase(connection.from_ref)
			old_inputs_connections.append(connection)

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
		
		if output_connection.line_ref:
			output_connection.line_ref.visible = false
			output_connection.line_ref = null

		for connection: InputConnectionData in old_inputs_connections:
			to.input_connections.append(connection)
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
		if v_cnode.is_deleted and not v_cnode.can_delete:
			return
		
		if not v_cnode.route_ref.ref.virtual_cnode_list.has(v_cnode):
			v_cnode.route_ref.ref.virtual_cnode_list.append(v_cnode)

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
		if not v_cnode.can_delete:
			return
		
		v_cnode.route_ref.ref.virtual_cnode_list.erase(v_cnode)

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


func get_input(_id: int) -> InOutData:
	for input: InOutData in inputs:
		if input.id == _id:
			return input
	return null


func get_output(_id: int) -> InOutData:
	for output: InOutData in outputs:
		if output.id == _id:
			return output
	return null


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
					input.visible = true
					
					var input_data: InOutData = inputs[idx]

					input.change_name(input_data.name)
					input.input_ref = input_data
					
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

					output.change_name(output_data.name)
					output.change_type(
						output_data.type,
						output_data.value if output_data.value else null,
						output_data.sub_type if output_data.sub_type else &''
					)

				idx += 1
			
			cnode_ref = cnode


			for connection: InputConnectionData in input_connections:
				if connection.from_ref.line_ref is HenConnectionLine:
					connection.line_ref = connection.from_ref.line_ref
				elif connection.line_ref is HenConnectionLine:
					connection.from_ref.line_ref = connection.line_ref
				else:
					connection.line_ref = HenPool.get_line_from_pool(
						connection.from.cnode_ref if connection.from.cnode_ref else null,
						null,
						connection.from.cnode_ref.get_node('%OutputContainer').get_child(outputs.find(get_output(connection.from_id))).get_node('%Connector') if connection.from.cnode_ref else null,
						null
					)

					if not connection.line_ref:
						continue
				
				connection.line_ref.from_virtual_pos = connection.from_old_pos

				
				var input: HenCnodeInOut = cnode_ref.get_node('%InputContainer').get_child(inputs.find(get_input(connection.to_id)))
				connection.line_ref.to_cnode = cnode_ref
				connection.line_ref.output = input.get_node('%Connector')
				connection.line_ref.to_pool_visible = true

				input.remove_in_prop()

				connection.line_ref.conn_size = (input.get_node('%Connector') as TextureRect).size / 2
				connection.line_ref.update_colors(connection.from_type, connection.type)

				if not cnode_ref.is_connected('on_move', connection.line_ref.update_line):
					cnode_ref.connect('on_move', connection.line_ref.update_line)


			for connection: OutputConnectionData in output_connections:
				if connection.to_ref.line_ref is HenConnectionLine:
					connection.line_ref = connection.to_ref.line_ref
				elif connection.line_ref is HenConnectionLine:
					connection.to_ref.line_ref = connection.line_ref
				else:
					connection.line_ref = HenPool.get_line_from_pool(
						null,
						connection.to.cnode_ref if connection.to and connection.to.cnode_ref else null,
						null,
						connection.to.cnode_ref.get_node('%InputContainer').get_child(inputs.find(get_input(connection.to_id))).get_node('%Connector') if connection.to and connection.to.cnode_ref else null
					)

					if not connection.line_ref:
						continue
				
				connection.line_ref.to_virtual_pos = connection.to_old_pos


				var output: HenCnodeInOut = cnode_ref.get_node('%OutputContainer').get_child(outputs.find(get_output(connection.from_id)))
				connection.line_ref.from_cnode = cnode_ref
				connection.line_ref.input = output.get_node('%Connector')
				connection.line_ref.from_pool_visible = true

				connection.line_ref.conn_size = (output.get_node('%Connector') as TextureRect).size / 2
				connection.line_ref.update_colors(connection.type, connection.to_type)

				if not cnode_ref.is_connected('on_move', connection.line_ref.update_line):
					cnode_ref.connect('on_move', connection.line_ref.update_line)

			
			# cleaning from flows
			var from_flow_container: HBoxContainer = cnode_ref.get_node('%FromFlowContainer')

			for from_flow: HenFromFlow in from_flow_container.get_children():
				(from_flow.get_node('%Arrow') as TextureRect).visible = false
				from_flow.visible = false

			# cleaning flows
			var flow_container: HBoxContainer = cnode_ref.get_node('%FlowContainer')

			for flow_c: PanelContainer in flow_container.get_children():
				var connector: HenFlowConnector = flow_c.get_node('FlowSlot/Control/Connector')

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

				my_from_flow_container.id = from_flow_connection.id
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
				var connector: HenFlowConnector = my_flow_container.get_node('FlowSlot/Control/Connector')

				connector.id = flow_connection.id

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

			if invalid:
				cnode.modulate = Color(1, 1, 1, .3)
			else:
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

	if not can_delete:
		data.can_delete = false

	if name_to_code:
		data.name_to_code = name_to_code

	if singleton_class:
		data.singleton_class = singleton_class

	if invalid:
		data.invalid = invalid

	if ref:
		data.ref_id = ref.id

	if from_side_bar_id > -1:
		data.from_side_bar_id = from_side_bar_id

	if from_id > -1:
		data.from_id = from_id

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
		Type.DEFAULT:
			var flows: Array = []

			for flow_connection: FlowConnectionData in flow_connections:
				if flow_connection.name:
					flows.append({id = flow_connection.id, name = flow_connection.name})
			
			if not flows.is_empty(): data.to_flow = flows
		Type.STATE:
			data.to_flow = []
			for flow_connection: FlowConnectionData in flow_connections:
					if flow_connection.name:
						data.to_flow.append({name = flow_connection.name, id = flow_connection.id})


	if from_id > -1:
		if not HenGlobal.FROM_REFERENCES.references.has(from_id):
			HenGlobal.FROM_REFERENCES.references[from_id] = []

		var arr: Array = HenGlobal.FROM_REFERENCES.references[from_id]
		
		if not arr.has(HenGlobal.script_config.id):
			arr.append(HenGlobal.script_config.id)


	return data


func add_flow_connection(_id: int, _to_id: int, _to: HenVirtualCNode) -> FlowConnectionReturn:
	var flow_connection: FlowConnectionData = get_flow(_id)
	var flow_from_connection: FromFlowConnection = _to.get_from_flow(_to_id)

	if not flow_connection or not flow_from_connection:
		push_warning(flow_connections.map(func(x): return x.id))
		push_warning('Not Found Flow Connections: Id -> ', _id, ' or To Id -> ', _to_id)
		return null

	return FlowConnectionReturn.new(flow_connection, _id, _to, _to_id, self, flow_from_connection)


func get_flow(_id: int) -> FlowConnection:
	for flow: FlowConnection in flow_connections:
		if flow.id == _id:
			return flow
	
	return null


func get_from_flow(_id: int) -> FlowConnection:
	for flow: FlowConnection in from_flow_connections:
		if flow.id == _id:
			return flow
	
	return null


func get_flow_connection(_id: int) -> FlowConnectionReturn:
	var flow_connection: FlowConnectionData = get_flow(_id)

	if not flow_connection or not flow_connection.to:
		return null

	return FlowConnectionReturn.new(flow_connection, _id, flow_connection.to, flow_connection.to_id, self, flow_connection.to_from_ref)


func get_input_connection(_id: int) -> ConnectionReturn:
	for connection: InputConnectionData in input_connections:
		if connection.to_id == _id:
			return ConnectionReturn.new(connection, connection.from_ref, connection.from, self)

	return null


func create_connection(_id: int, _from_id: int, _from: HenVirtualCNode) -> ConnectionReturn:
	var input_connection: InputConnectionData = InputConnectionData.new()
	var output_connection: OutputConnectionData = OutputConnectionData.new()

	var input: InOutData = get_input(_id)
	var output: InOutData = _from.get_output(_from_id)

	if not input or not output:
		return
	
	if not HenUtils.is_type_relation_valid(output.type, input.type):
		return

	# output
	output_connection.type = output.type
	output_connection.from_id = output.id
	output_connection.to_id = input.id

	output_connection.to = self
	output_connection.to_ref = input_connection
	output_connection.to_type = input.type
	output_connection.output_ref = output

	# inputs
	input_connection.from_id = output.id
	input_connection.to_id = input.id
	input_connection.type = input.type
	
	input_connection.from = _from
	input_connection.from_ref = output_connection
	input_connection.from_type = output.type
	input_connection.input_ref = input

	return ConnectionReturn.new(input_connection, output_connection, _from, self, _id)


func add_connection(_idx: int, _from_id: int, _from: HenVirtualCNode) -> void:
	create_connection(_idx, _from_id, _from).add(false)


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

	var new_idx: int = _pos + index_slice

	if is_input:
		HenUtils.move_array_item_to_idx(inputs, _in_ou_ref, new_idx)
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

	remove_inout_connection(_in_ou_ref)
	update()


func _on_in_out_added(_is_input: bool, _data: Dictionary, _check_types: bool = true) -> InOutData:
	# restrict creation by sub_type
	if _check_types:
		match sub_type:
			SubType.FUNC_INPUT, SubType.MACRO_INPUT:
				if not _is_input: return
				_is_input = false
			SubType.FUNC_OUTPUT, SubType.MACRO_OUTPUT:
				if _is_input: return
				_is_input = true
			SubType.SIGNAL_ENTER:
				_is_input = false

	if _data.has('ref_id'):
		if not invalid:
			_data.ref = HenGlobal.SIDE_BAR_LIST_CACHE[int(_data.ref_id)]

	var in_out: InOutData = InOutData.new(_data)

	if _data.has('ref'):
		in_out.set_ref(_data.ref, )

	in_out.moved.connect(_on_in_out_moved)
	in_out.deleted.connect(_on_in_out_deleted)
	in_out.update_changes.connect(_on_in_out_data_changed)
	in_out.type_changed.connect(_on_in_out_type_changed)

	if _is_input:
		inputs.append(in_out)
	else:
		outputs.append(in_out)
	
	update()

	return in_out


func _on_in_out_type_changed(_old_type: StringName, _type: StringName, _ref: InOutData) -> void:
	if HenUtils.is_type_relation_valid(_old_type, _type):
		remove_inout_connection(_ref)


func input_has_connection(_id: int) -> bool:
	for input_connection: InputConnectionData in input_connections:
		if input_connection.to_id == _id:
			return true

	return false


func remove_inout_connection(_ref: InOutData) -> void:
	var input_remove: Array = []
	var output_remove: Array = []

	for connection: InputConnectionData in input_connections:
		if _ref.id == connection.to_id:
			input_remove.append(connection)
		
	for connection: OutputConnectionData in output_connections:
		if _ref.id == connection.from_id:
			output_remove.append(connection)

	for connection: InputConnectionData in input_remove:
		connection.from.output_connections.erase(connection.from_ref)
		input_connections.erase(connection)

		if connection.line_ref:
			connection.line_ref.visible = false

		connection.from.update()
	
	for connection: OutputConnectionData in output_remove:
		connection.to.input_connections.erase(connection.to_ref)
		output_connections.erase(connection)

		if connection.line_ref:
			connection.line_ref.visible = false

		connection.to.update()
	
	update()


func _on_side_bar_deleted(_deleted: bool) -> void:
	invalid = _deleted
	update()


func _on_in_out_data_changed() -> void:
	update()


func _on_in_out_reset(_is_input: bool, _new_inputs: Array, _subtype_filter: Array = []) -> void:
	var is_input: bool = _is_input

	match sub_type:
		SubType.SIGNAL_ENTER:
			if _is_input: is_input = false
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
		var flow: FlowConnectionData = _flow_ref as FlowConnectionData
		flow_connections.erase(flow)

		if flow.line_ref:
			flow.line_ref.visible = false

		flow.line_ref = null
		if flow.to_from_ref: flow.to_from_ref.from_connections.erase(flow)
	else:
		var flow: FromFlowConnection = _flow_ref as FromFlowConnection
		
		for connection: FlowConnectionData in flow.from_connections:
			if connection.line_ref:
				connection.line_ref.visible = false
			
			connection.line_ref = null
			connection.from.flow_connections.erase(connection)
		
		from_flow_connections.erase(flow)

	update()


func _on_delete_flow_state(_ref: FlowConnectionData) -> void:
	_on_flow_deleted(true, _ref)


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
			var _ref: HenSideBar.FuncData = _config.route.ref
			
			_ref.virtual_cnode_list.append(v_cnode)

			match v_cnode.sub_type:
				SubType.FUNC_INPUT:
					_ref.input_ref = v_cnode
				SubType.FUNC_OUTPUT:
					_ref.output_ref = v_cnode
		HenRouter.ROUTE_TYPE.SIGNAL:
			var _ref: HenSideBar.SignalData = _config.route.ref
			
			_ref.virtual_cnode_list.append(v_cnode)

			match v_cnode.sub_type:
				SubType.SIGNAL_ENTER:
					_ref.signal_enter = v_cnode
		HenRouter.ROUTE_TYPE.MACRO:
			var _ref: HenSideBar.MacroData = _config.route.ref
			
			_ref.virtual_cnode_list.append(v_cnode)

			match v_cnode.sub_type:
				SubType.MACRO_INPUT:
					_ref.input_ref = v_cnode
				SubType.MACRO_OUTPUT:
					_ref.output_ref = v_cnode

	if _config.has('singleton_class'):
		v_cnode.singleton_class = _config.singleton_class
		print(v_cnode.singleton_class)

	if _config.has('can_delete'):
		v_cnode.can_delete = _config.can_delete

	if _config.has('from_side_bar_id'):
		v_cnode.from_side_bar_id = _config.from_side_bar_id

	if _config.has('from_id'):
		v_cnode.from_id = _config.from_id

	if _config.has('invalid'):
		v_cnode.invalid = _config.invalid

	if _config.has('ref_id'):
		if not v_cnode.invalid:
			_config.ref = HenGlobal.SIDE_BAR_LIST_CACHE[int(_config.ref_id)]

	if _config.has('ref'):
		# ref is required to have id to save and load work
		v_cnode.ref = _config.ref

		if _config.ref.has_signal('name_changed'):
			_config.ref.name_changed.connect(v_cnode._on_change_name)

		if _config.ref.has_signal('in_out_added'):
			_config.ref.in_out_added.connect(v_cnode._on_in_out_added)
	

		if _config.ref.has_signal('deleted'):
			_config.ref.deleted.connect(v_cnode._on_side_bar_deleted)


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


	match v_cnode.type:
		Type.DEFAULT:
			if not _config.has('to_flow'): v_cnode.flow_connections.append(FlowConnectionData.new({id = 0}))
			v_cnode.from_flow_connections.append(FromFlowConnection.new({id = 0}))
		Type.IF:
			v_cnode.flow_connections.append(FlowConnectionData.new({name = 'True', id = 0}))
			v_cnode.flow_connections.append(FlowConnectionData.new({name = 'False', id = 1}))
			v_cnode.flow_connections.append(FlowConnectionData.new({name = 'Then', id = 2}))
			v_cnode.from_flow_connections.append(FromFlowConnection.new({id = 0}))
		Type.FOR:
			v_cnode.flow_connections.append(FlowConnectionData.new({name = 'Body', id = 0}))
			v_cnode.flow_connections.append(FlowConnectionData.new({name = 'Then', id = 1}))
			v_cnode.from_flow_connections.append(FromFlowConnection.new({id = 0}))
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
					position = Vector2.ZERO,
					can_delete = false
				})

				HenVirtualCNode.instantiate_virtual_cnode({
					name = 'update',
					sub_type = HenVirtualCNode.SubType.VIRTUAL,
					outputs = [ {
						name = 'delta',
						type = 'float'
					}],
					route = v_cnode.route,
					position = Vector2(400, 0),
					can_delete = false
				})

			v_cnode.from_flow_connections.append(FromFlowConnection.new({id = 0}))

			if _config.has('to_flow'):
				for flow: Dictionary in _config.to_flow:
					v_cnode._on_flow_added(false, flow)
		Type.STATE_START:
			v_cnode.flow_connections.append(FlowConnectionData.new({name = 'On Start', id = 0}))
			v_cnode.from_flow_connections.append(FromFlowConnection.new({id = 0}))
		Type.STATE_EVENT:
			v_cnode.flow_connections.append(FlowConnectionData.new({id = 0}))
		_:
			if _config.has('to_flow'):
				for flow: Dictionary in _config.to_flow:
					v_cnode._on_flow_added(false, flow)

			if _config.has('from_flow'):
				for flow: Dictionary in _config.from_flow:
					v_cnode._on_flow_added(true, flow)
			

	if _config.has('inputs'):
		for input_data: Dictionary in _config.inputs:
			var input: InOutData = v_cnode._on_in_out_added(true, input_data, false)

			if not input_data.has('code_value'):
				input.reset_input_value()


	if _config.has('outputs'):
		for output_data: Dictionary in _config.outputs:
			v_cnode._on_in_out_added(false, output_data, false)

	return v_cnode


static func instantiate_virtual_cnode_and_add(_config: Dictionary) -> HenVirtualCNode:
	var v_cnode: HenVirtualCNode = instantiate_virtual_cnode(_config)
	v_cnode.update()
	return v_cnode


static func instantiate(_config: Dictionary) -> VCNodeReturn:
	var v_cnode: HenVirtualCNode = instantiate_virtual_cnode(_config)
	return VCNodeReturn.new(v_cnode)
