extends GdUnitTestSuite


# Creates and returns a default expression node for testing
func _create_expression_node() -> HenVirtualCNode:
	return HenVirtualCNode.instantiate_virtual_cnode({
		type = HenVirtualCNode.Type.EXPRESSION,
		sub_type = HenVirtualCNode.SubType.EXPRESSION,
		name = 'Expression',
		inputs = [
			{
				name = '', type = 'Variant', sub_type = 'expression',
				category = 'default_value', code_value = 'null',
				value = 'a + b', is_static = true
			},
			{id = 0, name = 'a', type = 'Variant'},
			{id = 1, name = 'b', type = 'Variant'}
		],
		outputs = [ {id = 0, name = 'result', type = 'Variant'}],
		category = 'native',
		route = HenTest.get_base_route()
	})


# Tests an expression node with no connected inputs
func test_expression_with_no_inputs() -> void:
	var refs: HenSaveCodeType.References = HenSaveCodeType.References.new()
	var vc: HenVirtualCNode = _create_expression_node()
	
	# Inputs should default to null when not connected
	assert_str(HenTest.construct_and_get_code(vc, [], refs)).is_equal('null + null')


# Tests an expression with a single connected input
func test_expression_with_one_input() -> void:
	var refs: HenSaveCodeType.References = HenSaveCodeType.References.new()
	var vc: HenVirtualCNode = _create_expression_node()
	var value_node: HenVirtualCNode = HenTest.get_const()

	# The first input is connected to a constant value
	vc.get_new_input_connection_command(0, 0, value_node).add()
	assert_str(HenTest.construct_and_get_code(vc, [value_node], refs)).is_equal('Test.CONST + null')


# Tests an expression with all inputs connected
func test_expression_with_two_inputs() -> void:
	var refs: HenSaveCodeType.References = HenSaveCodeType.References.new()
	var vc: HenVirtualCNode = _create_expression_node()
	var value_node: HenVirtualCNode = HenTest.get_const()

	# Both inputs are connected to the same constant
	vc.get_new_input_connection_command(0, 0, value_node).add()
	vc.get_new_input_connection_command(1, 0, value_node).add()
	assert_str(HenTest.construct_and_get_code(vc, [value_node], refs)).is_equal('Test.CONST + Test.CONST')
