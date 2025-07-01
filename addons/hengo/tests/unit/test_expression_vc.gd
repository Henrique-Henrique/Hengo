extends GutTest

func test_expression_code() -> void:
	var refs: HenSaveCodeType.References = HenSaveCodeType.References.new()
	var vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		type = HenVirtualCNode.Type.EXPRESSION,
		sub_type = HenVirtualCNode.SubType.EXPRESSION,
		name = 'Expression',
		inputs = [
			{
				name = '',
				type = 'Variant',
				sub_type = 'expression',
				category = 'default_value',
				code_value = 'null',
				value = 'a + b',
				is_static = true
			},
			{
				id = 0,
				name = 'a',
				type = 'Variant'
			},
			{
				id = 1,
				name = 'b',
				type = 'Variant'
			}
		],
		outputs = [
			{
				id = 0,
				name = 'result',
				type = 'Variant'
			}
		],
		category = 'native',
		route = HenTest.get_base_route()
	})

   	# test expression
	assert_eq(
		HenTest.get_virtual_cnode_code(vc, refs).code,
		'null + null'
	)
	
	var value: HenVirtualCNode = HenTest.get_const()

	# test expression with input connection
	assert_eq(
		HenTest.get_virtual_cnode_with_connections(vc, refs, [
			HenTest.CNodeConnection.new(vc, value),
		]),
		'Test.CONST + null'
	)

	# test expression with two connection
	assert_eq(
		HenTest.get_virtual_cnode_with_connections(vc, refs, [
			HenTest.CNodeConnection.new(vc, value),
			HenTest.CNodeConnection.new(vc, value, 1),
		]),
		'Test.CONST + Test.CONST'
	)
