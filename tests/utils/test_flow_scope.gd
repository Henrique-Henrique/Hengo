@tool
class_name TestHenFlowScope extends HenTestSuite

# the canvas draws one scope at a time: this covers going into a definition, being
# sent back by a state of the script, and going into one again


var state: HenSaveState
var func_res: HenSaveFunc
var macro: HenSaveStateMacro


func before_test() -> void:
	super ()
	state = save_data.add_state(false)
	state.name = 'Idle'

	func_res = save_data.add_function()
	func_res.name = 'helper'

	macro = save_data.add_macro()
	macro.name = 'alarm'
	(macro.get_states(save_data)[0] as HenSaveState).name = 'Flash'


func after_test() -> void:
	HenRoute.go_base()
	await super ()


func _viewer() -> HenFlowViewer:
	var viewer: HenFlowViewer = auto_free(
		(load('res://addons/hengo/scenes/flow_viewer.tscn') as PackedScene).instantiate()
	)

	add_child(viewer)
	viewer.rebuild()

	return viewer


func _drawn(_viewer: HenFlowViewer) -> Array[String]:
	var names: Array[String] = []

	for entry: Variant in _viewer._states.values():
		names.append((entry.state as HenSaveState).name)

	names.sort()

	return names


# --- what each scope draws ---------------------------------------------------


func test_the_base_draws_the_states_of_the_script() -> void:
	assert_array(_drawn(_viewer())).contains(['Idle'])


func test_a_function_draws_its_own_body() -> void:
	HenRoute.enter(HenRoute.KIND_FUNCTION, func_res.id)

	assert_array(_drawn(_viewer())).is_equal(['helper'])


func test_a_macro_draws_the_states_it_holds() -> void:
	HenRoute.enter(HenRoute.KIND_MACRO, macro.id)

	assert_array(_drawn(_viewer())).is_equal(['Flash'])


# --- going back and forth ----------------------------------------------------


# picking a state of the script while a definition is open sends the canvas back
func test_picking_a_state_leaves_the_definition() -> void:
	var viewer: HenFlowViewer = _viewer()

	HenRoute.enter(HenRoute.KIND_FUNCTION, func_res.id)
	viewer.rebuild()

	assert_bool(viewer.focus_state(state)).is_true()

	viewer.rebuild()

	assert_bool(HenRoute.is_base()).is_true()
	assert_array(_drawn(viewer)).contains(['Idle'])


# and after being sent back, the definitions still open: this is the one that
# broke, since the canvas kept asking to centre on a state it had already found
func test_a_definition_still_opens_after_going_back() -> void:
	var viewer: HenFlowViewer = _viewer()

	HenRoute.enter(HenRoute.KIND_MACRO, macro.id)
	viewer.rebuild()
	viewer.focus_state(state)
	viewer.rebuild()

	HenRoute.enter(HenRoute.KIND_FUNCTION, func_res.id)
	viewer.rebuild()

	assert_str(String(HenRoute.current_id())).is_equal(String(func_res.id))
	assert_array(_drawn(viewer)).is_equal(['helper'])

	HenRoute.enter(HenRoute.KIND_MACRO, macro.id)
	viewer.rebuild()

	assert_str(str(HenRoute.current_id())).is_equal(String(macro.id))
	assert_array(_drawn(viewer)).is_equal(['Flash'])


# --- the path the ui actually takes ------------------------------------------


# the sidebar asks through the bus and the canvas answers on its own: no one calls
# rebuild by hand, which is where the bug lived
func test_the_bus_path_goes_in_and_out_and_in_again() -> void:
	var viewer: HenFlowViewer = _viewer()
	var bus: HenSignalBus = Engine.get_singleton(&'SignalBus')

	HenRoute.enter(HenRoute.KIND_MACRO, macro.id)

	assert_array(_drawn(viewer)).is_equal(['Flash'])

	bus.request_focus_state.emit(state)

	assert_bool(HenRoute.is_base()).is_true()
	assert_array(_drawn(viewer)).contains(['Idle'])

	HenRoute.enter(HenRoute.KIND_FUNCTION, func_res.id)

	assert_str(String(HenRoute.current_id())).is_equal(String(func_res.id))
	assert_array(_drawn(viewer)).is_equal(['helper'])


