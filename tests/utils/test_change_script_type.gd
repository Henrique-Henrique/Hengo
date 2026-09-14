extends HenActionTestSuite

const FIX_PICK: String = 'res://addons/hengo/actions/input/pick_under_mouse_2d.gd'


func _popup() -> HenChangeScriptType:
	var popup: HenChangeScriptType = (load('res://addons/hengo/scenes/utils/change_script_type.tscn') as PackedScene).instantiate()

	popup.setup(save_data)
	add_child(popup)
	auto_free(popup)

	return popup


func test_it_shows_the_current_base() -> void:
	var popup: HenChangeScriptType = _popup()

	assert_str(popup.current_label.text).is_equal('Test extends Sprite2D')
	assert_bool(popup.apply_bt.disabled).is_true()


func test_a_base_that_breaks_actions_lists_them_and_still_allows_the_change() -> void:
	_add_action(_register(FIX_PICK), &'physics')

	var popup: HenChangeScriptType = _popup()

	popup.extend_bt.value_changed.emit('Node3D')

	assert_str(popup.report_label.text).contains('1 action(s) stop working on Node3D')
	assert_str(popup.apply_bt.text).is_equal('Change Anyway')
	assert_bool(popup.apply_bt.disabled).is_false()


func test_a_compatible_base_reports_nothing_broken() -> void:
	_add_action(_register(FIX_PICK), &'physics')

	var popup: HenChangeScriptType = _popup()

	popup.extend_bt.value_changed.emit('AnimatedSprite2D')

	assert_str(popup.report_label.text).contains('Every action still works')
	assert_str(popup.apply_bt.text).is_equal('Change')
	assert_bool(popup.apply_bt.disabled).is_false()


func test_a_class_that_is_not_a_node_cannot_be_picked() -> void:
	var popup: HenChangeScriptType = _popup()

	popup.extend_bt.value_changed.emit('Resource')

	assert_str(popup.report_label.text).contains('is not a node')
	assert_bool(popup.apply_bt.disabled).is_true()


func test_the_same_base_cannot_be_picked_again() -> void:
	var popup: HenChangeScriptType = _popup()

	popup.extend_bt.value_changed.emit('Sprite2D')

	assert_bool(popup.apply_bt.disabled).is_true()
