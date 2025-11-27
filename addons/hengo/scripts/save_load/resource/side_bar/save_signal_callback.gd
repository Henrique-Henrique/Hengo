@tool
class_name HenSaveSignalCallback extends HenSaveResTypeWithRoute

@export var params: Array[HenSaveParam]
@export var bind_params: Array[HenSaveParam]
@export var type: StringName
@export var signal_name: StringName
@export var signal_name_to_code: StringName

var signal_enter: HenVirtualCNode

static func create() -> HenSaveSignalCallback:
	var v: HenSaveSignalCallback = HenSaveSignalCallback.new()
	v.id = (Engine.get_singleton(&'Global') as HenGlobal).get_new_node_counter()
	v.type = &'Variant'
	return v


func get_inputs(_type: HenVirtualCNode.SubType) -> Array[Dictionary]:
	match _type:
		HenVirtualCNode.SubType.SIGNAL_CONNECTION:
			var arr: Array[Dictionary] = [
				{
					name = type,
					type = type,
					is_ref = true
				}
			]

			for param: HenSaveParam in bind_params:
				arr.append(param.get_data())
			
			return arr
		HenVirtualCNode.SubType.SIGNAL_DISCONNECTION:
			return [ {name = type, type = type, is_ref = true}]

	return []


func get_outputs(_type: HenVirtualCNode.SubType) -> Array[Dictionary]:
	return []


func get_connect_cnode_data() -> Dictionary:
	var router: HenRouter = Engine.get_singleton(&'Router')

	return {
		name = name,
		fantasy_name = 'Signal -> ' + name,
		sub_type = HenVirtualCNode.SubType.SIGNAL_CONNECTION,
		route = router.current_route,
		res = self
	}


func get_diconnect_cnode_data() -> Dictionary:
	var router: HenRouter = Engine.get_singleton(&'Router')

	return {
			name = name,
			fantasy_name = 'Dis Signal -> ' + name,
			sub_type = HenVirtualCNode.SubType.SIGNAL_DISCONNECTION,
			route = router.current_route,
			res = self
	}