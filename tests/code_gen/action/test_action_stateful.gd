extends HenActionTestSuite

# covers actions that declare state in the generated class: counters, signal
# connections and virtual overrides at script scope.

# --- action state -----------------------------------------------------------


# the counter lives in the state class and is zeroed on entry, so re-entering the
# state restarts the wait
func test_wait_declares_its_counter_and_resets_on_enter() -> void:
	HenScriptMacroLoader.load_native_actions()

	var target: HenSaveState = save_data.add_state(false)
	target.name = 'done state'

	var action: HenSaveAction = _add_action(HenActionsPanel.find_macro(&'wait'), &'update')
	action.branches['finished'] = {state_id = target.id, label = ''}

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('\tvar wait_' + str(action.id) + ': float = 0.0')
	assert_str(code).contains('func enter() -> void:\n\t\twait_' + str(action.id) + ' = 0.0')
	assert_str(code).contains('wait_' + str(action.id) + ' += delta')

	var script := GDScript.new()
	script.source_code = code

	assert_int(script.reload()).is_equal(OK)


# two waits in the same state get their own counter, or one would eat the other
func test_two_waits_do_not_share_a_counter() -> void:
	HenScriptMacroLoader.load_native_actions()

	var target: HenSaveState = save_data.add_state(false)
	target.name = 'done state'

	var macro: HenSaveMacro = HenActionsPanel.find_macro(&'wait')
	var first: HenSaveAction = _add_action(macro, &'update')
	var second: HenSaveAction = _add_action(macro, &'update')

	first.branches['finished'] = {state_id = target.id, label = ''}
	second.branches['finished'] = {state_id = target.id, label = ''}

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('var wait_' + str(first.id))
	assert_str(code).contains('var wait_' + str(second.id))

	var script := GDScript.new()
	script.source_code = code

	assert_int(script.reload()).is_equal(OK)


# a sub-state class is nested one level deeper, so every declaration line has to
# carry the extra indent — not just the first
func test_action_state_indents_inside_a_sub_state() -> void:
	HenScriptMacroLoader.load_native_actions()

	state.add_sub_state(save_data)
	var sub: HenSaveState = state.get_sub_states(save_data).get(0)
	sub.name = 'sub wait'

	var action: HenSaveAction = HenSaveAction.create(HenActionsPanel.find_macro(&'wait'))
	action.phase = &'update'
	action.branches['finished'] = {state_id = state.id, label = ''}
	save_data.add_state_action(sub.id, action)

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('\t\tvar wait_' + str(action.id) + ': float = 0.0')

	var script := GDScript.new()
	script.source_code = code

	assert_int(script.reload()).is_equal(OK)


# --- signal actions ---------------------------------------------------------


func _signal_action(_id: StringName, _target: HenSaveState, _emitter: String) -> HenSaveAction:
	var action: HenSaveAction = _add_action(HenActionsPanel.find_macro(_id), &'update')
	action.input_bindings['emitter'] = HenUtils.BIND_PATH_PREFIX + _emitter
	action.branches['received'] = {state_id = _target.id, label = ''}
	return action


# the connection is armed in enter and dropped in exit, both guarded: reconnecting
# on re-entry is an engine error, and the emitter may be gone by exit time
func test_signal_action_connects_on_enter_and_disconnects_on_exit() -> void:
	HenScriptMacroLoader.load_native_actions()

	var target: HenSaveState = save_data.add_state(false)
	target.name = 'hit state'

	var action: HenSaveAction = _signal_action(&'on_body_entered', target, 'Area2D')
	var code: String = HenTest.get_all_code()
	var id: String = str(action.id)

	assert_str(code).contains('emitter_' + id + ' = _ref.get_node("Area2D")')
	assert_str(code).contains("not emitter_" + id + ".is_connected('body_entered', _on_signal_" + id + ")")
	assert_str(code).contains("emitter_" + id + ".connect('body_entered', _on_signal_" + id + ")")

	# teardown lands in exit, right after the super() the base needs
	assert_str(code).contains('func exit() -> void:\n\t\tsuper()\n\t\tif is_instance_valid(emitter_' + id + ')')
	assert_str(code).contains(".disconnect('body_entered', _on_signal_" + id + ")")

	var script := GDScript.new()
	script.source_code = code

	assert_int(script.reload()).is_equal(OK)


