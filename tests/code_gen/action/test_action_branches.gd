extends HenActionTestSuite

# covers where an action sends the flow: branches, the transition action,
# cross-script targets and sub-state navigation.

const FIX_BRANCH: String = 'res://addons/hengo/actions/flow/if_condition.gd'


# --- branches ---------------------------------------------------------------


func _if_action(_phase: StringName) -> HenSaveAction:
	var action: HenSaveAction = _add_action(_register(FIX_BRANCH), _phase)
	action.input_bindings['condition'] = 'is_dead'
	return action


func test_branch_to_sibling_state() -> void:
	var dead: HenSaveState = save_data.add_state(false)
	dead.name = 'dead'

	var action: HenSaveAction = _if_action(&'update')
	action.branches['true'] = {state_id = dead.id, label = 'morreu'}

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('if _ref.is_dead:\n\t\t\t_ref._STATE_CONTROLLER.change_state("dead")\n\t\telse:\n\t\t\tpass')


# a child of the owning state goes through the parent, not the controller
func test_branch_to_sub_state() -> void:
	state.add_sub_state(save_data)
	var child: HenSaveState = state.get_sub_states(save_data).get(0)
	child.name = 'child state'

	var action: HenSaveAction = _if_action(&'update')
	action.branches['false'] = {state_id = child.id, label = ''}

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('_ref._STATE_CONTROLLER.current_state.change_sub_state("child_state")')


func test_branch_both_sides() -> void:
	var dead: HenSaveState = save_data.add_state(false)
	dead.name = 'dead'
	var idle: HenSaveState = save_data.add_state(false)
	idle.name = 'idle'

	var action: HenSaveAction = _if_action(&'update')
	action.branches['true'] = {state_id = dead.id, label = 'morreu'}
	action.branches['false'] = {state_id = idle.id, label = ''}

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('_ref._STATE_CONTROLLER.change_state("dead")')
	assert_str(code).contains('_ref._STATE_CONTROLLER.change_state("idle")')


# a target deleted after being bound must not emit a dangling call
func test_branch_with_stale_target_falls_back_to_pass() -> void:
	var action: HenSaveAction = _if_action(&'update')
	action.branches['true'] = {state_id = &'9999', label = ''}

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('no branch target set')


# an if that goes nowhere is a misconfiguration, not an empty block
func test_branch_without_any_target_emits_marker() -> void:
	_if_action(&'update')

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('no branch target set')


# steps are somewhere to go on a required branch too, not only on an optional one
func test_branch_with_only_steps_is_not_skipped() -> void:
	var action: HenSaveAction = _if_action(&'update')
	action.branch_actions['true'] = [HenSaveAction.create(_register(FIX_PHASES))] as Array[HenSaveAction]

	var code: String = HenTest.get_all_code()

	assert_str(code).not_contains('no branch target set')
	assert_str(code).contains('if _ref.is_dead:\n\t\t\ttest_update("hi")\n\t\telse:\n\t\t\tpass')


# the row preview shows where each configured branch goes
func test_branch_shows_in_row_preview() -> void:
	var dead: HenSaveState = save_data.add_state(false)
	dead.name = 'dead'

	var macro: HenSaveMacro = _register(FIX_BRANCH)
	var action: HenSaveAction = HenSaveAction.create(macro)
	save_data.add_state_action(state.id, action)
	action.branches['true'] = {state_id = dead.id, label = 'morreu'}

	var parts: Array[Dictionary] = HenActionsPanel.branch_parts(action, macro)

	assert_int(parts.size()).is_equal(1)
	assert_str(str(parts[0].kind)).is_equal('branch')
	assert_str(str(parts[0].value)).is_equal('-> dead')


# change_state runs exit() before swapping current_state, so transitioning from
# exit would re-enter it forever: the phase must be refused, not generated
func test_branch_is_refused_on_exit() -> void:
	var dead: HenSaveState = save_data.add_state(false)
	dead.name = 'dead'

	var macro: HenSaveMacro = _register(FIX_BRANCH)
	var action: HenSaveAction = _add_action(macro, &'exit')
	action.branches['true'] = {state_id = dead.id, label = ''}

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('cannot run on exit')
	assert_str(code).not_contains('func exit() -> void:\n\t\tsuper()\n\t\tif')

	# and the inspector must not offer the phase in the first place
	assert_bool(HenSaveAction.supported_phases(macro).has(&'exit')).is_false()
	assert_bool(HenSaveAction.supported_phases(macro).has(&'enter')).is_true()


