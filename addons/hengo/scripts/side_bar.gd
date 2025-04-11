@tool
class_name HenSideBar extends PanelContainer

var list_data: SideBarList

@onready var name_label: Label = %Name
@onready var list: ItemList = %List

enum AddType {VAR, FUNC, SIGNAL}

const NAME = {
	AddType.VAR: 'Variables',
	AddType.FUNC: 'Functions',
	AddType.SIGNAL: 'Signals',
}

class SideBarList:
	var type: AddType

	var var_list: Array
	var func_list: Array
	var signal_list: Array

	signal list_changed

	func clear() -> void:
		var_list.clear()
		func_list.clear()
		signal_list.clear()

		list_changed.emit()

	func add() -> void:
		match type:
			AddType.VAR:
				var_list.append(VarData.new())
			AddType.FUNC:
				func_list.append(FuncData.new())
			AddType.SIGNAL:
				signal_list.append(SignalData.new())
			
		list_changed.emit()

	func change(_type: AddType) -> void:
		type = _type
		list_changed.emit()

	func get_list_to_draw() -> Array:
		match type:
			AddType.VAR:
				return var_list.map(func(x: VarData): return {name = x.name})
			AddType.FUNC:
				return func_list.map(func(x: FuncData): return {name = x.name})
			AddType.SIGNAL:
				return signal_list.map(func(x: SignalData): return {name = x.name})
			
		return []
	
	func on_click(_index: int) -> void:
		var inspector_item_arr: Array
		var name: String = ''

		match type:
			AddType.VAR:
				var item: VarData = var_list[_index]
				name = item.name
				inspector_item_arr = [
					HenInspector.InspectorItem.new({
						name = 'name',
						type = &'String',
						value = item.name,
						ref = item
					}),
					HenInspector.InspectorItem.new({
						name = 'type',
						type = &'@dropdown',
						value = item.type,
						category = 'all_classes',
						ref = item
					}),
					HenInspector.InspectorItem.new({
						name = 'export',
						type = &'bool',
						value = item.export ,
						ref = item
					}),
				]
			AddType.FUNC:
				var item: FuncData = func_list[_index]
				name = item.name
				inspector_item_arr = [
					HenInspector.InspectorItem.new({
						name = 'name',
						type = &'String',
						value = item.name,
						ref = item
					}),
					HenInspector.InspectorItem.new({
						name = 'inputs',
						type = &'Array',
						value = item.inputs,
						item_creation_callback = item.create_param.bind(FuncData.ParamType.INPUT),
						item_move_callback = item.move_param.bind(FuncData.ParamType.INPUT),
						item_delete_callback = item.delete_param.bind(FuncData.ParamType.INPUT),
						field = {name = '', type = '@Param'}
					}),
					HenInspector.InspectorItem.new({
						name = 'outputs',
						type = &'Array',
						value = item.outputs,
						item_creation_callback = item.create_param.bind(FuncData.ParamType.OUTPUT),
						item_move_callback = item.move_param.bind(FuncData.ParamType.OUTPUT),
						item_delete_callback = item.delete_param.bind(FuncData.ParamType.OUTPUT),
						field = {name = '', type = '@Param'}
					})
				]
			AddType.SIGNAL:
				var item: SignalData = signal_list[_index]
				name = item.name
				inspector_item_arr = item.get_inspector_array_list()


		var state_inspector: HenInspector = HenInspector.start(inspector_item_arr)

		state_inspector.item_changed.connect(_on_config_changed)

		HenGlobal.GENERAL_POPUP.get_parent().show_content(
			state_inspector,
			name,
			HenGlobal.CNODE_CONTAINER.get_global_mouse_position()
		)

	func _on_config_changed(_name: StringName, _ref, _inspector: HenInspector) -> void:
		if _ref is SignalData and _name == 'signal_name':
			HenInspector.start(_ref.get_inspector_array_list(), _inspector)

		list_changed.emit()
	
	func get_save() -> Dictionary:
		return {
			var_list = var_list.map(func(x: VarData): return x.get_save()),
			func_list = func_list.map(func(x: FuncData): return x.get_save()),
			signal_list = signal_list.map(func(x: SignalData): return x.get_save()),
		}
	
	func load_save(_data: Dictionary) -> void:
		for item_data: Dictionary in _data.func_list:
			var item: FuncData = FuncData.new(false)
			item.load_save(item_data)
			func_list.append(item)
		
		for item_data: Dictionary in _data.var_list:
			var item: VarData = VarData.new()
			item.load_save(item_data)
			var_list.append(item)

		for item_data: Dictionary in _data.signal_list:
			var item: SignalData = SignalData.new(false)
			item.load_save(item_data)
			signal_list.append(item)
		
		list_changed.emit()


