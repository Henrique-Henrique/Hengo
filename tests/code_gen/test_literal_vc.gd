extends HenTestSuite

var state: HenSaveState


func before_test() -> void:
	super ()
	state = save_data.add_state(false)


func test_literal_int() -> void:
	var vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'int',
		sub_type = HenVirtualCNode.SubType.LITERAL,
		inputs = [
			{id = 0, name = '', type = 'int', value = 42}
		],
		outputs = [
			{id = 0, name = 'value', type = 'int'}
		],
		route = save_data.get_base_route()
	})

	assert_str(HenTest.get_vc_code(vc)).is_equal('42')


func test_literal_string() -> void:
	var vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'String',
		sub_type = HenVirtualCNode.SubType.LITERAL,
		inputs = [
			{id = 0, name = '', type = 'String', value = 'hello'}
		],
		outputs = [
			{id = 0, name = 'value', type = 'String'}
		],
		route = save_data.get_base_route()
	})

	var actual_code = HenTest.get_vc_code(vc)
	assert_str(actual_code).is_equal("'hello'")


func test_literal_vector2() -> void:
	var vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'Vector2',
		sub_type = HenVirtualCNode.SubType.LITERAL,
		inputs = [
			{id = 0, name = 'x', type = 'float', value = 1.5},
			{id = 1, name = 'y', type = 'float', value = -2.5}
		],
		outputs = [
			{id = 0, name = 'value', type = 'Vector2'}
		],
		route = save_data.get_base_route()
	})

	assert_str(HenTest.get_vc_code(vc)).is_equal('Vector2(1.5, -2.5)')


func test_literal_color() -> void:
	var vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'Color',
		sub_type = HenVirtualCNode.SubType.LITERAL,
		inputs = [
			{id = 0, name = 'r', type = 'float', value = 1.0},
			{id = 1, name = 'g', type = 'float', value = 0.5},
			{id = 2, name = 'b', type = 'float', value = 0.25},
			{id = 3, name = 'a', type = 'float', value = 1.0}
		],
		outputs = [
			{id = 0, name = 'value', type = 'Color'}
		],
		route = save_data.get_base_route()
	})

	assert_str(HenTest.get_vc_code(vc)).is_equal('Color(1.0, 0.5, 0.25, 1.0)')
