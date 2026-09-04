@tool
class_name TestHenActionValuePopup extends GdUnitTestSuite

# the one-line field behind Rename Action. it used to sit between a chip and the
# slot row too, which is why it once carried a button out to the value sources

const POPUP_SCENE = preload('res://addons/hengo/scenes/action_value_popup.tscn')


func _popup() -> HenActionValuePopup:
	var popup: HenActionValuePopup = POPUP_SCENE.instantiate()

	add_child(popup)
	auto_free(popup)

	return popup


func _key(_code: Key) -> InputEventKey:
	var event: InputEventKey = InputEventKey.new()

	event.keycode = _code
	event.pressed = true

	return event


# the field moved under a row when a button was added beside it, and a stale path
# only shows up as a crash while typing
func test_the_field_is_reachable() -> void:
	var popup: HenActionValuePopup = _popup()

	popup.edit({}, 'hello')

	assert_object(popup.get_node_or_null('Row/Input')).is_not_null()
	assert_str((popup.get_node('Row/Input') as LineEdit).text).is_equal('hello')


func test_enter_confirms_what_was_typed() -> void:
	var popup: HenActionValuePopup = _popup()
	var confirmed: Array = []

	popup.confirmed.connect(func(_chip: Variant, _text: String) -> void: confirmed.append(_text))
	popup.edit(null, 'dash')
	popup._on_field_input(_key(KEY_ENTER))

	assert_array(confirmed).contains_exactly(['dash'])


func test_escape_cancels() -> void:
	var popup: HenActionValuePopup = _popup()
	var cancelled: Array = []

	popup.cancelled.connect(func() -> void: cancelled.append(true))
	popup.edit(null, 'dash')
	popup._on_field_input(_key(KEY_ESCAPE))

	assert_int(cancelled.size()).is_equal(1)
