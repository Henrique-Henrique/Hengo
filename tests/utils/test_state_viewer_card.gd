@tool
class_name TestHenStateViewerCard extends HenTestSuite


const FIX_PHASES: String = 'res://tests/fixtures/action_phases.gd'

var state: HenSaveState
var macro: HenSaveMacro


func before_test() -> void:
	super ()
	state = save_data.add_state(false)
	state.name = 'state test'
	macro = _register(FIX_PHASES)


# mirrors HenScriptMacroLoader._load_macro_script
func _register(_path: String) -> HenSaveMacro:
	var instance: HenScriptMacroBase = (load(_path) as GDScript).new()
	var result: HenSaveMacro = HenSaveMacro.new()

	result.id = instance.get_id()
	result.name = _path.get_file().get_basename()
	result.is_script_macro = true
	result.script_path = _path

	for input: Dictionary in instance.get_inputs():
		result.inputs.append(HenSaveParam.create(input))

	for flow: Dictionary in instance.get_flow_inputs():
		result.flow_inputs.append(HenSaveFlowParam.create(flow))

	(Engine.get_singleton(&'Global') as HenGlobal).action_macros.append(result)

	return result


func _add_action(_phase: StringName) -> HenSaveAction:
	var action: HenSaveAction = HenSaveAction.create(macro)
	action.phase = _phase
	save_data.add_state_action(state.id, action)

	return action


func _card() -> HenStateViewerCard:
	var host: Control = auto_free(Control.new())
	add_child(host)

	var card: HenStateViewerCard = auto_free(HenStateViewerCard.new())
	host.add_child(card)
	card.setup(host, save_data, {state_id = str(state.id)}, state.name, false, false)

	return card


func test_empty_state_still_has_a_card() -> void:
	var size: Vector2 = _card().compute_size()

	assert_float(size.x).is_greater(0.0)
	assert_float(size.y).is_greater(0.0)


func test_every_action_gets_a_hit_rect() -> void:
	_add_action(&'enter')
	_add_action(&'update')
	_add_action(&'update')

	var card: HenStateViewerCard = _card()
	card.apply_size(card.compute_size())

	var rows: int = 0

	for hit: Dictionary in card.get_hits():
		if hit.kind == &'row':
			rows += 1

	assert_int(rows).is_equal(3)


func test_hit_rects_stay_inside_the_card() -> void:
	_add_action(&'enter')
	_add_action(&'update')

	var card: HenStateViewerCard = _card()
	var size: Vector2 = card.compute_size()
	card.apply_size(size)

	var bounds: Rect2 = Rect2(Vector2.ZERO, size)

	for hit: Dictionary in card.get_hits():
		assert_bool(bounds.encloses(hit.rect)) \
			.override_failure_message('%s %s fora do card %s' % [hit.kind, hit.rect, size]) \
			.is_true()


func test_more_actions_make_a_taller_card() -> void:
	var one: Vector2 = _card_height_with(1)
	var three: Vector2 = _card_height_with(3)

	assert_float(three.y).is_greater(one.y)


func _card_height_with(_count: int) -> Vector2:
	for i: int in _count:
		_add_action(&'update')

	return _card().compute_size()


func _hits_with(_card: HenStateViewerCard, _kind: StringName) -> Array:
	var out: Array = []

	for hit: Dictionary in _card.get_hits():
		if hit.kind == _kind:
			out.append(hit)

	return out


# dictionaries compare by value in gdscript, so identical chips would share a
# highlight if the index were not carried
func test_chip_hits_have_unique_indexes() -> void:
	_add_action(&'update')
	_add_action(&'update')
	_add_action(&'update')

	var card: HenStateViewerCard = _card()
	card.apply_size(card.compute_size())

	var seen: Dictionary = {}

	for hit: Dictionary in _hits_with(card, &'chip'):
		assert_bool(seen.has(hit.index)) \
			.override_failure_message('indice de chip repetido: %s' % hit.index) \
			.is_false()
		seen[hit.index] = true

	assert_int(seen.size()).is_equal(3)