# string asserts pin the indentation, but only a real compile proves the block is valid
func test_branch_code_compiles() -> void:
	var dead: HenSaveState = save_data.add_state(false)
	dead.name = 'dead'

	var action: HenSaveAction = _if_action(&'update')
	action.branches['true'] = {state_id = dead.id, label = ''}

	var script := GDScript.new()
	script.source_code = HenTest.get_all_code()

	assert_int(script.reload()).is_equal(OK)


# the custom branch name is what labels the arrow in the state viewer
func test_branch_feeds_state_viewer_edges() -> void:
	var dead: HenSaveState = save_data.add_state(false)
	dead.name = 'dead'
	var idle: HenSaveState = save_data.add_state(false)
	idle.name = 'idle'

	var action: HenSaveAction = _if_action(&'update')
	action.branches['true'] = {state_id = dead.id, label = 'colidiu com player'}
	action.branches['false'] = {state_id = idle.id, label = ''}

	# the edges come from save_data alone, with no view involved
	var on_dict: Dictionary = {}
	HenStateGraphSource.add_branch_edges(state, save_data, on_dict, {})

	assert_str(str(on_dict.get('colidiu com player', ''))).is_equal('dead')
	# no custom name falls back to the same shape the transition nodes use
	assert_str(str(on_dict.get('go_to_idle', ''))).is_equal('idle')


# --- transition action ------------------------------------------------------


func test_transition_goes_to_a_state() -> void:
	var dead: HenSaveState = save_data.add_state(false)
	dead.name = 'dead'

	var action: HenSaveAction = _add_action(_register(FIX_TRANSITION), &'update')
	action.branches['to'] = {state_id = dead.id, label = ''}

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('func update(delta) -> void:\n\t\tsuper(delta)\n\t\t_ref._STATE_CONTROLLER.change_state("dead")')


func test_transition_goes_to_a_sub_state() -> void:
	state.add_sub_state(save_data)
	var child: HenSaveState = state.get_sub_states(save_data).get(0)
	child.name = 'child state'

	var action: HenSaveAction = _add_action(_register(FIX_TRANSITION), &'update')
	action.branches['to'] = {state_id = child.id, label = ''}

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('_ref._STATE_CONTROLLER.current_state.change_sub_state("child_state")')


# the bound instance is the prefix, so the other node's machine is the one driven
func test_transition_goes_to_another_script_state() -> void:
	var other: Dictionary = _other_script('hurt')

	var action: HenSaveAction = _add_action(_register(FIX_TRANSITION), &'update')
	action.branches['to'] = {
		state_id = other.state.id,
		script_id = other.save_data.identity.id,
		instance_bind = 'target_player',
		label = ''
	}

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('_ref.target_player._STATE_CONTROLLER.change_state("hurt")')


# without the instance there is nothing to call change_state on
func test_cross_script_branch_without_instance_emits_marker() -> void:
	var other: Dictionary = _other_script('hurt')

	var action: HenSaveAction = _add_action(_register(FIX_TRANSITION), &'update')
	action.branches['to'] = {
		state_id = other.state.id,
		script_id = other.save_data.identity.id,
		label = ''
	}

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('missing target instance connection')
	assert_str(code).not_contains('change_state("hurt")')


# any branching action takes cross-script targets, not just the transition
func test_if_branch_goes_to_another_script_state() -> void:
	var other: Dictionary = _other_script('dead')

	var action: HenSaveAction = _if_action(&'update')
	action.branches['true'] = {
		state_id = other.state.id,
		script_id = other.save_data.identity.id,
		instance_bind = 'target_player',
		label = ''
	}

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('if _ref.is_dead:\n\t\t\t_ref.target_player._STATE_CONTROLLER.change_state("dead")')


# it transitions on its own, so it may never run on exit
func test_transition_phases() -> void:
	var macro: HenSaveMacro = _register(FIX_TRANSITION)

	assert_array(HenSaveAction.supported_phases(macro)).is_equal([&'enter', &'update', &'physics'])
	assert_str(str(HenSaveAction.default_phase(macro))).is_equal('update')


# --- instance source --------------------------------------------------------


# a node path keeps no reference around: it resolves at the call site
func test_instance_from_node_path() -> void:
	var other: Dictionary = _other_script('hurt')

	var action: HenSaveAction = _add_action(_register(FIX_TRANSITION), &'update')
	action.branches['to'] = _cross_branch('to', other, {instance_path = '%Player'})

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('_ref.get_node("%Player")._STATE_CONTROLLER.change_state("hurt")')