# the store line lives in the phase body, the only path that substitutes inputs.
# the sweep never reaches it because it leaves optional slots empty
func test_signal_action_stores_the_argument_when_bound() -> void:
	HenScriptMacroLoader.load_native_actions()

	var body_var: HenSaveVar = save_data.add_var(false)
	body_var.name = 'ultimo corpo'
	body_var.type = 'Node2D'

	var target: HenSaveState = save_data.add_state(false)
	target.name = 'hit state'

	var action: HenSaveAction = _signal_action(&'on_body_entered', target, 'Area2D')
	action.input_bindings['store_arg'] = HenUtils.bind_code_for_var(body_var)

	var code: String = HenTest.get_all_code()
	var id: String = str(action.id)

	# no placeholder may survive into the script base
	assert_str(code).not_contains('{{')
	assert_str(code).contains('_ref.ultimo_corpo = value_' + id)
	assert_str(code).contains('_ref._STATE_CONTROLLER.change_state("hit_state")')

	var script := GDScript.new()
	script.source_code = code

	assert_int(script.reload()).is_equal(OK)


# leaving the optional slot empty drops the value instead of skipping the action
func test_signal_action_without_store_still_compiles() -> void:
	HenScriptMacroLoader.load_native_actions()

	var target: HenSaveState = save_data.add_state(false)
	target.name = 'hit state'

	var action: HenSaveAction = _signal_action(&'on_body_entered', target, 'Area2D')
	var code: String = HenTest.get_all_code()

	assert_str(code).not_contains('# hengo:')
	assert_str(code).not_contains(' = value_' + str(action.id))
	assert_str(code).contains('var value_' + str(action.id))


# two listeners in the same state need their own flag, emitter and value
func test_two_signal_actions_do_not_share_state() -> void:
	HenScriptMacroLoader.load_native_actions()

	var target: HenSaveState = save_data.add_state(false)
	target.name = 'hit state'

	var first: HenSaveAction = _signal_action(&'on_body_entered', target, 'Area2D')
	var second: HenSaveAction = _signal_action(&'on_body_exited', target, 'Area2D')

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('var fired_' + str(first.id))
	assert_str(code).contains('var fired_' + str(second.id))
	assert_str(code).contains('_on_signal_' + str(first.id))
	assert_str(code).contains('_on_signal_' + str(second.id))

	var script := GDScript.new()
	script.source_code = code

	assert_int(script.reload()).is_equal(OK)


# the generic action takes any signal, and refuses an empty name instead of
# emitting connect("", cb), which compiles and silently never fires
func test_generic_on_signal_takes_a_name_and_refuses_a_blank_one() -> void:
	HenScriptMacroLoader.load_native_actions()

	var target: HenSaveState = save_data.add_state(false)
	target.name = 'hit state'

	var action: HenSaveAction = _signal_action(&'on_signal', target, 'Timer')

	for param: HenSaveParam in action.inputs:
		if str(param.id) == 'signal_name':
			param.default_value = 'timeout'

	assert_str(HenTest.get_all_code()).contains(".connect('timeout', _on_signal_" + str(action.id) + ")")

	for param: HenSaveParam in action.inputs:
		if str(param.id) == 'signal_name':
			param.default_value = ''

	var blank: String = HenTest.get_all_code()

	assert_str(blank).contains('the signal name is empty')

	# a skipped action must leave NOTHING behind: the marker alone is a half-truth
	# while enter still runs connect('', cb) and exit the matching disconnect
	assert_str(blank).not_contains("connect('',")
	assert_str(blank).not_contains('_on_signal_' + str(action.id))
	assert_str(blank).not_contains('emitter_' + str(action.id))