class VarData:
	var id: int = HenGlobal.get_new_node_counter()
	var name: String = 'var ' + str(Time.get_ticks_usec()): set = on_change_name
	var type: StringName = &'Variant': set = on_change_type
	var export: bool = false

	# used in inOut virtual cnode
	signal data_changed(_property: String, _value)

	func on_change_type(_type: StringName) -> void:
		type = _type
		data_changed.emit('type', _type)

	func on_change_name(_name: String) -> void:
		name = _name
		data_changed.emit('value', _name)
		data_changed.emit('code_value', _name.to_snake_case())

	func get_save() -> Dictionary:
		return {
			id = id,
			name = name,
			type = type,
			export = export
		}
	
	func load_save(_data: Dictionary) -> void:
		id = _data.id
		name = _data.name
		type = _data.type
		export = _data.export

		HenGlobal.SIDE_BAR_LIST_CACHE[id] = self


class Param:
	var id: int = HenGlobal.get_new_node_counter()
	var name: String: set = on_change_name
	var type: String = &'Variant': set = on_change_type
	
	signal moved
	signal deleted

	# used in inOut virtual cnode
	signal data_changed(_property: String, _value)

	func on_change_name(_name) -> void:
		data_changed.emit('name', _name)
		name = _name

	func on_change_type(_type) -> void:
		data_changed.emit('type', _type)
		type = _type

	func get_data() -> Dictionary:
		return {name = name, type = type, ref = self}
	
	func get_save() -> Dictionary:
		return {
			name = name,
			type = type,
			id = id
		}
	
	func load_save(_data: Dictionary) -> void:
		id = _data.id
		
		HenGlobal.SIDE_BAR_LIST_CACHE[id] = self

		name = _data.name
		type = _data.type


class FuncData:
	signal name_changed
	signal in_out_added(_is_input: bool, _data: Dictionary)

	var id: int = HenGlobal.get_new_node_counter()
	var name: String = 'func ' + str(Time.get_ticks_usec()): set = on_change_name
	var inputs: Array
	var outputs: Array
	var route: Dictionary
	var virtual_cnode_list: Array = []
	var input_ref: HenVirtualCNode
	var output_ref: HenVirtualCNode

	enum ParamType {INPUT, OUTPUT}

	func _init(_load_vc: bool = true) -> void:
		route = {
			name = name,
			type = HenRouter.ROUTE_TYPE.FUNC,
			id = HenUtilsName.get_unique_name(),
			ref = self
		}

		HenRouter.line_route_reference[route.id] = []
		HenRouter.comment_reference[route.id] = []

		if _load_vc:
			HenVirtualCNode.instantiate_virtual_cnode({
				name = 'input',
				sub_type = HenVirtualCNode.SubType.FUNC_INPUT,
				outputs = outputs.map(func(x: Param) -> Dictionary: return x.get_data()),
				route = route,
				position = Vector2.ZERO,
				ref = self
			})

			HenVirtualCNode.instantiate_virtual_cnode({
				name = 'output',
				sub_type = HenVirtualCNode.SubType.FUNC_OUTPUT,
				route = route,
				inputs = inputs.map(func(x: Param) -> Dictionary: return x.get_data()),
				position = Vector2(400, 0),
				ref = self
			})

	func on_change_name(_name: String) -> void:
		name = _name
		name_changed.emit(_name)

	func create_param(_type: ParamType) -> void:
		var in_out: Param = Param.new()

		match _type:
			ParamType.INPUT:
				inputs.append(in_out)
				in_out_added.emit(true, in_out.get_data())
			ParamType.OUTPUT:
				outputs.append(in_out)
				in_out_added.emit(false, in_out.get_data())
		

	func move_param(_ref: Param, _type: ParamType) -> void:
		match _type:
			ParamType.INPUT:
				_ref.moved.emit(true, inputs.find(_ref))
			ParamType.OUTPUT:
				_ref.moved.emit(false, outputs.find(_ref))


	func delete_param(_ref: Param, _type: ParamType) -> void:
		_ref.deleted.emit(_type == ParamType.INPUT)


	func get_cnode_data() -> Dictionary:
		return {
				name = name,
				fantasy_name = 'Func -> ' + name,
				sub_type = HenCnode.SUB_TYPE.USER_FUNC,
				inputs = inputs.map(func(x: Param) -> Dictionary: return x.get_data()),
				outputs = outputs.map(func(x: Param) -> Dictionary: return x.get_data()),
				route = HenRouter.current_route,
				ref = self
		}
	
	func get_save() -> Dictionary:
		return {
			id = id,
			name = name,
			inputs = inputs.map(func(x: Param) -> Dictionary: return x.get_save()),
			outputs = outputs.map(func(x: Param) -> Dictionary: return x.get_save()),
			virtual_cnode_list = virtual_cnode_list.map(func(x: HenVirtualCNode) -> Dictionary: return x.get_save()),
		}
	
	func load_save(_data: Dictionary) -> void:
		name = _data.name
		id = _data.id

		HenGlobal.SIDE_BAR_LIST_CACHE[id] = self

		for item_data: Dictionary in _data.inputs:
			var item: Param = Param.new()
			item.load_save(item_data)
			inputs.append(item)

		for item_data: Dictionary in _data.outputs:
			var item: Param = Param.new()
			item.load_save(item_data)
			outputs.append(item)

		HenLoader._load_vc(_data.virtual_cnode_list, route)


