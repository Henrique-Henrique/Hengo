@tool
class_name TestHenActionValueEditors extends HenTestSuite


const FIX_BOOL: String = 'res://addons/hengo/actions/control/set_disabled.gd'
const FIX_VECTOR2: String = 'res://addons/hengo/actions/node2d/set_position.gd'
const FIX_COLOR: String = 'res://addons/hengo/actions/render/change_color.gd'
const FIX_ARRAY: String = 'res://addons/hengo/actions/array/array_add.gd'
const FIX_MATH: String = 'res://addons/hengo/actions/math/math_operator.gd'
const FIX_COOLDOWN: String = 'res://addons/hengo/actions/flow/cooldown.gd'
const FIX_MOUSE: String = 'res://addons/hengo/actions/input/get_mouse_position.gd'
const FIX_SPLIT: String = 'res://addons/hengo/actions/vector/get_vector2_xy.gd'

var state: HenSaveState


func before_test() -> void:
	super ()
	state = save_data.add_state(false)
	state.name = 'Play'


func _action(_path: String) -> HenSaveAction:
	var instance: HenScriptMacroBase = (load(_path) as GDScript).new()
	var macro: HenSaveMacro = HenSaveMacro.new()

	macro.id = instance.get_id()
	macro.name = _path.get_file().get_basename()
	macro.is_script_macro = true
	macro.script_path = _path

	for input: Dictionary in instance.get_inputs():
		macro.inputs.append(HenSaveParam.create(input))

	for output: Dictionary in instance.get_outputs():
		macro.outputs.append(HenSaveParam.create(output))

	(Engine.get_singleton(&'Global') as HenGlobal).action_macros.append(macro)

	return HenSaveAction.create(macro)


func _part_named(_action: HenSaveAction, _name: String) -> Dictionary:
	for part: Dictionary in HenActionsPanel.value_parts(_action, save_data):
		if (part.get('slot', {}) as Dictionary).get('param') and (part.slot.param as HenSaveParam).name == _name:
			return part

	return {}


func _viewer() -> HenFlowViewer:
	var viewer: HenFlowViewer = auto_free(
		(load('res://addons/hengo/scenes/flow_viewer.tscn') as PackedScene).instantiate()
	)

	add_child(viewer)
	viewer.rebuild()

	return viewer


# a text field on the card could only write a literal, so reaching a variable cost
# a second popup: every type but bool opens the slot row, which has all of them
func test_only_a_bool_is_handled_on_the_card() -> void:
	for type: String in ['String', 'StringName', 'int', 'float', 'Variant']:
		assert_str(str(HenActionValueEditors.kind_for(type))).is_empty()

	assert_str(str(HenActionValueEditors.kind_for('bool'))).is_equal('bool')


func test_a_bool_input_gets_the_bool_editor() -> void:
	var part: Dictionary = _part_named(_action(FIX_BOOL), 'Disabled')

	assert_bool(part.is_empty()).is_false()
	assert_str(str(part.get('editor', ''))).is_equal('bool')


# a typed editor already exists as a prop scene, so the chip opens the slot row
# instead of a second one built for the card
func test_the_typed_editors_are_left_to_the_slot_row() -> void:
	for type: String in ['Vector2', 'Vector3', 'Color', 'Array', 'Dictionary']:
		assert_str(str(HenActionValueEditors.kind_for(type))).is_empty()

	assert_str(str(_part_named(_action(FIX_VECTOR2), 'Position').get('editor', ''))).is_empty()
	assert_str(str(_part_named(_action(FIX_COLOR), 'Color').get('editor', ''))).is_empty()
	assert_str(str(_part_named(_action(FIX_ARRAY), 'Array').get('editor', ''))).is_empty()


# a node reference is a binding, not a literal, so no small editor may claim it
func test_a_bind_only_input_gets_no_editor() -> void:
	var part: Dictionary = _part_named(_action(FIX_BOOL), 'Target')

	assert_bool(part.is_empty()).is_false()
	assert_str(str(part.get('editor', ''))).is_empty()