# the `Sends` option drives the callback signature: godot refuses a callable that
# expects more arguments than the signal provides
func test_generic_on_signal_arity_follows_the_option() -> void:
	HenScriptMacroLoader.load_native_actions()

	var target: HenSaveState = save_data.add_state(false)
	target.name = 'hit state'

	var action: HenSaveAction = _signal_action(&'on_signal', target, 'Timer')

	for param: HenSaveParam in action.inputs:
		if str(param.id) == 'signal_name':
			param.default_value = 'timeout'

	assert_str(HenTest.get_all_code()).contains('func _on_signal_' + str(action.id) + '() -> void:')

	for param: HenSaveParam in action.inputs:
		if str(param.id) == 'args':
			param.default_value = 'one value'

	assert_str(HenTest.get_all_code()).contains('func _on_signal_' + str(action.id) + '(arg_' + str(action.id) + ') -> void:')


# the only test that proves the callback signature matches the signal: godot does
# not document the arity rule and GDScript.reload() never checks it. it also
# exercises the connect/disconnect for real
func test_signal_action_fires_at_runtime() -> void:
	HenScriptMacroLoader.load_native_actions()
	save_data.identity.type = 'Node2D'
	state.start = true

	# Variant on purpose: a var typed Node2D makes gen_variable emit Node2D.new()
	# as its default, which leaks an orphan node and is a separate known debt
	var body_var: HenSaveVar = save_data.add_var(false)
	body_var.name = 'ultimo corpo'
	body_var.type = 'Variant'

	var target: HenSaveState = save_data.add_state(false)
	target.name = 'hit state'

	var action: HenSaveAction = _signal_action(&'on_body_entered', target, 'Area2D')
	action.input_bindings['store_arg'] = HenUtils.bind_code_for_var(body_var)

	var script := GDScript.new()
	script.source_code = HenTest.get_all_code()

	assert_int(script.reload()).is_equal(OK)

	# freed by hand at the end: auto_free runs after the orphan check, and the
	# intruder never joins the tree
	var owner_node: Node2D = Node2D.new()
	var area: Area2D = Area2D.new()
	area.name = 'Area2D'
	owner_node.add_child(area)
	owner_node.set_script(script)
	add_child(owner_node)

	# _ready ran, so the start state is active and the signal is connected
	assert_bool(area.is_connected('body_entered', Callable(owner_node.get('_STATE_CONTROLLER').current_state, '_on_signal_' + str(action.id)))).is_true()

	var intruder: Node2D = Node2D.new()
	area.body_entered.emit(intruder)

	# the flag only becomes a transition on the next tick of the action's phase
	owner_node._process(0.016)

	assert_object(owner_node.get('ultimo_corpo')).is_same(intruder)
	assert_str(str(owner_node.get('_STATE_CONTROLLER')._last_debug_name)).is_equal('hit_state')

	owner_node.free()
	intruder.free()


# the owner itself is the emitter whenever the script sits on the node that has
# the signal — a Button script listening to its own `pressed`
func test_self_can_be_the_emitter() -> void:
	HenScriptMacroLoader.load_native_actions()
	save_data.identity.type = 'Button'

	var target: HenSaveState = save_data.add_state(false)
	target.name = 'clicked state'

	var action: HenSaveAction = _add_action(HenActionsPanel.find_macro(&'on_button_pressed'), &'update')
	action.input_bindings['emitter'] = '_ref'
	action.branches['received'] = {state_id = target.id, label = ''}

	var code: String = HenTest.get_all_code()
	var id: String = str(action.id)

	# _ref stands alone: prefixing it would emit _ref._ref
	assert_str(code).contains('emitter_' + id + ' = _ref\n')
	assert_str(code).not_contains('_ref._ref')
	assert_str(code).contains("emitter_" + id + ".connect('pressed', _on_signal_" + id + ")")

	assert_str(HenUtils.get_bind_label(save_data, '_ref')).is_equal('Self (this node)')

	var script := GDScript.new()
	script.source_code = code

	assert_int(script.reload()).is_equal(OK)


# Self must reach any node slot, and never a write target (`_ref = x`)
func test_self_is_offered_to_node_slots_only() -> void:
	HenScriptMacroLoader.load_native_actions()

	var inspector := HenInspector.new()
	var listener: HenSaveAction = _add_action(HenActionsPanel.find_macro(&'on_button_pressed'), &'update')
	var write: HenSaveAction = _add_action(HenActionsPanel.find_macro(&'set_value'), &'update')

	assert_array(_option_names(inspector, listener, 'emitter')).contains(['Self (this node)'])
	assert_array(_option_names(inspector, write, 'target')).not_contains(['Self (this node)'])

	inspector.free()


