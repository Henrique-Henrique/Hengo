@tool
class_name TestHenTooltip extends GdUnitTestSuite

# the doc tooltip waits for the cursor to settle, and a cursor that left before
# the wait ended must not be answered later


func _tooltip() -> HenTooltip:
	var tip: HenTooltip = auto_free(HenTooltip.new())

	add_child(tip)
	tip.visible = false

	return tip


func test_a_dwell_holds_the_tooltip_back_and_then_shows_it() -> void:
	var tip: HenTooltip = _tooltip()

	tip.go_to(Vector2.ZERO, 'doc', Vector2.ZERO, 0.08)

	assert_bool(tip.visible).is_false()

	await await_millis(220)

	assert_bool(tip.visible).is_true()


func test_closing_during_the_dwell_drops_the_tooltip() -> void:
	var tip: HenTooltip = _tooltip()

	tip.go_to(Vector2.ZERO, 'doc', Vector2.ZERO, 0.08)
	tip.close()

	await await_millis(220)

	assert_bool(tip.visible).is_false()


func test_a_second_hover_cancels_the_first_wait() -> void:
	var tip: HenTooltip = _tooltip()

	tip.go_to(Vector2.ZERO, 'first', Vector2.ZERO, 0.08)
	tip.go_to(Vector2.ZERO, 'second', Vector2.ZERO, 0.08)

	await await_millis(220)

	assert_bool(tip.visible).is_true()
	assert_str(tip.text).is_equal('second')


func test_no_dwell_shows_at_once() -> void:
	var tip: HenTooltip = _tooltip()

	tip.go_to(Vector2.ZERO, 'hint')

	assert_bool(tip.visible).is_true()
