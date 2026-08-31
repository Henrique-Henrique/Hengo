@tool
class_name HenSaveStateMacro extends HenSaveResTypeWithRoute

# a state machine kept in a drawer instead of in the tree: its states live in
# save_data.sub_states under this id, and every use of it is a state carrying
# macro_id. the branches inside it reach its own states plus the named exits,
# which each use wires to a state of the script

# script variable each use of a macro parks its input values in, since a nested
# state class cannot read the class holding it
const INPUT_VAR_PREFIX: String = '_mc_'

@export var inputs: Array[HenSaveParam]
# named places the machine of the macro leaves for each use to fill in, run by a
# "Run <name>" step inside it
@export var flow_inputs: Array[HenSaveFlowParam]
@export var flow_outputs: Array[HenSaveFlowParam]
@export_multiline var description: String = ''


static func create(_owner: HenSaveData = null) -> HenSaveStateMacro:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var macro: HenSaveStateMacro = HenSaveStateMacro.new()

	macro.id = _owner.new_counter_id() if _owner else global.get_new_node_counter()
	macro.name = macro.get_new_name()

	return macro


func get_new_name() -> String:
	return 'macro_' + str(id)


func get_states(_save_data: HenSaveData) -> Array:
	if not _save_data or not _save_data.sub_states.has(id):
		return []

	return _save_data.sub_states.get(id)


func add_state(_save_data: HenSaveData) -> HenSaveState:
	var state: HenSaveState = HenSaveState.create(true, _save_data)

	if not _save_data.sub_states.has(id):
		_save_data.sub_states.set(id, [])

	var states: Array = _save_data.sub_states.get(id)

	states.append(state)

	# the flag is set after the append: its setter sweeps the siblings by looking
	# for the list holding this state
	if states.size() == 1:
		state.start = true

	return state


func get_start_state(_save_data: HenSaveData) -> HenSaveState:
	var states: Array = get_states(_save_data)

	for state: HenSaveState in states:
		if state.start:
			return state

	return states[0] if not states.is_empty() else null


func get_new_input() -> HenSaveParam:
	var param: HenSaveParam = HenSaveParam.create({name = 'input_' + str(inputs.size() + 1), type = &'Variant'})

	inputs.append(param)

	return param


func get_new_flow_output() -> HenSaveFlowParam:
	var flow: HenSaveFlowParam = HenSaveFlowParam.create({name = 'exit_' + str(flow_outputs.size() + 1)})

	flow_outputs.append(flow)

	return flow


func get_new_flow_input() -> HenSaveFlowParam:
	var flow: HenSaveFlowParam = HenSaveFlowParam.create({name = 'step_' + str(flow_inputs.size() + 1)})

	flow_inputs.append(flow)

	return flow


func find_flow_input(_id: StringName) -> HenSaveFlowParam:
	for flow: HenSaveFlowParam in flow_inputs:
		if str(flow.id) == str(_id):
			return flow

	return null