func test_the_chip_of_an_untyped_value_is_still_drawn() -> void:
	assert_str(str(_part_named(_action(FIX_VECTOR2), 'Position').get('value', ''))).is_not_empty()


# clicking a bound value or an expression used to open every input of the action
# plus its phase and its menu
func test_the_slot_popup_renders_a_single_row() -> void:
	var action: HenSaveAction = _action(FIX_BOOL)
	var inspector: HenInspector = auto_free(
		(load('res://addons/hengo/scenes/custom_inspector.tscn') as PackedScene).instantiate()
	)

	add_child(inspector)
	inspector.edit_one_slot(action, _part_named(action, 'Disabled').slot, 'Disabled')

	assert_int(inspector.vbox.get_child_count()).is_equal(1)


func _row_for(_action: HenSaveAction, _slot_name: String) -> HenInspector:
	var inspector: HenInspector = auto_free(
		(load('res://addons/hengo/scenes/custom_inspector.tscn') as PackedScene).instantiate()
	)

	add_child(inspector)
	inspector.edit_one_slot(_action, _part_named(_action, _slot_name).slot, _slot_name)

	return inspector


# the chip used to open a text field whose only exit to a variable was a button
# that opened this row anyway: the row is what the chip opens now, so typing has
# to work the moment it appears
func test_the_row_opens_with_the_caret_in_the_editor() -> void:
	var inspector: HenInspector = _row_for(_action(FIX_MATH), 'A')

	inspector.focus_editor()

	var editor: Control = inspector._first_editor(inspector.vbox)

	assert_object(editor).is_not_null()
	assert_bool(editor.has_focus()).is_true()


# a slot that takes no literal renders a "Choose a variable..." button, and a
# grab_focus aimed at nothing must not throw
func test_a_bind_only_row_has_no_editor_to_focus() -> void:
	var inspector: HenInspector = _row_for(_action(FIX_BOOL), 'Target')

	assert_object(inspector._first_editor(inspector.vbox)).is_null()

	inspector.focus_editor()


# the caret is put in the field, so the keyboard has to be able to leave it: the
# editors write on every keystroke, so both keys are a plain dismiss
func test_the_focused_editor_takes_enter_and_escape() -> void:
	var inspector: HenInspector = _row_for(_action(FIX_MATH), 'A')

	inspector.focus_editor()

	assert_bool(inspector._first_editor(inspector.vbox).gui_input.is_connected(inspector._on_editor_input)).is_true()

	for code: Key in [KEY_ENTER, KEY_KP_ENTER, KEY_ESCAPE]:
		assert_bool(HenInspector.is_dismiss_key(_key(code))).is_true()


# typing is the whole point of the caret being there, so a letter must not close
func test_a_plain_key_leaves_the_row_open() -> void:
	assert_bool(HenInspector.is_dismiss_key(_key(KEY_A))).is_false()

	var released: InputEventKey = _key(KEY_ENTER)

	released.pressed = false

	assert_bool(HenInspector.is_dismiss_key(released)).is_false()
	assert_bool(HenInspector.is_dismiss_key(InputEventMouseButton.new())).is_false()


func _key(_code: Key) -> InputEventKey:
	var event: InputEventKey = InputEventKey.new()

	event.keycode = _code
	event.pressed = true

	return event


# picking a source redraws the row, and the redraw used to come back as the whole
# action: phase selector, both branches and every other input
func test_picking_a_source_keeps_the_popup_on_one_row() -> void:
	var action: HenSaveAction = _action(FIX_MATH)
	var slot: Dictionary = _part_named(action, 'A').slot
	var inspector: HenInspector = _row_for(action, 'A')

	inspector._on_bind_selected({kind = 'bind', code = 'rotation'}, slot)

	assert_str(str(action.input_bindings.get('a', ''))).is_equal('rotation')
	assert_int(_live_rows(inspector)).is_equal(1)


