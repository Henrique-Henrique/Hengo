extends HenTestSuite


func _row() -> HenScriptTabRow:
	var row: HenScriptTabRow = HenScriptTabRow.new()

	add_child(row)
	auto_free(row)
	# the type icon comes from the editor theme, which a headless run does not have
	save_data.identity.type = &''
	row.setup(save_data)

	return row


func _click(_row_node: HenScriptTabRow, _button: MouseButton) -> void:
	var event: InputEventMouseButton = InputEventMouseButton.new()

	event.button_index = _button
	event.pressed = true
	_row_node._on_gui_input(event)


func test_right_click_asks_for_the_menu() -> void:
	var row: HenScriptTabRow = _row()
	var asked: Array = []

	row.menu_request.connect(func(_data: HenSaveData, _source: Control) -> void: asked.append([_data, _source]))
	_click(row, MOUSE_BUTTON_RIGHT)

	assert_int(asked.size()).is_equal(1)
	assert_object(asked[0][0]).is_same(save_data)
	assert_object(asked[0][1]).is_same(row)


func test_right_click_still_asks_for_the_menu_when_collapsed() -> void:
	var row: HenScriptTabRow = _row()
	var asked: Array = []

	row.set_collapsed(true)
	row.menu_request.connect(func(_data: HenSaveData, _source: Control) -> void: asked.append(_data))
	_click(row, MOUSE_BUTTON_RIGHT)

	assert_int(asked.size()).is_equal(1)


func test_left_click_selects_without_the_menu() -> void:
	var row: HenScriptTabRow = _row()
	var asked: Array = []
	var pressed: Array = []

	row.menu_request.connect(func(_data: HenSaveData, _source: Control) -> void: asked.append(_data))
	row.pressed.connect(func(_data: HenSaveData) -> void: pressed.append(_data))
	_click(row, MOUSE_BUTTON_LEFT)

	assert_int(pressed.size()).is_equal(1)
	assert_array(asked).is_empty()


func test_the_menu_button_stays_hidden_while_collapsed() -> void:
	var row: HenScriptTabRow = _row()

	row.set_collapsed(true)
	row._apply_actions_visible(true)

	assert_bool(row._menu_bt.visible).is_false()


func test_the_menu_lists_the_script_options() -> void:
	var tabs: HenTabs = HenTabs.new()
	var names: Array = tabs.menu_entries(save_data, null).map(func(entry: Dictionary) -> String: return str(entry.name))

	auto_free(tabs)

	assert_array(names).contains_exactly(['Change Base Type', 'Delete Script'])
