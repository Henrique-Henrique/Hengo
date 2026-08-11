@tool
class_name TestHenFlowDebug extends HenTestSuite

# the flash is visual and temporal, and no assertion here proves it is on screen:
# that is what temp/shot_flow.gd renders. this covers the machine around it


const FIX_MATH: String = 'res://addons/hengo/actions/math/math_operator.gd'

var state: HenSaveState
var other_state: HenSaveState


func before_test() -> void:
	super ()
	state = save_data.add_state(false)
	state.name = 'ScoreHand'
	other_state = save_data.add_state(false)
	other_state.name = 'Idle'


func _register(_path: String) -> HenSaveMacro:
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

	return macro


func _viewer() -> HenFlowViewer:
	var macro: HenSaveMacro = _register(FIX_MATH)
	var action: HenSaveAction = HenSaveAction.create(macro)

	action.phase = &'update'
	save_data.add_state_action(state.id, action)

	var viewer: HenFlowViewer = auto_free(
		(load('res://addons/hengo/scenes/flow_viewer.tscn') as PackedScene).instantiate()
	)

	add_child(viewer)
	viewer.rebuild()

	return viewer


func _bus() -> HenSignalBus:
	return Engine.get_singleton(&'SignalBus')


func _script_id() -> String:
	return String(save_data.identity.id)


func _frame_of(_viewer: HenFlowViewer, _name: String) -> HenFlowStateFrame:
	for node: Variant in _viewer._frames:
		var frame: HenFlowStateFrame = _viewer._frames[node]

		if frame.state_name == _name:
			return frame

	return null


func _first_action_card(_viewer: HenFlowViewer) -> HenFlowNodeCard:
	for entry: Variant in _viewer._states.values():
		for card: HenFlowNodeCard in entry.cards:
			if card.node.action:
				return card

	return null


# the runtime reports the key of the generated dictionary, which is snake_case.
# comparing against the editor name never matches and never errors
func test_the_running_state_is_matched_in_snake_case() -> void:
	var viewer: HenFlowViewer = _viewer()
	var frame: HenFlowStateFrame = _frame_of(viewer, 'ScoreHand')

	assert_object(frame).is_not_null()
	assert_bool(frame.is_running()).is_false()

	_bus().debug_state_changed.emit(&'score_hand', _script_id())

	assert_bool(frame.is_running()).is_true()
	assert_bool(_frame_of(viewer, 'Idle').is_running()).is_false()


func test_the_editor_name_alone_would_not_match() -> void:
	var viewer: HenFlowViewer = _viewer()

	_bus().debug_state_changed.emit(&'ScoreHand', _script_id())

	assert_bool(_frame_of(viewer, 'ScoreHand').is_running()).is_false()


func test_only_one_state_is_running_at_a_time() -> void:
	var viewer: HenFlowViewer = _viewer()

	_bus().debug_state_changed.emit(&'score_hand', _script_id())
	_bus().debug_state_changed.emit(&'idle', _script_id())

	assert_bool(_frame_of(viewer, 'ScoreHand').is_running()).is_false()
	assert_bool(_frame_of(viewer, 'Idle').is_running()).is_true()


func test_another_script_is_ignored() -> void:
	var viewer: HenFlowViewer = _viewer()

	_bus().debug_state_changed.emit(&'score_hand', 'some-other-script')

	assert_bool(_frame_of(viewer, 'ScoreHand').is_running()).is_false()


func test_an_action_flash_arms_and_expires() -> void:
	var viewer: HenFlowViewer = _viewer()
	var card: HenFlowNodeCard = _first_action_card(viewer)

	assert_object(card).is_not_null()

	_bus().debug_action_flow.emit(StringName(str(card.node.action.id)), _script_id())

	assert_bool(card.is_running()).is_true()

	# the expiry is a timestamp, so winding it back is the same as time passing
	viewer._flashes[str(card.node.action.id)] = Time.get_ticks_msec() - 1
	viewer._expire_flashes()

	assert_bool(card.is_running()).is_false()
	assert_dict(viewer._flashes).is_empty()


# an update action re-arms every frame; the expiry moves, the card does not redraw
func test_re_arming_pushes_the_expiry_forward() -> void:
	var viewer: HenFlowViewer = _viewer()
	var card: HenFlowNodeCard = _first_action_card(viewer)
	var id: String = str(card.node.action.id)

	_bus().debug_action_flow.emit(StringName(id), _script_id())

	var first: int = viewer._flashes[id]

	viewer._flashes[id] = first - 100
	_bus().debug_action_flow.emit(StringName(id), _script_id())

	assert_int(viewer._flashes[id]).is_greater(first - 100)
	assert_bool(card.is_running()).is_true()


# set_detail, set_hover and refresh_content all rebuild the draw list, so a
# highlight painted outside apply_size would be wiped by an unrelated hover
func test_the_flash_survives_a_redraw() -> void:
	var viewer: HenFlowViewer = _viewer()
	var card: HenFlowNodeCard = _first_action_card(viewer)

	_bus().debug_action_flow.emit(StringName(str(card.node.action.id)), _script_id())

	var lit: int = card._painter._ops.size()

	card.set_hover(&'header', null)

	assert_bool(card.is_running()).is_true()
	assert_int(card._painter._ops.size()).is_greater_equal(lit)

	card.set_hover(&'', null)

	assert_int(card._painter._ops.size()).is_equal(lit)


func test_stopping_the_session_clears_everything() -> void:
	var viewer: HenFlowViewer = _viewer()
	var card: HenFlowNodeCard = _first_action_card(viewer)

	_bus().debug_state_changed.emit(&'score_hand', _script_id())
	_bus().debug_action_flow.emit(StringName(str(card.node.action.id)), _script_id())

	_bus().debug_session_stopped.emit()

	assert_bool(_frame_of(viewer, 'ScoreHand').is_running()).is_false()
	assert_bool(card.is_running()).is_false()
	assert_dict(viewer._flashes).is_empty()


# a rebuild frees every card, so a flash kept on the card object would die with it
func test_the_running_state_survives_a_rebuild() -> void:
	var viewer: HenFlowViewer = _viewer()

	_bus().debug_state_changed.emit(&'score_hand', _script_id())
	viewer.rebuild()

	assert_bool(_frame_of(viewer, 'ScoreHand').is_running()).is_true()