# --- the box of a use --------------------------------------------------------


func _entry_pins(_viewer: HenFlowViewer, _state: HenSaveState) -> Array[String]:
	var entry: HenFlowGraphTypes.FlowNode = (_viewer._states[String(_state.id)].graph as HenFlowGraphTypes.FlowGraph).entry
	var labels: Array[String] = []

	for pin: HenFlowGraphTypes.FlowPin in entry.pins:
		labels.append(pin.label)

	return labels


# the box is not a blank rectangle: it carries what the use hands the macro, the
# places it fills and the ways out it wires
func test_the_box_of_a_use_shows_its_ports() -> void:
	var param: HenSaveParam = macro.get_new_input()
	var hook: HenSaveFlowParam = macro.get_new_flow_input()
	var way: HenSaveFlowParam = macro.get_new_flow_output()

	param.name = 'label'
	hook.name = 'on aim'
	way.name = 'next'

	var use: HenSaveState = HenStateOps.request_add_macro_use(save_data, state, macro)

	use.name = 'pistol'

	var pins: Array[String] = _entry_pins(_viewer(), use)

	assert_array(pins).contains(['label', 'on aim', 'next'])
	# the four phases of a state are still there, since a use is one
	assert_array(pins).contains([HenActionVisuals.phase_label(&'enter'), HenActionVisuals.phase_label(&'update')])


# a branch that leaves the macro through a named way out still draws: where it
# lands is answered by each use, but the reader has to see that it leaves
func test_a_way_out_branch_draws_inside_the_macro() -> void:
	var way: HenSaveFlowParam = macro.get_new_flow_output()
	var inner: HenSaveState = macro.get_states(save_data)[0]
	var action: HenSaveAction = HenSaveAction.create(_transition_macro())

	way.name = 'next'
	action.branches['to'] = {exit_id = str(way.id), label = ''}
	save_data.add_state_action(inner.id, action)

	HenRoute.enter(HenRoute.KIND_MACRO, macro.id)

	var titles: Array[String] = []

	for node: HenFlowGraphTypes.FlowNode in (_viewer()._states[String(inner.id)].graph as HenFlowGraphTypes.FlowGraph).nodes:
		if node.kind == &'transition':
			titles.append(node.title)

	assert_array(titles).contains(['next'])


func _transition_macro() -> HenSaveMacro:
	var instance: HenScriptMacroBase = (load('res://addons/hengo/actions/flow/transition.gd') as GDScript).new()
	var macro_res: HenSaveMacro = HenSaveMacro.new()

	macro_res.id = instance.get_id()
	macro_res.name = 'transition'
	macro_res.is_script_macro = true
	macro_res.script_path = 'res://addons/hengo/actions/flow/transition.gd'

	for flow: Dictionary in instance.get_flow_outputs():
		macro_res.flow_outputs.append(HenSaveFlowParam.create(flow))

	for flow: Dictionary in instance.get_flow_inputs():
		macro_res.flow_inputs.append(HenSaveFlowParam.create(flow))

	(Engine.get_singleton(&'Global') as HenGlobal).action_macros.append(macro_res)

	return macro_res


# a port a macro leaves for its uses is not a lifecycle phase, so the palette has
# to offer what fits the phase that port runs at, not an empty list
func test_the_palette_of_a_place_offers_actions() -> void:
	var hook: HenSaveFlowParam = macro.get_new_flow_input()
	var inner: HenSaveState = macro.get_states(save_data)[0]
	var run: HenSaveAction = HenSaveAction.create(HenMacroHookMacro.macro_of(macro, hook))

	hook.name = 'on aim'
	run.phase = &'physics'
	save_data.add_state_action(inner.id, run)

	var use: HenSaveState = HenStateOps.request_add_macro_use(save_data, state, macro)
	var editor := HenStateViewerCardEditor.new()

	editor.target(save_data, use.id)

	# the port answers with the phase the macro runs it at
	assert_str(String(editor.effective_phase(StringName(str(hook.id))))).is_equal('physics')
	assert_int(HenActionPool.for_phase(editor.effective_phase(StringName(str(hook.id)))).size()).is_greater(0)
	# and a step dropped there keeps the port, not the phase
	assert_str(String(editor.effective_phase(&'enter'))).is_equal('enter')