# --- script scope and virtual overrides -------------------------------------


func _look_action(_phase: StringName) -> HenSaveAction:
	save_data.identity.type = 'CharacterBody3D'
	var action: HenSaveAction = _add_action(HenActionsPanel.find_macro(&'mouse_look'), _phase)
	action.input_bindings['camera'] = HenUtils.BIND_PATH_PREFIX + 'Camera3D'
	return action


# _input runs on the node, so both the override and the variables it reads have to
# land at script scope — inside the state class they would be unreachable
func test_action_reaches_script_scope_and_virtuals() -> void:
	HenScriptMacroLoader.load_native_actions()

	var action: HenSaveAction = _look_action(&'physics')
	var code: String = HenTest.get_all_code()
	var id: String = str(action.id)

	var scope_at: int = code.find('var look_on_' + id)
	var class_at: int = code.find('class StateTest')

	assert_int(scope_at).is_greater(-1)
	assert_int(scope_at).is_less(class_at)

	# the override keeps its parameter, or the body would reference an unknown event
	assert_str(code).contains('func _input(event: InputEvent) -> void:\n\tif look_on_' + id)
	assert_int(code.find('func _input')).is_less(class_at)

	# the state class reaches script scope through _ref
	assert_str(code).contains('_ref.look_on_' + id + ' = true')
	assert_str(code).contains('_ref.look_on_' + id + ' = false')

	var script := GDScript.new()
	script.source_code = code

	assert_int(script.reload()).is_equal(OK)


# two actions overriding the same virtual share one func, they do not emit two
func test_two_actions_share_one_virtual_override() -> void:
	HenScriptMacroLoader.load_native_actions()

	var first: HenSaveAction = _look_action(&'physics')
	var second: HenSaveAction = _look_action(&'update')

	var code: String = HenTest.get_all_code()

	assert_int(code.count('func _input(')).is_equal(1)
	assert_str(code).contains('look_move_' + str(first.id) + ' += event.relative')
	assert_str(code).contains('look_move_' + str(second.id) + ' += event.relative')

	var script := GDScript.new()
	script.source_code = code

	assert_int(script.reload()).is_equal(OK)


# a skipped action must not leave an override or a declaration behind, the same
# rule the signal connect follows
func test_skipped_action_leaves_no_override() -> void:
	HenScriptMacroLoader.load_native_actions()

	var action: HenSaveAction = _look_action(&'physics')
	action.input_bindings.erase('camera')

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('must be bound to a variable or property')
	assert_str(code).not_contains('func _input')
	assert_str(code).not_contains('look_on_' + str(action.id))


# headless has no input and reload() proves nothing about behaviour: this drives a
# real InputEventMouseMotion through the generated script and checks that the look
# both works AND stops once the state is left
func test_mouse_look_arms_and_disarms_at_runtime() -> void:
	HenScriptMacroLoader.load_native_actions()
	state.start = true

	var idle: HenSaveState = save_data.add_state(false)
	idle.name = 'parked'

	var action: HenSaveAction = _look_action(&'physics')

	# leaving the state is what must switch the listener off
	var leave: HenSaveAction = _add_action(HenActionsPanel.find_macro(&'transition'), &'update')
	leave.branches['to'] = {state_id = idle.id, label = ''}

	var script := GDScript.new()
	script.source_code = HenTest.get_all_code()

	assert_int(script.reload()).is_equal(OK)

	var body: CharacterBody3D = CharacterBody3D.new()
	var cam: Camera3D = Camera3D.new()
	cam.name = 'Camera3D'
	body.add_child(cam)
	body.set_script(script)
	add_child(body)

	var motion := InputEventMouseMotion.new()
	motion.relative = Vector2(100, 40)

	body._input(motion)
	body._physics_process(0.016)

	var turned: float = body.rotation.y
	var pitched: float = cam.rotation.x

	assert_bool(is_zero_approx(turned)).override_failure_message('the body did not turn').is_false()
	assert_bool(is_zero_approx(pitched)).override_failure_message('the camera did not pitch').is_false()

	# now leave the state: update runs the transition, whose exit drops the listener
	body._process(0.016)

	body._input(motion)

	# checked on the accumulator, not on the rotation: the body stops running once
	# the state is left, so the rotation would freeze even with the listener still on
	assert_vector(body.get('look_move_' + str(action.id))) \
		.override_failure_message('_input kept accumulating after the state exited') \
		.is_equal(Vector2.ZERO)

	body._physics_process(0.016)

	assert_float(body.rotation.y).is_equal_approx(turned, 0.0001)
	assert_float(cam.rotation.x).is_equal_approx(pitched, 0.0001)

	body.free()


