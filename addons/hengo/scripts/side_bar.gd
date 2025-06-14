@tool
class_name HenSideBar extends PanelContainer

var list: Tree
# @onready var name_label: Label = %Name
# @onready var local_var_bt: Button = %LocalVar

enum AddType {VAR, FUNC, SIGNAL, LOCAL_VAR, MACRO}
enum ParamType {INPUT, OUTPUT}

const BG_COLOR = {
	AddType.VAR: Color.WHITE,
	AddType.FUNC: Color.RED,
	AddType.SIGNAL: Color.GREEN,
	AddType.MACRO: Color.MEDIUM_PURPLE,
	AddType.LOCAL_VAR: Color.ORANGE
}

const ICONS = {
	AddType.VAR: preload('res://addons/hengo/assets/icons/menu/cuboid.svg'),
	AddType.MACRO: preload('res://addons/hengo/assets/icons/menu/text.svg'),
	AddType.FUNC: preload('res://addons/hengo/assets/icons/menu/void.svg'),
	AddType.SIGNAL: preload('res://addons/hengo/assets/icons/menu/wifi.svg'),
	AddType.LOCAL_VAR: preload('res://addons/hengo/assets/icons/menu/cuboid.svg')
}

const NAME = {
	AddType.VAR: 'Variables',
	AddType.FUNC: 'Functions',
	AddType.SIGNAL: 'Signals',
	AddType.LOCAL_VAR: 'Local Variables',
	AddType.MACRO: 'Macro'
}


class SideBarList:
	var type: AddType

	var var_list: Array
	var func_list: Array
	var signal_list: Array
	var macro_list: Array

	signal list_changed

	func clear() -> void:
		var_list.clear()
		func_list.clear()
		signal_list.clear()
		macro_list.clear()

		change(AddType.VAR)
		list_changed.emit()

	func add() -> void:
		match type:
			AddType.VAR:
				var_list.append(VarData.new())
			AddType.FUNC:
				func_list.append(FuncData.new())
			AddType.SIGNAL:
				signal_list.append(SignalData.new())
			AddType.MACRO:
				macro_list.append(MacroData.new())
			AddType.LOCAL_VAR:
				if HenRouter.current_route.ref.get(&'local_vars') is Array:
					var var_data: VarData = VarData.new()
					var_data.local_ref = HenRouter.current_route.ref
					
					(HenRouter.current_route.ref.local_vars as Array).append(var_data)

		list_changed.emit()

	func change(_type: AddType) -> void:
		type = _type

	func get_list_to_draw() -> Array:
		match type:
			AddType.VAR:
				return var_list.map(func(x: VarData): return {name = x.name})
			AddType.FUNC:
				return func_list.map(func(x: FuncData): return {name = x.name})
			AddType.SIGNAL:
				return signal_list.map(func(x: SignalData): return {name = x.name})
			AddType.MACRO:
				return macro_list.map(func(x: MacroData): return {name = x.name})
			AddType.LOCAL_VAR:
				if HenRouter.current_route.ref.get(&'local_vars') is Array:
					return (HenRouter.current_route.ref.local_vars as Array).map(func(x: VarData): return {name = x.name})
			
		return []
	
	func on_click(_item) -> void:
		var inspector_item_arr: Array
		var name: String = ''

		inspector_item_arr = _item.get_inspector_array_list()

		name = _item.name

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
			macro_list = macro_list.map(func(x: MacroData): return x.get_save())
		}
	
	func load_save(_data: Dictionary) -> void:
		for item_data: Dictionary in _data.var_list:
			var item: VarData = VarData.new()
			item.load_save(item_data)
			var_list.append(item)

		for item_data: Dictionary in _data.func_list:
			var item: FuncData = FuncData.new(false)
			item.load_save(item_data)
			func_list.append(item)
		
		for item_data: Dictionary in _data.signal_list:
			var item: SignalData = SignalData.new(false)
			item.load_save(item_data)
			signal_list.append(item)

		for item_data: Dictionary in _data.macro_list:
			var item: MacroData = MacroData.new(false)
			item.load_save(item_data)
			macro_list.append(item)

		# loading cnodes
		for item in HenGlobal.SIDE_BAR_LIST_CACHE.values():
			if item.get('cnode_list_to_load') is Array:
				HenLoader._load_vc(item.cnode_list_to_load, item.route)

		list_changed.emit()