# --- editing inside a definition ---------------------------------------------


func _register_phases() -> HenSaveMacro:
	var instance: HenScriptMacroBase = (load('res://tests/fixtures/action_phases.gd') as GDScript).new()
	var macro_res: HenSaveMacro = HenSaveMacro.new()

	macro_res.id = instance.get_id()
	macro_res.name = 'phases'
	macro_res.is_script_macro = true
	macro_res.script_path = 'res://tests/fixtures/action_phases.gd'

	for input: Dictionary in instance.get_inputs():
		macro_res.inputs.append(HenSaveParam.create(input))

	for flow: Dictionary in instance.get_flow_inputs():
		macro_res.flow_inputs.append(HenSaveFlowParam.create(flow))

	(Engine.get_singleton(&'Global') as HenGlobal).action_macros.append(macro_res)

	return macro_res


# a step added on a place of a macro is kept on that place, not on a phase
func test_a_step_added_on_a_place_stays_there() -> void:
	var hook: HenSaveFlowParam = macro.get_new_flow_input()
	var use: HenSaveState = HenStateOps.request_add_macro_use(save_data, state, macro)
	var editor := HenStateViewerCardEditor.new()

	hook.name = 'on aim'
	editor.target(save_data, use.id)
	editor._do_insert(_register_phases(), save_data, use.id, null, StringName(str(hook.id)), -1)

	var steps: Array = HenGeneratorAction.hook_steps(save_data, use, StringName(str(hook.id)))

	assert_int(steps.size()).is_equal(1)
	assert_str(String((steps[0] as HenSaveAction).phase)).is_equal(String(hook.id))


# the body of a function is an action list like any other, so a step lands in it
func test_a_step_added_inside_a_function_lands_in_its_body() -> void:
	var editor := HenStateViewerCardEditor.new()
	var scope: HenSaveState = func_res.scope_state()

	editor.target(save_data, scope.id)
	editor._do_insert(_register_phases(), save_data, scope.id, null, &'update', -1)

	assert_int(save_data.get_state_actions(scope.id).size()).is_equal(1)


# --- the definition going away while it is open ------------------------------


func test_deleting_the_open_function_falls_back_to_the_script() -> void:
	var viewer: HenFlowViewer = _viewer()
	var side_bar: HenSideBar = (load('res://addons/hengo/scenes/side_bar.tscn') as PackedScene).instantiate()

	add_child(side_bar)
	HenRoute.enter(HenRoute.KIND_FUNCTION, func_res.id)

	assert_array(_drawn(viewer)).is_equal(['helper'])

	side_bar._request_delete_resource(func_res)
	viewer.rebuild()

	assert_bool(HenRoute.is_base()).is_true()
	assert_array(_drawn(viewer)).contains(['Idle'])

	side_bar.free()


func test_deleting_the_open_macro_falls_back_to_the_script() -> void:
	var viewer: HenFlowViewer = _viewer()
	var side_bar: HenSideBar = (load('res://addons/hengo/scenes/side_bar.tscn') as PackedScene).instantiate()

	add_child(side_bar)
	HenRoute.enter(HenRoute.KIND_MACRO, macro.id)

	assert_array(_drawn(viewer)).is_equal(['Flash'])

	side_bar._request_delete_resource(macro)
	viewer.rebuild()

	assert_bool(HenRoute.is_base()).is_true()
	assert_array(_drawn(viewer)).contains(['Idle'])

	side_bar.free()


# --- copy, paste and undo inside a definition --------------------------------


