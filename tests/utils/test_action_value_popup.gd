@tool
class_name TestHenActionValuePopup extends GdUnitTestSuite

# the chip of a Variant slot opens the text field and nothing else, so the field
# is the only way into a slot that wants a variable: it has to offer the way out

const POPUP_SCENE = preload('res://addons/hengo/scenes/action_value_popup.tscn')


func _popup() -> HenActionValuePopup:
	var popup: HenActionValuePopup = POPUP_SCENE.instantiate()

	add_child(popup)
	auto_free(popup)

	return popup


# the field moved under a row when the button was added, and a stale path only
# shows up as a crash while typing
func test_the_field_is_reachable() -> void:
	var popup: HenActionValuePopup = _popup()

	popup.edit({}, 'hello')

	assert_object(popup.get_node_or_null('Row/Input')).is_not_null()
	assert_str((popup.get_node('Row/Input') as LineEdit).text).is_equal('hello')


func test_the_field_offers_a_way_to_a_variable() -> void:
	var popup: HenActionValuePopup = _popup()
	var button: Button = popup.get_node_or_null('Row/BindBt')

	assert_object(button).is_not_null()

	var asked: Array = []

	popup.bind_requested.connect(func(chip: Variant) -> void: asked.append(chip))
	popup.edit({name = 'slot'}, '')
	button.pressed.emit()

	assert_int(asked.size()).is_equal(1)
	assert_str(str((asked[0] as Dictionary).get('name', ''))).is_equal('slot')


# a Variant slot reads as text on the card, which is what sends it to the field
func test_a_variant_slot_still_uses_the_text_editor() -> void:
	assert_str(str(HenActionValueEditors.kind_for('Variant'))).is_equal(str(HenActionValueEditors.TEXT))
