@tool
class_name TestHenSearchRank extends HenTestSuite

# the one place the plugin turns typing into an ordered list: the palettes, the
# dashboard and the project search all rank through it


func _names(_found: Array) -> Array:
	return _found.map(func(_item: Dictionary) -> String: return _item.name)


func _items() -> Array:
	return [
		{name = 'auto_reload', kind = 1},
		{name = 'reload', kind = 1},
		{name = 'reload_weapon', kind = 1},
		{name = 'ammo', kind = 0, macro = 'Reload Gun'}
	]


func test_the_closest_name_comes_first() -> void:
	var found: Array = HenSearch.rank(_items(), 'reload', func(_item: Dictionary) -> String: return _item.name)

	assert_array(_names(found)).contains_exactly(['reload', 'reload_weapon', 'auto_reload'])


func test_a_secondary_field_matches_below_every_name() -> void:
	var found: Array = HenSearch.rank(_items(), 'reload', func(_item: Dictionary) -> String: return _item.name, {
		secondary_of = func(_item: Dictionary) -> String: return str(_item.get('macro', ''))
	})

	assert_array(_names(found)).contains_exactly(['reload', 'reload_weapon', 'auto_reload', 'ammo'])


func test_the_tie_breaker_orders_equal_scores() -> void:
	var items: Array = [{name = 'jump', kind = 1}, {name = 'jump', kind = 0}]
	var found: Array = HenSearch.rank(items, 'jump', func(_item: Dictionary) -> String: return _item.name, {
		tie_of = func(_item: Dictionary) -> int: return _item.kind
	})

	assert_int(found[0].kind).is_equal(0)


func test_a_blank_query_matches_nothing() -> void:
	assert_array(HenSearch.rank(_items(), '  ', func(_item: Dictionary) -> String: return _item.name)).is_empty()


func test_the_limit_keeps_the_best_ones() -> void:
	var found: Array = HenSearch.rank(_items(), 'reload', func(_item: Dictionary) -> String: return _item.name, {limit = 2})

	assert_array(_names(found)).contains_exactly(['reload', 'reload_weapon'])
