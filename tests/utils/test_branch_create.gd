@tool
class_name TestHenBranchCreate extends HenTestSuite

# creating the target of a transition from the branch row itself, instead of
# going to the sidebar and losing the row that asked


const FIX_TRANSITION: String = 'res://addons/hengo/actions/flow/transition.gd'

var state: HenSaveState


func before_test() -> void:
	super ()
	state = save_data.add_state(false)
	state.name = 'Play'


func _action(_state: HenSaveState) -> HenSaveAction:
	var instance: HenScriptMacroBase = (load(FIX_TRANSITION) as GDScript).new()
	var macro: HenSaveMacro = HenSaveMacro.new()

	macro.id = instance.get_id()
	macro.name = 'transition'
	macro.is_script_macro = true
	macro.script_path = FIX_TRANSITION

	for flow: Dictionary in instance.get_flow_outputs():
		macro.flow_outputs.append(HenSaveFlowParam.create(flow))

	(Engine.get_singleton(&'Global') as HenGlobal).action_macros.append(macro)

	var action: HenSaveAction = HenSaveAction.create(macro)
	save_data.add_state_action(_state.id, action)

	return action


func _inspector(_action: HenSaveAction) -> HenInspector:
	var inspector: HenInspector = auto_free(
		(load('res://addons/hengo/scenes/custom_inspector.tscn') as PackedScene).instantiate()
	)

	add_child(inspector)
	inspector.edit(_action, 'Transition', [])

	return inspector


# the owner used to be a stub returning null, so nothing could tell which machine
# an action ran in
func test_the_owner_state_of_an_action_is_found() -> void:
	var inspector: HenInspector = _inspector(_action(state))

	assert_object(inspector._owner_state(save_data)).is_same(state)


func test_a_nested_action_still_reports_the_state_that_holds_it() -> void:
	var host: HenSaveAction = _action(state)
	var inner: HenSaveAction = _action(state)

	save_data.remove_state_action(state.id, inner)
	host.body_actions.append(inner)

	var inspector: HenInspector = _inspector(inner)

	assert_object(inspector._owner_state(save_data)).is_same(state)


func test_creating_a_target_points_the_branch_at_it() -> void:
	var action: HenSaveAction = _action(state)
	var inspector: HenInspector = _inspector(action)
	var before: int = save_data.states.size()

	inspector._create_branch_target('to', null, false)

	assert_int(save_data.states.size()).is_equal(before + 1)

	var created: HenSaveState = save_data.states[-1]

	assert_str(str((action.branches.to as Dictionary).state_id)).is_equal(str(created.id))
	assert_object(HenGeneratorAction.branch_target(save_data, action, 'to')).is_same(created)


# picked from the row of an action that runs in a sub-state: the new one joins the
# machine the owner is in, not the machine the owner owns
func test_a_sibling_target_lands_next_to_the_state_the_action_runs_in() -> void:
	var child: HenSaveState = state.add_sub_state(save_data)
	var action: HenSaveAction = _action(child)
	var inspector: HenInspector = _inspector(action)

	assert_object(HenStateOps.parent_of(save_data, child)).is_same(state)

	inspector._create_branch_target('to', state)

	var subs: Array = state.get_sub_states(save_data)
	var created: HenSaveState = subs[-1]

	assert_int(subs.size()).is_equal(2)
	assert_bool(created.is_sub_state).is_true()
	assert_object(HenGeneratorAction.branch_target(save_data, action, 'to')).is_same(created)


# the first sub-state of a machine is its start, and a second one must not take it
func test_a_created_sibling_does_not_steal_the_start() -> void:
	var child: HenSaveState = state.add_sub_state(save_data)
	var inspector: HenInspector = _inspector(_action(child))

	inspector._create_branch_target('to', state)

	var subs: Array = state.get_sub_states(save_data)

	assert_bool((subs[0] as HenSaveState).start).is_true()
	assert_bool((subs[1] as HenSaveState).start).is_false()


func test_add_sub_state_hands_back_what_it_created() -> void:
	var created: HenSaveState = state.add_sub_state(save_data)

	assert_object(created).is_not_null()
	assert_array(state.get_sub_states(save_data)).contains([created])


# the ancestor chain block of the picker never ran while _owner_state was a stub:
# an action inside a sub-state can now target the machines it runs under
func test_the_picker_lists_the_sub_states_of_the_owner_chain() -> void:
	var sibling: HenSaveState = state.add_sub_state(save_data)
	var child: HenSaveState = state.add_sub_state(save_data)

	sibling.name = 'Recover'

	var inspector: HenInspector = _inspector(_action(child))
	var names: Array = inspector._build_branch_options().map(func(o: Dictionary) -> String: return str(o.name))

	assert_array(names).contains(['Nowhere', state.name, state.name + ' / ' + sibling.name])
	assert_array(names).not_contains([state.name + ' / ' + child.name])
