@tool
class_name TestHenDropDownMenu extends HenTestSuite

# the select every picker in the plugin is built on: it opens focused, and typing
# plus enter is enough to choose without ever reaching for the mouse


const MENU_SCENE: String = 'res://addons/hengo/scenes/drop_down_menu.tscn'

var picked: Array = []


func _menu(_items: Array = [{name = 'health'}, {name = 'speed'}, {name = 'shield'}]) -> HenDropDownMenu:
	var menu: HenDropDownMenu = auto_free((load(MENU_SCENE) as PackedScene).instantiate())

	add_child(menu)
	picked = []
	menu.mount(_items, func(_item: Dictionary) -> void: picked.append(_item), 'item_type')

	return menu


func _search(_menu: HenDropDownMenu, _query: String) -> void:
	_menu.search_bar.text = _query
	_menu._on_search(_query)


func _key(_code: Key) -> InputEventKey:
	var event: InputEventKey = InputEventKey.new()

	event.keycode = _code
	event.pressed = true

	return event


# grab_focus is deferred, because the popup that hosts the menu also places itself
# deferred and focus taken on the frame it jumps is dropped
func test_the_search_field_opens_focused() -> void:
	var menu: HenDropDownMenu = _menu()

	await await_idle_frame()

	assert_bool(menu.search_bar.has_focus()).is_true()


func test_enter_takes_the_only_match() -> void:
	var menu: HenDropDownMenu = _menu()

	_search(menu, 'shi')
	menu._on_search_input(_key(KEY_ENTER))

	assert_int(picked.size()).is_equal(1)
	assert_str(str(picked[0].name)).is_equal('shield')


func test_enter_takes_the_top_match_when_several_survive() -> void:
	var menu: HenDropDownMenu = _menu([{name = 'speed'}, {name = 'speed_max'}])

	_search(menu, 'speed')
	menu._on_search_input(_key(KEY_ENTER))

	assert_str(str(picked[0].name)).is_equal('speed')


func test_enter_on_an_empty_result_picks_nothing() -> void:
	var menu: HenDropDownMenu = _menu()

	_search(menu, 'nothing matches this')
	menu._on_search_input(_key(KEY_ENTER))

	assert_array(picked).is_empty()


# the field opens focused, so enter is reachable before anything has been read. the
# bind picker opens on "None (literal)", and taking it would drop a bound value
func test_enter_before_typing_picks_nothing() -> void:
	var menu: HenDropDownMenu = _menu([{name = 'None (literal)'}, {name = 'health'}])

	menu._on_search_input(_key(KEY_ENTER))

	assert_array(picked).is_empty()


func test_down_hands_the_arrows_to_the_list() -> void:
	var menu: HenDropDownMenu = _menu()

	menu._on_search_input(_key(KEY_DOWN))

	assert_bool(menu.list_container.is_selected(0)).is_true()
	assert_array(picked).is_empty()


# ItemList fires item_activated on its own when enter is pressed with the list
# focused, so the arrow-down handoff is only a dead end if this is unwired
func test_the_list_picks_what_it_activates() -> void:
	var menu: HenDropDownMenu = _menu()

	assert_bool(menu.list_container.item_activated.is_connected(menu._pick)).is_true()

	menu.list_container.item_activated.emit(2)

	assert_str(str(picked[0].name)).is_equal('shield')


func test_a_click_still_picks() -> void:
	var menu: HenDropDownMenu = _menu()

	menu._on_item_click(1, Vector2.ZERO, MOUSE_BUTTON_LEFT)

	assert_str(str(picked[0].name)).is_equal('speed')


func test_a_right_click_picks_nothing() -> void:
	var menu: HenDropDownMenu = _menu()

	menu._on_item_click(1, Vector2.ZERO, MOUSE_BUTTON_RIGHT)

	assert_array(picked).is_empty()


# the callable is dropped once it fires, and a second pick would call a null one
func test_picking_twice_only_counts_once() -> void:
	var menu: HenDropDownMenu = _menu()

	menu._pick(0)
	menu._pick(1)

	assert_int(picked.size()).is_equal(1)