# the click router takes the first rect containing the point, so a chip has to be
# emitted before the row that holds it
func test_chip_resolves_before_its_row() -> void:
	_add_action(&'update')

	var card: HenStateViewerCard = _card()
	card.apply_size(card.compute_size())

	var chip: Dictionary = _hits_with(card, &'chip')[0]
	var point: Vector2 = (chip.rect as Rect2).get_center()
	var first: Dictionary = {}

	for hit: Dictionary in card.get_hits():
		if (hit.rect as Rect2).has_point(point):
			first = hit
			break

	assert_str(str(first.get('kind', ''))).is_equal('chip')


# every visual state re-emits the card, so repeating one has to be a no-op: a
# card that redraws on an unchanged state redraws every frame
func test_visual_state_only_re_emits_on_a_real_change() -> void:
	var action: HenSaveAction = _add_action(&'update')

	var card: HenStateViewerCard = _card()
	card.apply_size(card.compute_size())

	assert_bool(card.set_hover(&'chip', 0)).is_true()
	assert_bool(card.set_hover(&'chip', 0)).is_false()

	assert_bool(card.set_drop_hint(&'row', action, true)).is_true()
	assert_bool(card.set_drop_hint(&'row', action, true)).is_false()

	assert_bool(card.set_highlight(&'running')).is_true()
	assert_bool(card.set_highlight(&'running')).is_false()


# the hit rects have to survive a re-emit, which is what tabbing between chips does
func test_refresh_content_keeps_the_hit_rects() -> void:
	_add_action(&'update')
	_add_action(&'update')

	var card: HenStateViewerCard = _card()
	card.apply_size(card.compute_size())

	var before: int = card.get_hits().size()
	card.refresh_content()

	assert_int(card.get_hits().size()).is_equal(before)


# the phase add button sits inside the header, so it has to win the hit test
func test_phase_add_resolves_before_the_header() -> void:
	_add_action(&'update')

	var card: HenStateViewerCard = _card()
	card.apply_size(card.compute_size())

	var add: Dictionary = _hits_with(card, &'phase_add')[0]
	var point: Vector2 = (add.rect as Rect2).get_center()
	var first: Dictionary = {}

	for hit: Dictionary in card.get_hits():
		if (hit.rect as Rect2).has_point(point):
			first = hit
			break

	assert_str(str(first.get('kind', ''))).is_equal('phase_add')
	assert_int(_hits_with(card, &'phase').size()).is_equal(1)


# the preview re-emits a row, and must not corrupt the card it came from
func test_row_preview_leaves_the_card_untouched() -> void:
	var action: HenSaveAction = _add_action(&'update')
	_add_action(&'update')

	var card: HenStateViewerCard = _card()
	card.apply_size(card.compute_size())

	var hits_before: int = card.get_hits().size()
	var ops_before: int = card._painter._ops.size()

	var preview: Control = auto_free(card.build_row_preview(action))

	assert_object(preview).is_not_null()
	assert_vector(preview.size).is_not_equal(Vector2.ZERO)
	assert_int(preview._painter._ops.size()).is_greater(0)
	assert_int(card.get_hits().size()).is_equal(hits_before)
	assert_int(card._painter._ops.size()).is_equal(ops_before)


# an update action re-arms its flash every frame, so re-arming the same set must
# not redraw the card again
func test_running_set_only_redraws_on_a_real_change() -> void:
	var action: HenSaveAction = _add_action(&'update')

	var card: HenStateViewerCard = _card()
	card.apply_size(card.compute_size())

	var ids: Dictionary = {}
	ids[str(action.id)] = 1000

	assert_bool(card.set_running(ids)).is_true()
	assert_bool(card.set_running(ids.duplicate())).is_false()
	assert_bool(card.set_running({})).is_true()


func test_has_row_finds_only_its_own_actions() -> void:
	var action: HenSaveAction = _add_action(&'update')

	var card: HenStateViewerCard = _card()
	card.compute_size()

	assert_bool(card.has_row(StringName(str(action.id)))).is_true()
	assert_bool(card.has_row(&'not_an_action')).is_false()


# the compact card keeps its footprint, otherwise the whole graph would reflow
# every time the zoom crosses the threshold
func test_compact_detail_keeps_the_measured_size() -> void:
	_add_action(&'enter')
	_add_action(&'update')

	var card: HenStateViewerCard = _card()
	var full: Vector2 = card.compute_size()

	card.apply_size(full)
	card.set_detail(HenStateViewerCard.Detail.COMPACT)

	assert_vector(card.compute_size()).is_equal(full)


