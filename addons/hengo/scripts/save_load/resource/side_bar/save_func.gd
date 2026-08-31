@tool
class_name HenSaveFunc extends HenSaveResTypeWithRoute

# a reusable list of actions with its own inputs, outputs and branches. the body
# lives in save_data.state_actions under this id, the drawer a state uses too

@export var inputs: Array[HenSaveParam]
@export var outputs: Array[HenSaveParam]
@export var flow_outputs: Array[HenSaveFlowParam]
@export_multiline var description: String = ''

var _scope: HenSaveState


static func create(_owner: HenSaveData = null) -> HenSaveFunc:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var f: HenSaveFunc = HenSaveFunc.new()

	f.id = _owner.new_counter_id() if _owner else global.get_new_node_counter()
	f.name = f.get_new_name()

	return f


func get_new_name() -> String:
	return 'function_' + str(id)


# the method the codegen emits for this function
func method_name() -> String:
	return 'fn_' + name.to_snake_case()


# the body of a function is an action list like a state's, so the graph, the card
# editor and the emit path read it through a state that only exists in memory
func scope_state() -> HenSaveState:
	if not _scope:
		_scope = HenSaveState.new()
		_scope.id = id
		_scope.is_function_scope = true

	_scope.name = name

	return _scope


func get_new_input() -> HenSaveParam:
	var param: HenSaveParam = HenSaveParam.create({name = 'input_' + str(inputs.size() + 1), type = &'Variant'})

	inputs.append(param)

	return param


func get_new_output() -> HenSaveParam:
	var param: HenSaveParam = HenSaveParam.create({name = 'output_' + str(outputs.size() + 1), type = &'Variant'})

	outputs.append(param)

	return param


func get_new_flow_output() -> HenSaveFlowParam:
	var flow: HenSaveFlowParam = HenSaveFlowParam.create({name = 'branch_' + str(flow_outputs.size() + 1)})

	flow_outputs.append(flow)

	return flow
