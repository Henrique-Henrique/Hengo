@tool
class_name HenSaveState extends HenSaveResTypeWithRoute

@export var flow_outputs: Array[HenSaveParam]
@export var transition_data: Array[HenSaveParam]
@export var is_sub_state: bool

static func create(_is_sub_state: bool = false) -> HenSaveState:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var state: HenSaveState = HenSaveState.new()

	state.id = global.get_new_node_counter()
	state.name = state.get_new_name()
	state.is_sub_state = _is_sub_state

	var route: HenRouteData = state.create_route(HenRouter.ROUTE_TYPE.STATE)

	HenVirtualCNode.instantiate_virtual_cnode({
		name = 'enter',
		sub_type = HenVirtualCNode.SubType.VIRTUAL,
		route = route,
		position = Vector2.ZERO,
		can_delete = false,
		res_data = state.get_res_data(HenSideBar.AddType.STATE)
	})

	HenVirtualCNode.instantiate_virtual_cnode({
		name = 'update',
		sub_type = HenVirtualCNode.SubType.VIRTUAL,
		outputs = [ {
			name = 'delta',
			type = 'float'
		}],
		route = route,
		position = Vector2(400, 0),
		can_delete = false
	})

	return state


func get_new_name() -> String:
	return 'state_' + str(id)


func get_vc_name(_type: HenVirtualCNode.SubType) -> String:
	match _type:
		HenVirtualCNode.SubType.VIRTUAL:
			return 'enter'
		HenVirtualCNode.SubType.STATE_TRANSITION:
			return 'Transition -> ' + name
	
	
	return name


func add_sub_state(_save_data: HenSaveData) -> void:
	var s: HenSaveState = HenSaveState.create(true)

	if not s:
		return

	if not _save_data.sub_states.has(id):
		_save_data.sub_states.set(id, [])

	var states_list: Array = _save_data.sub_states.get(id)

	if not states_list.has(s):
		states_list.append(s)


func get_sub_states(_save_data: HenSaveData) -> Array:
	if not _save_data.sub_states.has(id):
		return []

	return _save_data.sub_states.get(id)


func get_inputs(_type: HenVirtualCNode.SubType) -> Array[Dictionary]:
	var arr: Array[Dictionary] = []

	if _type == HenVirtualCNode.SubType.STATE_TRANSITION:
		for param: HenSaveParam in transition_data:
			arr.append(param.get_data())

	return arr


func get_outputs(_type: HenVirtualCNode.SubType) -> Array[Dictionary]:
	var arr: Array[Dictionary] = []

	if _type == HenVirtualCNode.SubType.VIRTUAL:
		for param: HenSaveParam in transition_data:
			if not param: continue
			
			arr.append(param.get_data())

	return arr


func get_flow_outputs(_type: HenVirtualCNode.SubType) -> Array[Dictionary]:
	var arr: Array[Dictionary] = []

	if _type == HenVirtualCNode.SubType.STATE:
		for flow_output: HenSaveParam in flow_outputs:
			arr.append({id = flow_output.id, name = flow_output.name})
	else:
		arr.append({id = 0})
	return arr


func get_cnode_data(_save_data_id: StringName, _from_another_script: bool = false) -> Dictionary:
	var router: HenRouter = Engine.get_singleton(&'Router')

	return {
		name = name,
		type = HenVirtualCNode.Type.STATE,
		sub_type = HenVirtualCNode.SubType.STATE if not _from_another_script else HenVirtualCNode.SubType.STATE,
		route = router.current_route,
		res_data = get_res_data(HenSideBar.AddType.STATE, _save_data_id)
	}


func get_transition_cnode_data(_save_data_id: StringName, _from_another_script: bool = false) -> Dictionary:
	var router: HenRouter = Engine.get_singleton(&'Router')
	
	return {
		name = name,
		sub_type = HenVirtualCNode.SubType.STATE_TRANSITION if not _from_another_script else HenVirtualCNode.SubType.STATE_TRANSITION_FROM,
		route = router.current_route,
		res_data = get_res_data(HenSideBar.AddType.STATE, _save_data_id)
	}


# hides the default resource section properties
func _validate_property(_property: Dictionary) -> void:
	super (_property)
	if _property.name in [&'is_sub_state']:
		_property.usage = PROPERTY_USAGE_STORAGE
