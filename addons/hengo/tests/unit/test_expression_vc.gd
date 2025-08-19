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
		HenTest.construct_and_get_code(vc, [], refs),
		'null + null'
	)
	
	var value: HenVirtualCNode = HenTest.get_const()

	vc.get_new_input_connection_command(0, 0, value).add()

	# test expression with input connection
	assert_eq(
		HenTest.construct_and_get_code(vc, [value], refs),
		'Test.CONST + null'
	)

	vc.get_new_input_connection_command(1, 0, value).add()

	# test expression with two connection
	assert_eq(
		HenTest.construct_and_get_code(vc, [value], refs),
		'Test.CONST + Test.CONST'
	)