# no rows are drawn, so a click has to fall through to opening the state
func test_compact_detail_drops_the_row_hits() -> void:
	_add_action(&'update')
	_add_action(&'update')

	var card: HenStateViewerCard = _card()
	card.apply_size(card.compute_size())

	assert_int(_hits_with(card, &'row').size()).is_equal(2)

	card.set_detail(HenStateViewerCard.Detail.COMPACT)

	assert_int(card.get_hits().size()).is_equal(0)

	card.set_detail(HenStateViewerCard.Detail.FULL)

	assert_int(_hits_with(card, &'row').size()).is_equal(2)


# the name is counter-scaled by a transform, so zooming never reshapes its text
func test_compact_title_scales_without_redrawing() -> void:
	_add_action(&'update')

	var card: HenStateViewerCard = _card()
	card.apply_size(card.compute_size())
	card.set_detail(HenStateViewerCard.Detail.COMPACT)

	var ops: int = card._compact_label._painter._ops.size()

	card.set_title_scale(4.0)

	assert_vector(card._compact_label.scale).is_equal(Vector2(4.0, 4.0))
	assert_int(card._compact_label._painter._ops.size()).is_equal(ops)


# the label is centered on its own origin, so the parent only places it
func test_compact_label_sits_at_the_card_center() -> void:
	var card: HenStateViewerCard = _card()
	var size: Vector2 = card.compute_size()

	card.apply_size(size)
	card.set_detail(HenStateViewerCard.Detail.COMPACT)

	assert_vector(card._compact_label.position).is_equal(size * 0.5)


# the far tier drops the count, which is noise in a field of names
func test_name_detail_shows_only_the_title() -> void:
	_add_action(&'update')
	_add_action(&'update')

	var card: HenStateViewerCard = _card()
	card.apply_size(card.compute_size())

	card.set_detail(HenStateViewerCard.Detail.COMPACT)
	var with_count: int = card._compact_label._painter._ops.size()

	card.set_detail(HenStateViewerCard.Detail.NAME)
	var name_only: int = card._compact_label._painter._ops.size()

	assert_int(name_only).is_less(with_count)
	assert_int(name_only).is_equal(1)


func test_every_detail_keeps_the_measured_size() -> void:
	_add_action(&'enter')
	_add_action(&'update')

	var card: HenStateViewerCard = _card()
	var full: Vector2 = card.compute_size()

	card.apply_size(full)

	for level: int in [HenStateViewerCard.Detail.COMPACT, HenStateViewerCard.Detail.NAME]:
		card.set_detail(level)
		assert_vector(card.compute_size()) \
			.override_failure_message('detalhe %d mudou o tamanho' % level) \
			.is_equal(full)


# a machine is mostly its own states, so its name has to stay on the header band
# instead of landing in the middle of them
func test_compound_name_sits_on_the_header_not_the_middle() -> void:
	var host: Control = auto_free(Control.new())
	add_child(host)

	var card: HenStateViewerCard = auto_free(HenStateViewerCard.new())
	host.add_child(card)
	card.setup(host, save_data, {}, 'machine', true, false)

	var header: Vector2 = card.compute_size()
	var full: Vector2 = Vector2(2000, 1500)

	card.apply_size(full)
	card.set_detail(HenStateViewerCard.Detail.NAME)

	assert_float(card._compact_label.position.x).is_equal(full.x * 0.5)
	assert_float(card._compact_label.position.y).is_equal(header.y * 0.5)
	assert_float(card._compact_label.position.y).is_less(full.y * 0.25)


func test_culled_card_rebuilds_when_shown_again() -> void:
	_add_action(&'update')

	var card: HenStateViewerCard = _card()
	card.apply_size(card.compute_size())

	var ops: int = card._painter._ops.size()

	card.set_culled(true)
	card.set_detail(HenStateViewerCard.Detail.COMPACT)

	assert_bool(card.visible).is_false()
	assert_bool(card._needs_emit).is_true()

	card.set_culled(false)

	assert_bool(card.visible).is_true()
	assert_bool(card._needs_emit).is_false()
	assert_int(card._painter._ops.size()).is_not_equal(ops)