func test_clearing_a_source_keeps_the_popup_on_one_row() -> void:
	var action: HenSaveAction = _action(FIX_MATH)
	var slot: Dictionary = _part_named(action, 'A').slot
	var inspector: HenInspector = _row_for(action, 'A')

	inspector._on_bind_selected({kind = 'none'}, slot)

	assert_int(_live_rows(inspector)).is_equal(1)


func test_a_branch_popup_also_redraws_as_one_row() -> void:
	var action: HenSaveAction = _action(FIX_MATH)
	var inspector: HenInspector = auto_free(
		(load('res://addons/hengo/scenes/custom_inspector.tscn') as PackedScene).instantiate()
	)

	add_child(inspector)
	inspector.edit_one_branch(action, 'true', 'Yes')

	var before: int = _live_rows(inspector)

	inspector._update_props()

	assert_int(_live_rows(inspector)).is_equal(before)


# _update_props frees the old rows without unparenting them, so they are still
# children for the rest of the frame
func _live_rows(_inspector: HenInspector) -> int:
	var count: int = 0

	for child: Node in _inspector.vbox.get_children():
		if not child.is_queued_for_deletion():
			count += 1

	return count


func test_the_whole_inspector_still_renders_every_row() -> void:
	var action: HenSaveAction = _action(FIX_BOOL)
	var inspector: HenInspector = auto_free(
		(load('res://addons/hengo/scenes/custom_inspector.tscn') as PackedScene).instantiate()
	)

	add_child(inspector)
	inspector.edit(action, 'Set Disabled')

	assert_int(inspector.vbox.get_child_count()).is_greater(1)


func _hits_of(_viewer: HenFlowViewer, _action: HenSaveAction, _kind: StringName) -> Array:
	var card: HenFlowNodeCard = _viewer._cards_by_action.get(str(_action.id))

	if not card:
		return []

	return card.get_hits().filter(func(h): return h.kind == _kind)


func _card_with(_action: HenSaveAction) -> HenFlowViewer:
	_action.phase = &'update'
	save_data.add_state_action(state.id, _action)

	return _viewer()


func test_an_input_pin_is_clickable() -> void:
	var action: HenSaveAction = _action(FIX_VECTOR2)
	var viewer: HenFlowViewer = _card_with(action)
	var hits: Array = _hits_of(viewer, action, &'pin')

	assert_int(hits.size()).is_equal(1)
	# the drawn dot is 13px and unreachable once the cam zooms out
	assert_float((hits[0].rect as Rect2).size.x).is_greater(HenFlowNodeCard.SLOT_DOT)


# the chip is emitted first, so it wins wherever the two rects meet
func test_the_chip_wins_over_the_pin() -> void:
	var action: HenSaveAction = _action(FIX_VECTOR2)
	var viewer: HenFlowViewer = _card_with(action)
	var card: HenFlowNodeCard = viewer._cards_by_action.get(str(action.id))
	var pin_rect: Rect2 = _hits_of(viewer, action, &'pin')[0].rect
	var chip_rect: Rect2 = _hits_of(viewer, action, &'chip')[0].rect

	assert_bool(pin_rect.intersects(chip_rect)).is_false()

	var chip_index: int = -1
	var pin_index: int = -1

	for i: int in range(card.get_hits().size()):
		var kind: StringName = card.get_hits()[i].kind

		if kind == &'chip' and chip_index < 0:
			chip_index = i
		if kind == &'pin' and pin_index < 0:
			pin_index = i

	assert_int(chip_index).is_less(pin_index)


# a pin fed by a producer already has a wire, and its source is that card
func test_a_pin_fed_by_a_producer_has_no_picker() -> void:
	var action: HenSaveAction = _action(FIX_VECTOR2)
	var producer: HenSaveAction = _action(FIX_VECTOR2)

	action.input_actions[str(action.inputs[0].id)] = {action = producer, output = &'result'}

	var viewer: HenFlowViewer = _card_with(action)

	assert_int(_hits_of(viewer, action, &'pin').size()).is_equal(0)