class DeleteItemCache:
	var item: RefCounted
	var arr: Array
	var idx: int

	func _init(_item: RefCounted, _arr: Array) -> void:
		item = _item
		arr = _arr

	func remove() -> void:
		idx = arr.find(item)
		arr.erase(item)
		item.emit_signal('deleted', true)
		HenGlobal.SIDE_BAR_LIST.list_changed.emit()
	
	func add() -> void:
		arr.append(item)
		HenUtils.move_array_item_to_idx(arr, item, idx)
		item.emit_signal('deleted', false)
		HenGlobal.SIDE_BAR_LIST.list_changed.emit()


class VarData:
	var id: int = HenGlobal.get_new_node_counter()
	var name: String = 'var ' + str(Time.get_ticks_usec()): set = on_change_name
	var type: StringName = &'Variant': set = on_change_type
	var local_ref: RefCounted
	var export: bool = false

	# used in inOut virtual cnode
	signal data_changed(_property: String, _value)
	signal deleted(_deleted: bool)

	func on_change_type(_type: StringName) -> void:
		type = _type
		data_changed.emit('type', _type)

	func on_change_name(_name: String) -> void:
		name = _name
		data_changed.emit('name', _name)

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
	
	func delete() -> void:
		var item_cache: DeleteItemCache = DeleteItemCache.new(self, HenGlobal.SIDE_BAR_LIST.var_list if not local_ref else local_ref.get(&'local_vars'))

		HenGlobal.history.create_action('Delete Variable')
		HenGlobal.history.add_do_method(item_cache.remove)
		HenGlobal.history.add_undo_reference(item_cache)
		HenGlobal.history.add_undo_method(item_cache.add)
		HenGlobal.history.commit_action()

		HenGlobal.GENERAL_POPUP.get_parent().hide_popup()


	func get_inspector_array_list(_is_local: bool = false) -> Array:
		return [
			HenInspector.InspectorItem.new({
				type = &'@controls',
				ref = self
			}),
			HenInspector.InspectorItem.new({
				name = 'name',
				type = &'String',
				value = name,
				ref = self
			}),
			HenInspector.InspectorItem.new({
				name = 'type',
				type = &'@dropdown',
				value = type,
				category = 'all_classes',
				ref = self
			})
		] + ([
			HenInspector.InspectorItem.new({
				name = 'export',
				type = &'bool',
				value = export ,
				ref = self
			}),
		] if not _is_local else [])


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
		
	func get_data_with_id() -> Dictionary:
		return {id = id, name = name, type = type, ref = self}


	func get_save() -> Dictionary:
		return {
			name = name,
			type = type,
			id = id
		}
	
	func get_save_without_id() -> Dictionary:
		return {
			name = name,
			type = type
		}

	func get_save_with_from_id() -> Dictionary:
		return {
			name = name,
			type = type,
			from_id = id
		}

	func load_save(_data: Dictionary) -> void:
		id = _data.id
		
		HenGlobal.SIDE_BAR_LIST_CACHE[id] = self

		name = _data.name
		type = _data.type


