class_name HenSignalData extends RefCounted


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


func on_change_name(_name: String) -> void:
	name = _name
	name_changed.emit(_name)
	HenGlobal.SIDE_BAR_LIST.list_changed.emit()


func on_change_signal_name(_name: String) -> void:
	signal_name = _name


func set_signal_params(_class: StringName, _signal: StringName) -> void:
	type = _class
	signal_name_to_code = _signal
	params = []

	for param_data: Dictionary in ClassDB.class_get_signal(_class, _signal).args:
		var param: HenParamData = HenParamData.new()
		param.name = param_data.name
		param.type = type_string(param_data.type)
		params.append(param)
	
	var inputs: Array = params.map(func(x: HenParamData) -> Dictionary: return x.get_data())
	var bind_inputs: Array = bind_params.map(func(x: HenParamData) -> Dictionary: return x.get_data())
	
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
			inputs = [ {name = type, type = type, is_ref = true}] + bind_params.map(func(x: HenParamData) -> Dictionary: return x.get_data()),
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

func create_param() -> HenParamData:
	var in_out: HenParamData = HenParamData.new()
	bind_params.append(in_out)
	in_out_added.emit(true, in_out.get_data())
	return in_out
	

func move_param(_direction: HenArrayItem.ArrayMove, _ref: HenParamData) -> void:
	var can_move: bool = false

	match _direction:
		HenArrayItem.ArrayMove.UP:
			can_move = HenUtils.move_array_item(bind_params, _ref, 1)
		HenArrayItem.ArrayMove.DOWN:
			can_move = HenUtils.move_array_item(bind_params, _ref, -1)

	if can_move: _ref.moved.emit(true, bind_params.find(_ref))


func delete_param(_ref: HenParamData) -> void:
	bind_params.erase(_ref)
	_ref.deleted.emit(true)


func delete() -> void:
	var item_cache: HenSideBar.DeleteItemCache = HenSideBar.DeleteItemCache.new(self, HenGlobal.SIDE_BAR_LIST.signal_list)

	HenGlobal.history.create_action('Delete Signal')
	HenGlobal.history.add_do_method(item_cache.remove)
	HenGlobal.history.add_undo_reference(item_cache)
	HenGlobal.history.add_undo_method(item_cache.add)
	HenGlobal.history.commit_action()

	HenGlobal.GENERAL_POPUP.get_parent().hide_popup()

func get_inspector_array_list() -> Array:
	return [
   		HenPropEditor.Prop.new({
			name = 'name',
			type = HenPropEditor.Prop.Type.STRING,
			default_value = name,
			on_value_changed = on_change_name
		}),
   		HenPropEditor.Prop.new({
			name = 'Signal Name',
			type = HenPropEditor.Prop.Type.DROPDOWN,
			default_value = signal_name,
			on_value_changed = on_change_signal_name,
			category = 'signal_list',
		    data = {
		        signal_ref = self
		    },
		}),
		HenPropEditor.Prop.new({
			name = 'Outputs',
			type = HenPropEditor.Prop.Type.ARRAY,
			on_item_create = create_param,
			prop_list = bind_params.map(func(x: HenParamData) -> HenPropEditor.Prop: return HenPropEditor.Prop.new({
				name = 'name',
				type = HenPropEditor.Prop.Type.STRING,
				default_value = x.name,
				on_value_changed = x.on_change_name,
				on_item_delete = delete_param.bind(x),
				on_item_move = move_param.bind(x),
			})),
		}),
	]

func get_save() -> Dictionary:
	return {
		id = id,
		name = name,
		type = type,
		signal_name = signal_name,
		signal_name_to_code = signal_name_to_code,
		params = params.map(func(x: HenParamData) -> Dictionary: return x.get_save()),
		bind_params = bind_params.map(func(x: HenParamData) -> Dictionary: return x.get_save()),
		virtual_cnode_list = virtual_cnode_list.map(func(x: HenVirtualCNode) -> Dictionary: return x.get_save()),
		local_vars = local_vars.map(func(x: HenVarData) -> Dictionary: return x.get_save()),
	}

func load_save(_data: Dictionary) -> void:
	id = _data.id
	name = _data.name
	type = _data.type
	signal_name = _data.signal_name
	signal_name_to_code = _data.signal_name_to_code

	HenGlobal.SIDE_BAR_LIST_CACHE[id] = self

	for item_data: Dictionary in _data.params:
		var item: HenParamData = HenParamData.new()
		item.load_save(item_data)
		params.append(item)

	for item_data: Dictionary in _data.bind_params:
		var item: HenParamData = HenParamData.new()
		item.load_save(item_data)
		bind_params.append(item)

	
	for item_data: Dictionary in _data.local_vars:
		var item: HenVarData = HenVarData.new()
		item.local_ref = self
		item.load_save(item_data)
		local_vars.append(item)

	cnode_list_to_load = _data.virtual_cnode_list
