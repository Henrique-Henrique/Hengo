@tool
class_name HenSaveSignal extends HenSaveResType

@export var inputs: Array[HenSaveParam]

static func create() -> HenSaveSignal:
	var v: HenSaveSignal = HenSaveSignal.new()
	return v


func _init() -> void:
	id = (Engine.get_singleton(&'Global') as HenGlobal).get_new_node_counter()
	name = get_new_name()


func get_new_name() -> String:
	return 'signal_' + str(id)


func get_data() -> Dictionary:
	var input_data: Array[Dictionary] = []

	for param: HenSaveParam in inputs:
		input_data.append(param.get_data())

	return {
		name = name,
		id = id,
		inputs = input_data,
	}


func get_inputs(_type: HenVirtualCNode.SubType) -> Array[Dictionary]:
	var arr: Array[Dictionary] = []

	for param: HenSaveParam in inputs:
		arr.append(param.get_data())

	return arr


func get_outputs(_type: HenVirtualCNode.SubType) -> Array[Dictionary]:
	return []