class FuncData:
	signal name_changed
	signal in_out_added(_is_input: bool, _data: Dictionary)
	signal deleted(_deleted: bool)

	var id: int = HenGlobal.get_new_node_counter()
	var name: String = 'func ' + str(Time.get_ticks_usec()): set = on_change_name
	var inputs: Array
	var outputs: Array
	var route: Dictionary
	var virtual_cnode_list: Array
	var input_ref: HenVirtualCNode
	var output_ref: HenVirtualCNode
	var local_vars: Array
	var cnode_list_to_load: Array

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
				ref = self,
				can_delete = false
			})

			HenVirtualCNode.instantiate_virtual_cnode({
				name = 'output',
				sub_type = HenVirtualCNode.SubType.FUNC_OUTPUT,
				route = route,
				inputs = inputs.map(func(x: Param) -> Dictionary: return x.get_data()),
				position = Vector2(400, 0),
				ref = self,
				can_delete = false
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
				sub_type = HenVirtualCNode.SubType.USER_FUNC,
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
			local_vars = local_vars.map(func(x: VarData) -> Dictionary: return x.get_save()),
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
		
		for item_data: Dictionary in _data.local_vars:
			var item: VarData = VarData.new()
			item.local_ref = self
			item.load_save(item_data)
			local_vars.append(item)

		cnode_list_to_load = _data.virtual_cnode_list
		# HenLoader._load_vc(_data.virtual_cnode_list, route)

	func delete() -> void:
		var item_cache: DeleteItemCache = DeleteItemCache.new(self, HenGlobal.SIDE_BAR_LIST.func_list)

		HenGlobal.history.create_action('Delete Function')
		HenGlobal.history.add_do_method(item_cache.remove)
		HenGlobal.history.add_undo_reference(item_cache)
		HenGlobal.history.add_undo_method(item_cache.add)
		HenGlobal.history.commit_action()

		HenGlobal.GENERAL_POPUP.get_parent().hide_popup()

	func get_inspector_array_list() -> Array:
		return [
			HenInspector.InspectorItem.new({
				type = &'@controls',
				ref = self
			}),
			HenInspector.InspectorItem.new({
				name = 'name',
				type = &'String',
				value = name,
				ref = self
			}),
			HenInspector.InspectorItem.new({
				name = 'inputs',
				type = &'Array',
				value = inputs,
				max_size = 5,
				item_creation_callback = create_param.bind(ParamType.INPUT),
				item_move_callback = move_param.bind(ParamType.INPUT),
				item_delete_callback = delete_param.bind(ParamType.INPUT),
				field = {name = '', type = '@Param'}
			}),
			HenInspector.InspectorItem.new({
				name = 'outputs',
				type = &'Array',
				value = outputs,
				max_size = 5,
				item_creation_callback = create_param.bind(ParamType.OUTPUT),
				item_move_callback = move_param.bind(ParamType.OUTPUT),
				item_delete_callback = delete_param.bind(ParamType.OUTPUT),
				field = {name = '', type = '@Param'}
			})
		]


class SignalData:
	signal name_changed
	signal in_out_added(_is_input: bool, _data: Dictionary)
	signal in_out_reseted(_new_inputs: Array[Dictionary])
	signal deleted(_deleted: bool)

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
	var local_vars: Array
	var cnode_list_to_load: Array

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
				ref = self,
				can_delete = false
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
			[ {name = type, type = type, is_ref = true}] + bind_inputs,
			[HenVirtualCNode.SubType.SIGNAL_CONNECTION],
		)

		in_out_reseted.emit(
			true,
			[ {name = type, type = type, is_ref = true}],
			[HenVirtualCNode.SubType.SIGNAL_DISCONNECTION],
		)
	
	func get_connect_cnode_data() -> Dictionary:
		return {
				name = name,
				fantasy_name = 'Signal -> ' + name,
				sub_type = HenVirtualCNode.SubType.SIGNAL_CONNECTION,
				inputs = [ {name = type, type = type, is_ref = true}] + bind_params.map(func(x: Param) -> Dictionary: return x.get_data()),
				route = HenRouter.current_route,
				ref = self
		}
	
	func get_diconnect_cnode_data() -> Dictionary:
		return {
				name = name,
				fantasy_name = 'Dis Signal -> ' + name,
				sub_type = HenVirtualCNode.SubType.SIGNAL_DISCONNECTION,
				inputs = [ {name = type, type = type, is_ref = true}],
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

	func delete() -> void:
		var item_cache: DeleteItemCache = DeleteItemCache.new(self, HenGlobal.SIDE_BAR_LIST.signal_list)

		HenGlobal.history.create_action('Delete Signal')
		HenGlobal.history.add_do_method(item_cache.remove)
		HenGlobal.history.add_undo_reference(item_cache)
		HenGlobal.history.add_undo_method(item_cache.add)
		HenGlobal.history.commit_action()

		HenGlobal.GENERAL_POPUP.get_parent().hide_popup()

	func get_inspector_array_list() -> Array:
		return [
			HenInspector.InspectorItem.new({
				type = &'@controls',
				ref = self
			}),
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
			# HenInspector.InspectorItem.new({
			# 	name = 'bind_params',
			# 	type = &'Array',
			# 	value = bind_params,
			# 	max_size = 5,
			# 	item_creation_callback = create_param,
			# 	item_move_callback = move_param,
			# 	item_delete_callback = delete_param,
			# 	field = {name = '', type = '@Param'}
			# }),
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
			local_vars = local_vars.map(func(x: VarData) -> Dictionary: return x.get_save()),
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

		
		for item_data: Dictionary in _data.local_vars:
			var item: VarData = VarData.new()
			item.local_ref = self
			item.load_save(item_data)
			local_vars.append(item)

		cnode_list_to_load = _data.virtual_cnode_list
		# HenLoader._load_vc(_data.virtual_cnode_list, route)


class MacroData:
	signal name_changed
	signal flow_added(_is_input: bool, _data: Dictionary)
	signal in_out_added(_is_input: bool, _data: Dictionary)
	signal deleted(_deleted: bool)

	var id: int = HenGlobal.get_new_node_counter()
	var name: String = 'macro ' + str(Time.get_ticks_usec()): set = on_change_name
	var route: Dictionary
	var virtual_cnode_list: Array = []
	var inputs: Array
	var outputs: Array
	var inputs_value: Array
	var outputs_value: Array
	var input_ref: HenVirtualCNode
	var output_ref: HenVirtualCNode
	var local_vars: Array
	var cnode_list_to_load: Array

	class MacroInOut:
		var id: int = HenGlobal.get_new_node_counter()
		var name: String: set = on_change_name

		signal data_changed(_property: String, _value)
		signal moved
		signal deleted

		func on_change_name(_name: String) -> void:
			name = _name
			data_changed.emit('name', _name)

		func get_data() -> Dictionary:
			return {id = id, name = name, ref = self}
		
		func get_save() -> Dictionary:
			return {
				name = name,
				id = id
			}
		
		func load_save(_data: Dictionary) -> void:
			id = _data.id
			name = _data.name
			
			HenGlobal.SIDE_BAR_LIST_CACHE[id] = self

	func _init(_load_vc: bool = true) -> void:
		route = {
			name = name,
			type = HenRouter.ROUTE_TYPE.MACRO,
			id = HenUtilsName.get_unique_name(),
			ref = self
		}

		HenRouter.line_route_reference[route.id] = []
		HenRouter.comment_reference[route.id] = []

		if _load_vc:
			HenVirtualCNode.instantiate_virtual_cnode({
				name = 'input',
				type = HenVirtualCNode.Type.MACRO_INPUT,
				sub_type = HenVirtualCNode.SubType.MACRO_INPUT,
				route = route,
				position = Vector2.ZERO,
				ref = self,
				can_delete = false
			})

			HenVirtualCNode.instantiate_virtual_cnode({
				name = 'output',
				type = HenVirtualCNode.Type.MACRO_OUTPUT,
				sub_type = HenVirtualCNode.SubType.MACRO_OUTPUT,
				route = route,
				position = Vector2(400, 0),
				ref = self,
				can_delete = false
			})

	func on_change_name(_name: String) -> void:
		name = _name
		name_changed.emit(_name)

	func crate_flow(_type: ParamType) -> void:
		var flow: MacroInOut = MacroInOut.new()

		match _type:
			ParamType.INPUT:
				flow.name = 'Flow ' + str(inputs.size())
				inputs.append(flow)
				flow_added.emit(true, flow.get_data())
			ParamType.OUTPUT:
				flow.name = 'Flow ' + str(outputs.size())
				outputs.append(flow)
				flow_added.emit(false, flow.get_data())

	
	func create_param(_type: ParamType) -> void:
		var in_out: Param = Param.new()

		match _type:
			ParamType.INPUT:
				inputs_value.append(in_out)
				in_out_added.emit(true, in_out.get_data_with_id())
			ParamType.OUTPUT:
				outputs_value.append(in_out)
				in_out_added.emit(false, in_out.get_data_with_id())
		

	func move_param(_ref: Param, _type: ParamType) -> void:
		match _type:
			ParamType.INPUT:
				_ref.moved.emit(true, inputs_value.find(_ref))
			ParamType.OUTPUT:
				_ref.moved.emit(false, outputs_value.find(_ref))


	func delete_param(_ref: Param, _type: ParamType) -> void:
		_ref.deleted.emit(_type == ParamType.INPUT)


	func move_flow(_ref: MacroInOut, _type: ParamType) -> void:
		match _type:
			ParamType.INPUT:
				_ref.moved.emit(inputs.find(_ref))
			ParamType.OUTPUT:
				_ref.moved.emit(outputs.find(_ref))


	func delete_flow(_ref: MacroInOut, _type: ParamType) -> void:
		_ref.deleted.emit()


	func get_cnode_data() -> Dictionary:
		return {
				name = name,
				type = HenVirtualCNode.Type.MACRO,
				sub_type = HenVirtualCNode.SubType.MACRO,
				inputs = inputs_value.map(func(x: Param) -> Dictionary: return x.get_data_with_id()),
				outputs = outputs_value.map(func(x: Param) -> Dictionary: return x.get_data_with_id()),
				route = HenRouter.current_route,
				ref = self
		}

	func delete() -> void:
		var item_cache: DeleteItemCache = DeleteItemCache.new(self, HenGlobal.SIDE_BAR_LIST.macro_list)

		HenGlobal.history.create_action('Delete Macro')
		HenGlobal.history.add_do_method(item_cache.remove)
		HenGlobal.history.add_undo_reference(item_cache)
		HenGlobal.history.add_undo_method(item_cache.add)
		HenGlobal.history.commit_action()

		HenGlobal.GENERAL_POPUP.get_parent().hide_popup()


	func get_inspector_array_list() -> Array:
		return [
			HenInspector.InspectorItem.new({
				type = &'@controls',
				ref = self
			}),
			HenInspector.InspectorItem.new({
				name = 'name',
				type = &'String',
				value = name,
				ref = self
			}),
			HenInspector.InspectorItem.new({
				name = 'inputs',
				type = &'Array',
				value = inputs,
				max_size = 5,
				item_creation_callback = crate_flow.bind(ParamType.INPUT),
				item_move_callback = move_flow.bind(ParamType.INPUT),
				item_delete_callback = delete_flow.bind(ParamType.INPUT),
				field = {name = 'name', type = 'String'}
			}),
			HenInspector.InspectorItem.new({
				name = 'outputs',
				type = &'Array',
				value = outputs,
				max_size = 5,
				item_creation_callback = crate_flow.bind(ParamType.OUTPUT),
				item_move_callback = move_flow.bind(ParamType.OUTPUT),
				item_delete_callback = delete_flow.bind(ParamType.OUTPUT),
				field = {name = 'name', type = 'String'}
			}),
			
			HenInspector.InspectorItem.new({
				name = 'inputs_value',
				type = &'Array',
				value = inputs_value,
				max_size = 5,
				item_creation_callback = create_param.bind(ParamType.INPUT),
				item_move_callback = move_param.bind(ParamType.INPUT),
				item_delete_callback = delete_param.bind(ParamType.INPUT),
				field = {name = '', type = '@Param'}
			}),
			HenInspector.InspectorItem.new({
				name = 'outputs_value',
				type = &'Array',
				value = outputs_value,
				max_size = 5,
				item_creation_callback = create_param.bind(ParamType.OUTPUT),
				item_move_callback = move_param.bind(ParamType.OUTPUT),
				item_delete_callback = delete_param.bind(ParamType.OUTPUT),
				field = {name = '', type = '@Param'}
			})
		]

		
	func get_save() -> Dictionary:
		return {
			id = id,
			name = name,
			inputs = inputs.map(func(x: MacroInOut) -> Dictionary: return x.get_save()),
			outputs = outputs.map(func(x: MacroInOut) -> Dictionary: return x.get_save()),
			inputs_value = inputs_value.map(func(x: Param) -> Dictionary: return x.get_save()),
			outputs_value = outputs_value.map(func(x: Param) -> Dictionary: return x.get_save()),
			virtual_cnode_list = virtual_cnode_list.map(func(x: HenVirtualCNode) -> Dictionary: return x.get_save()),
			local_vars = local_vars.map(func(x: VarData) -> Dictionary: return x.get_save()),
		}
	
	func load_save(_data: Dictionary) -> void:
		name = _data.name
		id = _data.id

		HenGlobal.SIDE_BAR_LIST_CACHE[id] = self

		for item_data: Dictionary in _data.inputs:
			var item: MacroInOut = MacroInOut.new()
			item.load_save(item_data)
			inputs.append(item)

		for item_data: Dictionary in _data.outputs:
			var item: MacroInOut = MacroInOut.new()
			item.load_save(item_data)
			outputs.append(item)
		
		for item_data: Dictionary in _data.local_vars:
			var item: VarData = VarData.new()
			item.local_ref = self
			item.load_save(item_data)
			local_vars.append(item)

		for item_data: Dictionary in _data.inputs_value:
			var item: Param = Param.new()
			item.load_save(item_data)
			inputs_value.append(item)

		for item_data: Dictionary in _data.outputs_value:
			var item: Param = Param.new()
			item.load_save(item_data)
			outputs_value.append(item)

		cnode_list_to_load = _data.virtual_cnode_list
		# HenLoader._load_vc(_data.virtual_cnode_list, route)


func _ready() -> void:
	if EditorInterface.get_edited_scene_root() == self or EditorInterface.get_edited_scene_root() == owner:
		set_process(false)
		set_physics_process(false)
		set_process_input(false)
		set_process_unhandled_input(false)
		set_process_unhandled_key_input(false)
		return

	list = get_node('%List')
	list.auto_tooltip = false
	list.button_clicked.connect(_on_list_button_clicked)
	list.item_mouse_selected.connect(_on_item_selected)
	list.item_activated.connect(_on_select)
	list.gui_input.connect(_on_gui)
	list.mouse_exited.connect(_on_exit)

	HenGlobal.SIDE_BAR = self
	HenGlobal.SIDE_BAR_LIST = SideBarList.new()
	HenGlobal.SIDE_BAR_LIST.list_changed.connect(_on_list_changed)


func _on_exit() -> void:
	HenGlobal.TOOLTIP.close()


func _on_gui(_event: InputEvent) -> void:
	if _event is InputEventMouseMotion:
		var item: TreeItem = list.get_item_at_position((_event as InputEventMouseMotion).position)
		var bt_id: int = list.get_button_id_at_position((_event as InputEventMouseMotion).position)

		if bt_id >= 0:
			HenGlobal.TOOLTIP.close()
			return

		if item:
			var data = item.get_metadata(0)
			var pos: Vector2 = (_event as InputEventMouseMotion).global_position + Vector2(20, 20)

			if not data is int:
				if data is VarData:
					HenGlobal.TOOLTIP.go_to(pos, '[b]{type}[/b]\n{name}\n\n{inspect}'.format({
						name = data.name,
						type = data.type,
						inspect = HenEnums.TOOLTIP_TEXT.RIGHT_MOUSE_INSPECT
					}))
				elif data is FuncData:
					HenGlobal.TOOLTIP.go_to(pos, '{name}\n\n[b]Input size: [/b]{in_size}\n\n[b]Output size: [/b]{out_size}\n\n{inspect}\n{enter}'.format({
						name = data.name,
						in_size = data.inputs.size(),
						out_size = data.outputs.size(),
						inspect = HenEnums.TOOLTIP_TEXT.RIGHT_MOUSE_INSPECT,
						enter = HenEnums.TOOLTIP_TEXT.DOUBLE_CLICK
					}))
				elif data is SignalData:
					HenGlobal.TOOLTIP.go_to(pos, '{name}\n\n[b]Signal: [/b] {s_name}\n\n{inspect}\n{enter}'.format({
						name = data.name,
						s_name = data.signal_name if data.signal_name else 'Not Selected',
						inspect = HenEnums.TOOLTIP_TEXT.RIGHT_MOUSE_INSPECT,
						enter = HenEnums.TOOLTIP_TEXT.DOUBLE_CLICK
					}))
				elif data is MacroData:
					HenGlobal.TOOLTIP.go_to(pos, '{name}\n\n[b]Flow Input Size: [/b] {fi_size}\n[b]Flow Output Size: [/b] {fo_size}\n\n[b]Input Size: [/b] {i_size}\n[b]Output Size: [/b] {o_size}\n\n{inspect}\n{enter}'.format({
						name = data.name,
						fi_size = data.inputs.size(),
						fo_size = data.outputs.size(),
						i_size = data.inputs_value.size(),
						o_size = data.outputs_value.size(),
						inspect = HenEnums.TOOLTIP_TEXT.RIGHT_MOUSE_INSPECT,
						enter = HenEnums.TOOLTIP_TEXT.DOUBLE_CLICK
					}))
			else:
				HenGlobal.TOOLTIP.close()
		

func _on_select() -> void:
	var obj = list.get_selected().get_metadata(0)
	
	if obj.get('route'):
		HenRouter.change_route(obj.get('route'))

func _on_item_selected(_mouse_position: Vector2, _mouse_button_index: int) -> void:
	match _mouse_button_index:
		2:
			HenGlobal.SIDE_BAR_LIST.on_click(list.get_selected().get_metadata(0))


func _on_list_changed() -> void:
	list.clear()

	var root: TreeItem = list.create_item()
	var base: TreeItem = root.create_child()

	base.set_text(0, 'Base')

	# variables
	_add_categories(root, 'Variables', AddType.VAR)
	_add_categories(root, 'Functions', AddType.FUNC)
	_add_categories(root, 'Signals', AddType.SIGNAL)
	_add_categories(root, 'Macros', AddType.MACRO)

	if not HenRouter.current_route.is_empty() and HenRouter.current_route.ref.get(&'local_vars') is Array:
		_add_categories(root, 'Local Variables', AddType.LOCAL_VAR)


func _add_categories(_root: TreeItem, _name: String, _type: AddType) -> void:
	# variables
	var category: TreeItem = _root.create_child()
	category.set_text(0, _name)
	category.add_button(0, preload('res://addons/hengo/assets/icons/menu/square-plus.svg'))
	category.set_metadata(0, _type)
	category.set_selectable(0, false)
	category.set_icon_modulate(0, BG_COLOR[_type])
	category.set_custom_color(0, BG_COLOR[_type])
	category.set_button_color(0, 0, (BG_COLOR[_type] as Color).lightened(0.6))
	category.set_icon(0, ICONS[_type])

	var arr: Array

	match _type:
		AddType.VAR:
			arr = HenGlobal.SIDE_BAR_LIST.var_list
		AddType.FUNC:
			arr = HenGlobal.SIDE_BAR_LIST.func_list
		AddType.SIGNAL:
			arr = HenGlobal.SIDE_BAR_LIST.signal_list
		AddType.MACRO:
			arr = HenGlobal.SIDE_BAR_LIST.macro_list
		AddType.LOCAL_VAR:
			if HenRouter.current_route.ref.get(&'local_vars') is Array:
				arr = (HenRouter.current_route.ref.local_vars as Array)

	for item_data in arr:
		var item: TreeItem = category.create_child()
		item.set_text(0, item_data.name)
		item.set_metadata(0, item_data)
		# item.set_custom_bg_color(0, Color((BG_COLOR[_type] as Color), .1))
		item.set_custom_color(0, Color(1, 1, 1, .6))

		match _type:
			AddType.VAR, AddType.LOCAL_VAR:
				item.set_icon(0, HenAssets.get_icon_texture(item_data.type))
			_:
				item.set_icon_modulate(0, BG_COLOR[_type])
				item.set_icon(0, ICONS[_type])


func _on_list_button_clicked(_item: TreeItem, _column: int, _id: int, _mouse_button_index: int) -> void:
	var _type: AddType = _item.get_metadata(0)

	HenGlobal.SIDE_BAR_LIST.change(_type)
	HenGlobal.SIDE_BAR_LIST.add()


	# _on_change_list(AddType.VAR)

	# local_var_bt.visible = false
	# local_var_bt.pressed.connect(_on_change_list.bind(AddType.LOCAL_VAR))

	# (get_node('%Add') as Button).pressed.connect(_on_add)

	# # change list
	# (get_node('%Var') as Button).pressed.connect(_on_change_list.bind(AddType.VAR))
	# (get_node('%Func') as Button).pressed.connect(_on_change_list.bind(AddType.FUNC))
	# (get_node('%Signal') as Button).pressed.connect(_on_change_list.bind(AddType.SIGNAL))
	# (get_node('%Macro') as Button).pressed.connect(_on_change_list.bind(AddType.MACRO))

	# list.item_activated.connect(_on_enter)
	# list.item_clicked.connect(_on_click)
