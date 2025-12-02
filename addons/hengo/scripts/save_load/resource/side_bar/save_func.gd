@tool
class_name HenSaveFunc extends HenSaveResTypeWithRoute

@export var inputs: Array[HenSaveParam]
@export var outputs: Array[HenSaveParam]
var input_ref: WeakRef
var output_ref: WeakRef


static func create() -> HenSaveFunc:
	var v: HenSaveFunc = HenSaveFunc.new()
	return v


func _init() -> void:
	id = (Engine.get_singleton(&'Global') as HenGlobal).get_new_node_counter()
	name = get_new_name()


func get_new_name() -> String:
	return 'function_' + str(id)


func get_data() -> Dictionary:
	var input_data: Array[Dictionary] = []
	var output_data: Array[Dictionary] = []
	var lvars: Array[Dictionary] = []
	var vc_list: Array[Dictionary] = []

	for param: HenSaveParam in inputs:
		input_data.append(param.get_data())

	for param: HenSaveParam in outputs:
		output_data.append(param.get_data())

	for lv: HenSaveParam in local_vars:
		lvars.append(lv.get_data())

	for cnode: Dictionary in virtual_cnode_list:
		vc_list.append(cnode)

	return {
		name = name,
		id = id,
		inputs = input_data,
		outputs = output_data,
		local_vars = lvars,
		virtual_cnode_list = vc_list,
	}


func get_inputs(_type: HenVirtualCNode.SubType) -> Array[Dictionary]:
	var arr: Array[Dictionary] = []

	for param: HenSaveParam in inputs:
		arr.append(param.get_data())

	return arr


func get_outputs(_type: HenVirtualCNode.SubType) -> Array[Dictionary]:
	var arr: Array[Dictionary] = []

	for param: HenSaveParam in outputs:
		arr.append(param.get_data())

	return arr


func get_cnode_data() -> Dictionary:
	var router: HenRouter = Engine.get_singleton(&'Router')

	return {
		name = name,
		sub_type = HenVirtualCNode.SubType.USER_FUNC,
		route = router.current_route,
		res = self,
	}