class SignalData:
	signal name_changed
	signal in_out_added(_is_input: bool, _data: Dictionary)
	signal in_out_reseted(_new_inputs: Array[Dictionary])

	var id: int = HenGlobal.get_new_node_counter()
	var name: String = 'signal ' + str(Time.get_ticks_usec())
	var route: Dictionary
	var virtual_cnode_list: Array = []
	var type: StringName = &'Variant'
	var params: Array
	var bind_params: Array
	var signal_name: StringName
	var signal_name_to_code: StringName
	var signal_enter: HenVirtualCNode

	func _init(_load_vc: bool = true) -> void:
		route = {
			name = name,
			type = HenRouter.ROUTE_TYPE.SIGNAL,
			id = HenUtilsName.get_unique_name(),
			ref = self
		}

		HenRouter.line_route_reference[route.id] = []
		HenRouter.comment_reference[route.id] = []

		if _load_vc:
			HenVirtualCNode.instantiate_virtual_cnode({
				name = 'signal',
				sub_type = HenVirtualCNode.SubType.SIGNAL_ENTER,
				route = route,
				position = Vector2.ZERO,
				ref = self
			})
		
	func set_signal_params(_class: StringName, _signal: StringName) -> void:
		type = _class
		signal_name_to_code = _signal
		params = []

		for param_data: Dictionary in ClassDB.class_get_signal(_class, _signal).args:
			var param: Param = Param.new()
			param.name = param_data.name
			param.type = type_string(param_data.type)
			params.append(param)
		
		var inputs: Array = params.map(func(x: Param) -> Dictionary: return x.get_data())
		var bind_inputs: Array = bind_params.map(func(x: Param) -> Dictionary: return x.get_data())
		
		inputs.append_array(bind_inputs)

		in_out_reseted.emit(
			true,
			inputs,
			[HenVirtualCNode.SubType.SIGNAL_ENTER]
		)

		in_out_reseted.emit(
			true,
			[ {name = type, type = 'Variant', is_ref = true}] + bind_inputs,
			[HenVirtualCNode.SubType.SIGNAL_CONNECTION],
		)
	
	func get_connect_cnode_data() -> Dictionary:
		return {
				name = name,
				fantasy_name = 'Signal -> ' + name,
				sub_type = HenVirtualCNode.SubType.SIGNAL_CONNECTION,
				inputs = [ {name = type, type = 'Variant', is_ref = true}] + bind_params.map(func(x: Param) -> Dictionary: return x.get_data()),
				route = HenRouter.current_route,
				ref = self
		}
	
	func get_diconnect_cnode_data() -> Dictionary:
		return {
				name = name,
				fantasy_name = 'Dis Signal -> ' + name,
				sub_type = HenVirtualCNode.SubType.SIGNAL_DISCONNECTION,
				inputs = [ {name = type, type = 'Variant', is_ref = true}],
				route = HenRouter.current_route,
				ref = self
		}
	
	func create_param() -> void:
		var in_out: Param = Param.new()
		bind_params.append(in_out)
		in_out_added.emit(true, in_out.get_data())
		
	func move_param(_ref: Param) -> void:
		_ref.moved.emit(true, bind_params.find(_ref))

	func delete_param(_ref: Param) -> void:
		_ref.deleted.emit(true)

	func get_inspector_array_list() -> Array:
		return [
			HenInspector.InspectorItem.new({
				name = 'name',
				type = &'String',
				value = name,
				ref = self
			}),
			HenInspector.InspectorItem.new({
				name = 'type',
				type = &'Label',
				value = type,
				ref = self
			}),
			HenInspector.InspectorItem.new({
				name = 'signal_name',
				type = &'@dropdown',
				value = signal_name,
				category = 'signal_list',
				data = {
					signal_ref = self
				},
				ref = self
			}),
			HenInspector.InspectorItem.new({
				name = 'bind_params',
				type = &'Array',
				value = bind_params,
				item_creation_callback = create_param,
				item_move_callback = move_param,
				item_delete_callback = delete_param,
				field = {name = '', type = '@Param'}
			}),
		]
	
	func get_save() -> Dictionary:
		return {
			id = id,
			name = name,
			type = type,
			signal_name = signal_name,
			signal_name_to_code = signal_name_to_code,
			params = params.map(func(x: Param) -> Dictionary: return x.get_save()),
			bind_params = bind_params.map(func(x: Param) -> Dictionary: return x.get_save()),
			virtual_cnode_list = virtual_cnode_list.map(func(x: HenVirtualCNode) -> Dictionary: return x.get_save()),
		}
	
	func load_save(_data: Dictionary) -> void:
		id = _data.id
		name = _data.name
		type = _data.type
		signal_name = _data.signal_name
		signal_name_to_code = _data.signal_name_to_code

		HenGlobal.SIDE_BAR_LIST_CACHE[id] = self

		for item_data: Dictionary in _data.params:
			var item: Param = Param.new()
			item.load_save(item_data)
			params.append(item)

		for item_data: Dictionary in _data.bind_params:
			var item: Param = Param.new()
			item.load_save(item_data)
			bind_params.append(item)

		HenLoader._load_vc(_data.virtual_cnode_list, route)


