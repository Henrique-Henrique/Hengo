extends HenTestSuite


var var_data: HenSaveVar


func before_test() -> void:
	super ()
	var_data = save_data.add_var(false)
	var_data.name = 'test var'
	var_data.type = &'int'


func test_compound_add_to_int_with_get_var() -> void:
	var var_get_vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode(var_data.get_getter_cnode_data(''))
	var operator_vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'Add To',
		name_to_code = '+=',
		sub_type = HenVirtualCNode.SubType.OPERATOR,
		input_code_value_map = {'operator_type': 'compound', 'var_type': 'int'},
		inputs = [
			{id = 'var_ref', name = 'score', type = 'int'},
			{id = 'value', name = 'value', type = 'int'}
		],
		outputs = [],
		route = save_data.get_base_route()
	})
	var literal_vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'int',
		sub_type = HenVirtualCNode.SubType.LITERAL,
		inputs = [
			{id = 0, name = '', type = 'int', value = 5}
		],
		outputs = [
			{id = 0, name = 'value', type = 'int'}
		],
		route = save_data.get_base_route()
	})

	operator_vc.get_new_input_connection_command(StringName('var_ref'), StringName('0'), var_get_vc).add()
	operator_vc.get_new_input_connection_command(StringName('value'), StringName('0'), literal_vc).add()

	var expected_code = 'test_var += 5'
	assert_str(HenTest.get_vc_code(operator_vc)).is_equal(expected_code)


func test_binary_add_int() -> void:
	var operator_vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'Add',
		name_to_code = '+',
		sub_type = HenVirtualCNode.SubType.OPERATOR,
		input_code_value_map = {'operator_type': 'binary'},
		inputs = [
			{id = '0', name = 'a', type = 'int'},
			{id = '1', name = 'b', type = 'int'}
		],
		outputs = [
			{id = '0', name = 'result', type = 'int'}
		],
		route = save_data.get_base_route()
	})
	var literal_a: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'int',
		sub_type = HenVirtualCNode.SubType.LITERAL,
		inputs = [
			{id = 0, name = '', type = 'int', value = 3}
		],
		outputs = [
			{id = 0, name = 'value', type = 'int'}
		],
		route = save_data.get_base_route()
	})
	var literal_b: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'int',
		sub_type = HenVirtualCNode.SubType.LITERAL,
		inputs = [
			{id = 0, name = '', type = 'int', value = 5}
		],
		outputs = [
			{id = 0, name = 'value', type = 'int'}
		],
		route = save_data.get_base_route()
	})

	operator_vc.get_new_input_connection_command(StringName('0'), StringName('0'), literal_a).add()
	operator_vc.get_new_input_connection_command(StringName('1'), StringName('0'), literal_b).add()

	var expected_code = '3 + 5'
	assert_str(HenTest.get_vc_code(operator_vc)).is_equal(expected_code)


func test_unary_not() -> void:
	var operator_vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'NOT',
		name_to_code = '!',
		sub_type = HenVirtualCNode.SubType.OPERATOR,
		input_code_value_map = {'operator_type': 'unary'},
		inputs = [
			{id = '0', name = 'a', type = 'bool'}
		],
		outputs = [
			{id = '0', name = 'result', type = 'bool'}
		],
		route = save_data.get_base_route()
	})
	var literal_vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'bool',
		sub_type = HenVirtualCNode.SubType.LITERAL,
		inputs = [
			{id = 0, name = '', type = 'bool', value = true}
		],
		outputs = [
			{id = 0, name = 'value', type = 'bool'}
		],
		route = save_data.get_base_route()
	})

	operator_vc.get_new_input_connection_command(StringName('0'), StringName('0'), literal_vc).add()

	var expected_code = '!true'
	assert_str(HenTest.get_vc_code(operator_vc)).is_equal(expected_code)


func test_binary_bitwise_and() -> void:
	var operator_vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'Bitwise AND',
		name_to_code = '&',
		sub_type = HenVirtualCNode.SubType.OPERATOR,
		input_code_value_map = {'operator_type': 'binary'},
		inputs = [
			{id = '0', name = 'a', type = 'int'},
			{id = '1', name = 'b', type = 'int'}
		],
		outputs = [
			{id = '0', name = 'result', type = 'int'}
		],
		route = save_data.get_base_route()
	})
	var literal_a: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'int',
		sub_type = HenVirtualCNode.SubType.LITERAL,
		inputs = [
			{id = 0, name = '', type = 'int', value = 5}
		],
		outputs = [
			{id = 0, name = 'value', type = 'int'}
		],
		route = save_data.get_base_route()
	})
	var literal_b: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'int',
		sub_type = HenVirtualCNode.SubType.LITERAL,
		inputs = [
			{id = 0, name = '', type = 'int', value = 3}
		],
		outputs = [
			{id = 0, name = 'value', type = 'int'}
		],
		route = save_data.get_base_route()
	})

	operator_vc.get_new_input_connection_command(StringName('0'), StringName('0'), literal_a).add()
	operator_vc.get_new_input_connection_command(StringName('1'), StringName('0'), literal_b).add()

	var expected_code = '5 & 3'
	assert_str(HenTest.get_vc_code(operator_vc)).is_equal(expected_code)


func test_binary_logical_and() -> void:
	var operator_vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'Logical AND',
		name_to_code = '&&',
		sub_type = HenVirtualCNode.SubType.OPERATOR,
		input_code_value_map = {'operator_type': 'binary'},
		inputs = [
			{id = '0', name = 'a', type = 'bool'},
			{id = '1', name = 'b', type = 'bool'}
		],
		outputs = [
			{id = '0', name = 'result', type = 'bool'}
		],
		route = save_data.get_base_route()
	})
	var literal_a: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'bool',
		sub_type = HenVirtualCNode.SubType.LITERAL,
		inputs = [
			{id = 0, name = '', type = 'bool', value = true}
		],
		outputs = [
			{id = 0, name = 'value', type = 'bool'}
		],
		route = save_data.get_base_route()
	})
	var literal_b: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'bool',
		sub_type = HenVirtualCNode.SubType.LITERAL,
		inputs = [
			{id = 0, name = '', type = 'bool', value = false}
		],
		outputs = [
			{id = 0, name = 'value', type = 'bool'}
		],
		route = save_data.get_base_route()
	})

	operator_vc.get_new_input_connection_command(StringName('0'), StringName('0'), literal_a).add()
	operator_vc.get_new_input_connection_command(StringName('1'), StringName('0'), literal_b).add()

	var expected_code = 'true && false'
	assert_str(HenTest.get_vc_code(operator_vc)).is_equal(expected_code)