func _macro_named(_name: String) -> HenSaveMacro:
	for macro: HenSaveMacro in (Engine.get_singleton(&'Global') as HenGlobal).action_macros:
		if macro.name == _name:
			return macro

	return null


func _pool_names(_type: String) -> Array:
	var search: HenActionsSearch = auto_free(
		(load('res://addons/hengo/scenes/actions_search.tscn') as PackedScene).instantiate()
	)

	# added first on purpose: _ready populates inside add_child, and a picker
	# configured afterwards used to keep the unfiltered list it built there
	add_child(search)
	search.setup_producer_picker(_type, func(_m: HenSaveMacro) -> void: pass)

	return search._get_pool().map(func(m): return m.name)


func test_a_branching_action_is_never_offered_as_a_producer() -> void:
	_action(FIX_MATH)
	_action(FIX_COOLDOWN)

	var names: Array = _pool_names('float')

	assert_bool(names.has('math_operator')).is_true()
	assert_bool(names.has('cooldown')).is_false()


func test_a_concrete_output_type_is_matched() -> void:
	_action(FIX_MOUSE)

	assert_bool(_pool_names('Vector2').has('get_mouse_position')).is_true()
	assert_bool(_pool_names('String').has('get_mouse_position')).is_false()


# the project rule treats Variant as compatible both ways, so an action that
# declares one is offered everywhere. Array Get feeding a float depends on it
func test_a_variant_output_is_offered_for_any_type() -> void:
	_action(FIX_MATH)

	assert_bool(_pool_names('Array').has('math_operator')).is_true()


# an input has one source, so the binding and the expression cannot survive it
func test_setting_a_producer_drops_the_other_sources() -> void:
	var action: HenSaveAction = _action(FIX_VECTOR2)
	var part: Dictionary = _part_named(action, 'Position')
	var key: String = str(action.inputs[0].id)

	action.input_bindings[key] = 'some_var'
	action.input_expressions[key] = HenSaveActionExpression.new()

	var macro: HenSaveMacro = (Engine.get_singleton(&'Global') as HenGlobal).action_macros[-1]
	var child: HenSaveAction = HenActionsPanel.set_producer(part.slot, macro)

	assert_object(child).is_not_null()
	assert_bool(action.input_actions.has(key)).is_true()
	assert_bool(action.input_bindings.has(key)).is_false()
	assert_bool(action.input_expressions.has(key)).is_false()


# the chip text is baked into the pin at build time, so an edit that does not
# rebuild the graph showed the old value until the view was refreshed by hand
func test_a_committed_value_reaches_the_card() -> void:
	var action: HenSaveAction = _action(FIX_VECTOR2)

	action.phase = &'update'
	save_data.add_state_action(state.id, action)

	var viewer: HenFlowViewer = _viewer()
	var card: Variant = viewer._cards_by_action.get(str(action.id))

	assert_object(card).is_not_null()

	viewer._editing_card = card
	action.inputs[0].default_value = Vector2(42.0, 7.0)
	viewer._refresh_edited_card()

	var pin: HenFlowGraphTypes.FlowPin = (card as HenFlowNodeCard).node.pins_of(&'data_in')[0]

	assert_str(str(pin.part.get('value', ''))).contains('42')


