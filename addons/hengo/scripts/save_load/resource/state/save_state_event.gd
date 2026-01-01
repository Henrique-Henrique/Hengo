@tool
class_name HenSaveStateEvent extends HenSaveResType

func get_new_name() -> String:
	return 'event_' + str(id)


static func create() -> HenSaveStateEvent:
	var v: HenSaveStateEvent = HenSaveStateEvent.new()
	return v


func _init() -> void:
	id = (Engine.get_singleton(&'Global') as HenGlobal).get_new_node_counter()
	name = get_new_name()


func get_flow_outputs(_type: HenVirtualCNode.SubType) -> Array[Dictionary]:
	if _type == HenVirtualCNode.SubType.STATE_EVENT_TRANSITION:
		return []

	return [ {id = 0}]


func get_cnode_data() -> Dictionary:
	var router: HenRouter = Engine.get_singleton(&'Router')

	return {
		name = name,
		sub_type = HenVirtualCNode.SubType.STATE_EVENT,
		route = router.current_route,
		res_data = get_res_data(HenSideBar.AddType.STATE_EVENT)
	}


func get_event_transition_cnode_data(_save_data_id: StringName, _from_another_script: bool = false) -> Dictionary:
	var router: HenRouter = Engine.get_singleton(&'Router')

	return {
		name = name,
		type = HenVirtualCNode.Type.STATE_EVENT_TRANSITION,
		sub_type = HenVirtualCNode.SubType.STATE_EVENT_TRANSITION if not _from_another_script else HenVirtualCNode.SubType.STATE_EVENT_TRANSITION_FROM,
		route = router.current_route,
		res_data = get_res_data(HenSideBar.AddType.STATE_EVENT, _save_data_id)
	}