# --- check mouse button -----------------------------------------------------


func _mouse_action(_when: String, _target: HenSaveState) -> HenSaveAction:
	var action: HenSaveAction = _add_action(HenActionsPanel.find_macro(&'mouse_button'), &'update')
	action.branches['true'] = {state_id = _target.id, label = ''}

	for param: HenSaveParam in action.inputs:
		if str(param.id) == 'when':
			param.default_value = _when

	return action


# Held is a plain per-frame check: it must not drag an _input override along
func test_mouse_button_held_declares_nothing() -> void:
	HenScriptMacroLoader.load_native_actions()

	var target: HenSaveState = save_data.add_state(false)
	target.name = 'firing'

	_mouse_action('Held', target)

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):')
	assert_str(code).not_contains('func _input')
	assert_str(code).not_contains('click_on_')


# a moment needs the event, and a double click has to rule out the plain click
func test_mouse_button_double_click_uses_the_event() -> void:
	HenScriptMacroLoader.load_native_actions()

	var target: HenSaveState = save_data.add_state(false)
	target.name = 'firing'

	var action: HenSaveAction = _mouse_action('Double Click', target)
	var code: String = HenTest.get_all_code()
	var id: String = str(action.id)

	assert_str(code).contains('func _input(event: InputEvent) -> void:')
	assert_str(code).contains('event.pressed and event.double_click')
	assert_str(code).contains('_ref.click_on_' + id + ' = true')
	assert_str(code).contains('_ref.click_on_' + id + ' = false')
	assert_str(code).not_contains('Input.is_mouse_button_pressed')

	var script := GDScript.new()
	script.source_code = code

	assert_int(script.reload()).is_equal(OK)


# renaming the display name must reach an action saved under the old one
func test_renamed_macro_shows_the_new_name() -> void:
	HenScriptMacroLoader.load_native_actions()

	var action: HenSaveAction = _add_action(HenActionsPanel.find_macro(&'mouse_button'), &'update')
	action.name = 'Mouse Button'

	assert_str(HenActionsPanel.display_name(action)).is_equal('Check Mouse Button')


# nothing else can reach this: headless has no input and reload() only proves the
# code parses. drives real mouse events through the generated script
func test_double_click_fires_only_on_a_double_click() -> void:
	HenScriptMacroLoader.load_native_actions()
	save_data.identity.type = 'Node2D'
	state.start = true

	var target: HenSaveState = save_data.add_state(false)
	target.name = 'firing'

	var action: HenSaveAction = _mouse_action('Double Click', target)

	var script := GDScript.new()
	script.source_code = HenTest.get_all_code()

	assert_int(script.reload()).is_equal(OK)

	var node: Node2D = Node2D.new()
	node.set_script(script)
	add_child(node)

	var single := InputEventMouseButton.new()
	single.button_index = MOUSE_BUTTON_LEFT
	single.pressed = true

	node._input(single)
	node._process(0.016)

	assert_str(str(node.get('_STATE_CONTROLLER')._last_debug_name)) \
		.override_failure_message('a single click fired the double click branch') \
		.is_equal('state_test')

	var double := InputEventMouseButton.new()
	double.button_index = MOUSE_BUTTON_LEFT
	double.pressed = true
	double.double_click = true

	node._input(double)
	node._process(0.016)

	assert_str(str(node.get('_STATE_CONTROLLER')._last_debug_name)).is_equal('firing')

	# the state changed, so the listener was disarmed on the way out
	node._input(double)

	assert_bool(bool(node.get('click_on_' + str(action.id)))) \
		.override_failure_message('_input kept listening after the state exited') \
		.is_false()

	node.free()