# the camera compensates the relayout, so the edited card keeps its place on
# screen even when a longer value pushes the whole graph sideways
func test_the_edited_card_holds_its_screen_position() -> void:
	# the second of a chain is centred on the first, so growing it moves it
	var first: HenSaveAction = _action(FIX_VECTOR2)
	var action: HenSaveAction = _action(FIX_VECTOR2)

	first.phase = &'update'
	action.phase = &'update'
	# the wide one owns the left edge of the box, so normalising after the relayout
	# cannot cancel the movement of the card below it
	first.inputs[0].default_value = Vector2(111111111111.111, 222222222222.222)
	save_data.add_state_action(state.id, first)
	save_data.add_state_action(state.id, action)

	var viewer: HenFlowViewer = _viewer()
	var card: Variant = viewer._cards_by_action.get(str(action.id))

	assert_object(card).is_not_null()

	var cam: HenCam = viewer._cam()
	var world_before: Vector2 = viewer._world_of(card)
	var before: Vector2 = world_before * cam.transform.x.x + cam.transform.origin

	viewer._editing_card = card
	# the header floors the card width, so a narrow value would not relayout
	action.inputs[0].default_value = Vector2(111111111.111, 222222222.222)
	viewer._refresh_edited_card()

	var moved: Variant = viewer._cards_by_action.get(str(action.id))
	var world_after: Vector2 = viewer._world_of(moved)
	var after: Vector2 = world_after * cam.transform.x.x + cam.transform.origin

	# without a relayout the compensation is a no-op and this asserts nothing
	assert_vector(world_after).is_not_equal(world_before)
	assert_vector(after).is_equal_approx(before, Vector2.ONE)


func _code_search(_type: String) -> HenCodeSearch:
	var picked: Array = []
	var search: HenCodeSearch = auto_free(HenCodeSearch.load(Vector2.ZERO, {
		type = StringName(_type),
		io_type = &'in',
		on_pick = func(_m: HenSaveMacro) -> void: picked.append(_m)
	}))

	search.set_meta('picked', picked)

	return search


func test_the_code_search_enters_action_mode_with_a_pick() -> void:
	assert_bool(_code_search('float').is_action_mode()).is_true()
	assert_bool(auto_free(HenCodeSearch.load(Vector2.ZERO, {type = &'float'})).is_action_mode()).is_false()


# the categories the picker offers are the action folders, not the api classes
func test_the_action_categories_are_grouped_and_filtered() -> void:
	_action(FIX_MATH)
	_action(FIX_COOLDOWN)
	_action(FIX_MOUSE)

	var names: Array = HenActionPool.producers_for('Vector2').map(func(m): return m.name)

	assert_bool(names.has('get_mouse_position')).is_true()
	assert_bool(names.has('cooldown')).is_false()


func test_the_pool_is_shared_by_both_pickers() -> void:
	_action(FIX_MOUSE)

	assert_array(HenActionPool.producers_for('Vector2')).is_equal(_pool_names_macros('Vector2'))


func _pool_names_macros(_type: String) -> Array:
	var search: HenActionsSearch = auto_free(
		(load('res://addons/hengo/scenes/actions_search.tscn') as PackedScene).instantiate()
	)

	add_child(search)
	search.setup_producer_picker(_type, func(_m: HenSaveMacro) -> void: pass)

	return search._get_pool()


# a Vector2 XY has an X and a Y: taking the first silently always wired X
func test_an_action_with_two_usable_outputs_lists_them() -> void:
	_action(FIX_SPLIT)

	var macro: HenSaveMacro = _macro_named('get_vector2_xy')

	assert_object(macro).is_not_null()

	var outputs: Array = HenActionPool.outputs_for(macro, 'float')

	assert_int(outputs.size()).is_greater(1)


func test_a_single_output_needs_no_choice() -> void:
	_action(FIX_MOUSE)

	assert_int(HenActionPool.outputs_for(_macro_named('get_mouse_position'), 'Vector2').size()).is_equal(1)


# the stored source is {action, output}, so the chosen port has to reach it
func test_the_chosen_output_is_stored() -> void:
	var action: HenSaveAction = _action(FIX_VECTOR2)
	var part: Dictionary = _part_named(action, 'Position')

	_action(FIX_SPLIT)

	HenActionsPanel.set_producer(part.slot, _macro_named('get_vector2_xy'), &'y')

	var entry: Dictionary = action.input_actions[str(action.inputs[0].id)]

	assert_str(str(entry.output)).is_equal('y')