func _ready() -> void:
	list_data = SideBarList.new()
	list_data.list_changed.connect(_on_list_changed)


	HenGlobal.SIDE_BAR = self
	HenGlobal.SIDE_BAR_LIST = list_data

	_on_change_list(AddType.VAR)

	(get_node('%Add') as Button).pressed.connect(_on_add)

	# change list
	(get_node('%Var') as Button).pressed.connect(_on_change_list.bind(AddType.VAR))
	(get_node('%Func') as Button).pressed.connect(_on_change_list.bind(AddType.FUNC))
	(get_node('%Signal') as Button).pressed.connect(_on_change_list.bind(AddType.SIGNAL))

	list.item_activated.connect(_on_enter)
	list.item_clicked.connect(_on_click)


func _on_enter(_index: int) -> void:
	match HenGlobal.SIDE_BAR_LIST.type:
		AddType.FUNC:
			HenRouter.change_route((HenGlobal.SIDE_BAR_LIST.func_list[_index] as FuncData).route)
		AddType.SIGNAL:
			HenRouter.change_route((HenGlobal.SIDE_BAR_LIST.signal_list[_index] as SignalData).route)


func _on_click(_index: int, _at_position: Vector2, _mouse_button_index: int) -> void:
	if _mouse_button_index == MOUSE_BUTTON_RIGHT:
		list_data.on_click(_index)


func update_list() -> void:
	list.clear()

	for item_data: Dictionary in HenGlobal.SIDE_BAR_LIST.get_list_to_draw():
		list.add_item(item_data.name)


func _on_add() -> void:
	HenGlobal.SIDE_BAR_LIST.add()


func _on_change_list(_type: AddType) -> void:
	HenGlobal.SIDE_BAR_LIST.change(_type)
	name_label.text = NAME[_type]


func _on_list_changed() -> void:
	update_list()