func test_instance_check_guards_a_bound_variable() -> void:
	var other: Dictionary = _other_script('hurt')

	var action: HenSaveAction = _add_action(_register(FIX_TRANSITION), &'update')
	action.branches['to'] = _cross_branch('to', other, {instance_bind = 'target_player', check_instance = true})

	var code: String = HenTest.get_all_code()
	var temp: String = '__hg_' + str(action.id) + '_to'

	assert_str(code).contains('var ' + temp + ' = _ref.target_player')
	assert_str(code).contains('if is_instance_valid(' + temp + ') and "_STATE_CONTROLLER" in ' + temp + ':')
	assert_str(code).contains('\t' + temp + '._STATE_CONTROLLER.change_state("hurt")')


# the instance is bound by id as well, so a rename can't break the transition
func test_instance_binding_follows_variable_rename() -> void:
	var other: Dictionary = _other_script('hurt')
	var target: HenSaveVar = save_data.add_var(false)
	target.name = 'target_player'
	target.type = 'Node2D'

	var action: HenSaveAction = _add_action(_register(FIX_TRANSITION), &'update')
	action.branches['to'] = _cross_branch('to', other, {instance_bind = HenUtils.bind_code_for_var(target)})

	target.name = 'enemy ref'

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('_ref.enemy_ref._STATE_CONTROLLER.change_state("hurt")')


# a deleted instance variable leaves the branch with no receiver
func test_instance_binding_to_deleted_variable_emits_marker() -> void:
	var other: Dictionary = _other_script('hurt')
	var target: HenSaveVar = save_data.add_var(false)
	target.name = 'target_player'
	target.type = 'Node2D'

	var action: HenSaveAction = _add_action(_register(FIX_TRANSITION), &'update')
	action.branches['to'] = _cross_branch('to', other, {instance_bind = HenUtils.bind_code_for_var(target)})

	save_data.variables.erase(target)

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('missing target instance connection')
	assert_str(code).not_contains('change_state("hurt")')


# the guarded path resolves once into the temp, and a missing node must not push an error
func test_instance_check_uses_get_node_or_null() -> void:
	var other: Dictionary = _other_script('hurt')

	var action: HenSaveAction = _add_action(_register(FIX_TRANSITION), &'update')
	action.branches['to'] = _cross_branch('to', other, {instance_path = '%Player', check_instance = true})

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('var __hg_' + str(action.id) + '_to = _ref.get_node_or_null("%Player")')
	assert_int(code.count('get_node_or_null')).is_equal(1)


# string asserts pin the tabs, only a compile proves the guard block nests right
func test_guarded_branch_inside_if_compiles() -> void:
	var other: Dictionary = _other_script('dead')

	var action: HenSaveAction = _if_action(&'update')
	action.branches['true'] = _cross_branch('true', other, {instance_path = '%Player', check_instance = true})

	var script := GDScript.new()
	script.source_code = HenTest.get_all_code()

	assert_int(script.reload()).is_equal(OK)


# an empty path is as unset as no source at all
func test_empty_node_path_emits_marker() -> void:
	var other: Dictionary = _other_script('hurt')

	var action: HenSaveAction = _add_action(_register(FIX_TRANSITION), &'update')
	action.branches['to'] = _cross_branch('to', other, {instance_path = ''})

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('missing target instance connection')


# the new branch keys must survive ResourceSaver like state_id/script_id do
func test_instance_source_round_trips() -> void:
	var other: Dictionary = _other_script('hurt')

	var action: HenSaveAction = _add_action(_register(FIX_TRANSITION), &'update')
	action.branches['to'] = _cross_branch('to', other, {instance_path = '%Player', check_instance = true})

	var path: String = 'user://test_action_branch.res'
	assert_int(ResourceSaver.save(action, path)).is_equal(OK)

	var loaded: HenSaveAction = ResourceLoader.load(path, '', ResourceLoader.CACHE_MODE_IGNORE_DEEP) as HenSaveAction
	var branch: Dictionary = loaded.branches['to']

	assert_str(str(branch.get('instance_path', ''))).is_equal('%Player')
	assert_bool(bool(branch.get('check_instance', false))).is_true()

	DirAccess.remove_absolute(path)