# the clipboard and the undo stack are keyed by the list a step belongs to, and a
# function body is one of those lists like any state
func test_copy_and_paste_inside_a_function() -> void:
	var editor := HenStateViewerCardEditor.new()
	var scope: HenSaveState = func_res.scope_state()

	editor.target(save_data, scope.id)
	editor._do_insert(_register_phases(), save_data, scope.id, null, &'update', -1)

	var original: HenSaveAction = save_data.get_state_actions(scope.id)[0]

	HenActionClipboard.copy([original])
	editor.paste_around(HenActionClipboard.take(), original)

	assert_int(save_data.get_state_actions(scope.id).size()).is_equal(2)

	var pasted: HenSaveAction = save_data.get_state_actions(scope.id)[1]

	assert_str(String(pasted.macro_id)).is_equal(String(original.macro_id))
	assert_str(String(pasted.id)).is_not_equal(String(original.id))


# undo of an edit made inside a definition restores that definition, and not the
# state that happened to be on screen before
func test_undo_restores_the_body_of_the_open_definition() -> void:
	var editor := HenStateViewerCardEditor.new()
	var scope: HenSaveState = func_res.scope_state()
	var global: HenGlobal = Engine.get_singleton(&'Global')

	editor.record_hook = func(_states: Array, _label: String, _mutation: Callable) -> bool:
		return global.flow_history.record(save_data, _states, _label, _mutation)

	editor.target(save_data, scope.id)
	editor._insert_new(_register_phases(), scope.id, null, &'update', -1)

	assert_int(save_data.get_state_actions(scope.id).size()).is_equal(1)

	assert_bool(global.flow_history.undo(save_data)).is_true()
	assert_int(save_data.get_state_actions(scope.id).size()).is_equal(0)

	assert_bool(global.flow_history.redo(save_data)).is_true()
	assert_int(save_data.get_state_actions(scope.id).size()).is_equal(1)


# --- the values a use hands its macro -----------------------------------------

# the chips live on the entry card of the use, which carries no action of its own
func test_a_value_chip_of_a_use_answers_the_click() -> void:
	var param: HenSaveParam = macro.get_new_input()
	param.name = 'Loud'
	param.type = &'bool'
	param.default_value = false

	HenStateOps.request_add_macro_use(save_data, state, macro)

	var viewer: HenFlowViewer = _viewer()
	var hit: Dictionary = _chip_hit(viewer)

	assert_dict(hit).is_not_empty()
	assert_bool(viewer._dispatch_hit(hit)).is_true()
	assert_bool(bool(_use_param(viewer).default_value)).is_true()


# the row is what the chip of a non-bool value opens, and it has no action to
# render itself from
func test_the_row_of_a_use_value_renders_without_an_action() -> void:
	var param: HenSaveParam = macro.get_new_input()
	param.name = 'Speed'
	param.type = &'float'

	var use: HenSaveState = HenStateOps.request_add_macro_use(save_data, state, macro)
	var inspector: HenInspector = auto_free(
		(load('res://addons/hengo/scenes/custom_inspector.tscn') as PackedScene).instantiate()
	)

	add_child(inspector)
	inspector.edit_one_slot(null, {
		param = use.macro_inputs[0],
		type = 'float',
		bind_store = use.macro_bindings,
		bind_key = str(use.macro_inputs[0].id)
	}, 'Speed')

	assert_int(inspector.vbox.get_child_count()).is_greater(0)
	assert_object(_first_of_class(inspector.vbox, 'SpinBox')).is_not_null()


func _first_of_class(_node: Node, _class: String) -> Node:
	for child: Node in _node.get_children():
		if child.get_class() == _class:
			return child

		var found: Node = _first_of_class(child, _class)

		if found:
			return found

	return null


# the use holds its own copy of the value, not the one the definition declares
func _use_param(_viewer: HenFlowViewer) -> HenSaveParam:
	for entry: Variant in _viewer._states.values():
		if (entry.state as HenSaveState).is_macro_use():
			return (entry.state as HenSaveState).macro_inputs[0]

	return null


# a card rect is frame local and the hover cache already holds it in world space
func _chip_hit(_viewer: HenFlowViewer) -> Dictionary:
	for item: Dictionary in _viewer._hover_items:
		if item.kind != &'card':
			continue

		var card: HenFlowNodeCard = item.card

		for hit: Dictionary in card.get_hits():
			if hit.kind == &'chip':
				return _viewer.hit_at((item.rect as Rect2).position + (hit.rect as Rect2).get_center())

	return {}