# a var holds the target when either type inherits the other; only siblings fail
func test_can_hold_instance_of_matrix() -> void:
	assert_bool(HenUtils.can_hold_instance_of(&'CharacterBody2D', &'CharacterBody2D')).is_true()
	assert_bool(HenUtils.can_hold_instance_of(&'Node2D', &'CharacterBody2D')).is_true()
	assert_bool(HenUtils.can_hold_instance_of(&'Node', &'CharacterBody2D')).is_true()

	# a script extending Node can be attached to a Sprite2D, so that var is valid
	assert_bool(HenUtils.can_hold_instance_of(&'Sprite2D', &'Node')).is_true()

	# sibling branches can never point at the same node
	assert_bool(HenUtils.can_hold_instance_of(&'Sprite2D', &'CharacterBody2D')).is_false()
	assert_bool(HenUtils.can_hold_instance_of(&'RigidBody2D', &'CharacterBody2D')).is_false()
	assert_bool(HenUtils.can_hold_instance_of(&'Control', &'Node2D')).is_false()
	assert_bool(HenUtils.can_hold_instance_of(&'int', &'CharacterBody2D')).is_false()

	# an unknown target class must not empty the picker
	assert_bool(HenUtils.can_hold_instance_of(&'Variant', &'MyCustomBase')).is_true()

	# every new variable is born Variant — dropping those would read as a bug
	assert_bool(HenUtils.can_hold_instance_of(&'Variant', &'CharacterBody2D')).is_true()


# --- sub-state transitions and go back --------------------------------------


func _sub_state(_parent: HenSaveState, _name: String) -> HenSaveState:
	_parent.add_sub_state(save_data)
	var subs: Array = _parent.get_sub_states(save_data)
	var sub: HenSaveState = subs[subs.size() - 1]
	sub.name = _name
	return sub


# a sub-state changing to a SIBLING has to go through the parent: emitting
# change_state would look the name up in the top level dict and print "not found"
func test_sub_state_transitions_to_a_sibling() -> void:
	HenScriptMacroLoader.load_native_actions()

	var ready: HenSaveState = _sub_state(state, 'ready state')
	var busy: HenSaveState = _sub_state(state, 'busy state')

	var action: HenSaveAction = HenSaveAction.create(HenActionsPanel.find_macro(&'transition'))
	action.phase = &'update'
	action.branches['to'] = {state_id = ready.id, label = ''}
	save_data.add_state_action(busy.id, action)

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('_ref._STATE_CONTROLLER.current_state.change_sub_state("ready_state")')
	assert_str(code).not_contains('_STATE_CONTROLLER.change_state("ready_state")')

	var script := GDScript.new()
	script.source_code = code

	assert_int(script.reload()).is_equal(OK)


# a sub-state of a state that is not running cannot be reached, and saying so is
# better than emitting a change_state that fails at runtime
func test_branch_to_an_unreachable_sub_state_is_refused() -> void:
	HenScriptMacroLoader.load_native_actions()

	var other: HenSaveState = save_data.add_state(false)
	other.name = 'other top'

	# the first sub-state is the machine's start, and entering it emits a
	# change_sub_state of its own: the branch under test needs a name of its own
	_sub_state(other, 'entry point')

	var stranger: HenSaveState = _sub_state(other, 'stranger')

	var action: HenSaveAction = _add_action(HenActionsPanel.find_macro(&'transition'), &'update')
	action.branches['to'] = {state_id = stranger.id, label = ''}

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('points at a sub-state of another state')
	assert_str(code).not_contains('change_sub_state("stranger")')


# Go Back needs no target: the state asks whoever handed control to it
func test_go_back_emits_a_targetless_return() -> void:
	HenScriptMacroLoader.load_native_actions()

	var sub: HenSaveState = _sub_state(state, 'quick state')

	var action: HenSaveAction = HenSaveAction.create(HenActionsPanel.find_macro(&'go_back'))
	action.phase = &'enter'
	save_data.add_state_action(sub.id, action)

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('go_back()')

	var script := GDScript.new()
	script.source_code = code

	assert_int(script.reload()).is_equal(OK)


# --- a state entering its own start sub-state -------------------------------


# through the controller this reads current_state, the TOP level state, so a
# sub-state holding sub-states of its own handed the name to its ancestor and
# change_sub_state found nothing and returned in silence
func test_a_nested_state_enters_its_own_start_sub_state() -> void:
	var moving: HenSaveState = _sub_state(state, 'moving')
	var blink: HenSaveState = _sub_state(moving, 'blink')

	blink.start = true

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('change_sub_state("blink")')
	assert_str(code).not_contains('_ref._STATE_CONTROLLER.current_state.change_sub_state("blink")')

	var script: GDScript = GDScript.new()

	script.source_code = code

	assert_int(script.reload()).is_equal(OK)
