extends GutTest


func test_if_code() -> void:
	var refs: HenSaveCodeType.References = HenSaveCodeType.References.new()
	var vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'IF',
		type = HenVirtualCNode.Type.IF,
		sub_type = HenVirtualCNode.SubType.IF,
		inputs = [
			{
				name = 'condition',
				type = 'bool'
			},
		],
		route = HenTest.get_base_route()
	})

	print(HenTest.get_virtual_cnode_code(vc, refs).code)

	var vc_flow_1: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'print',
		sub_type = HenVirtualCNode.SubType.VOID,
		category = 'native',
		inputs = [
			{
				name = 'content',
				type = 'Variant'
			}
		],
		route = HenTest.get_base_route()
	})

	var vc_flow_2: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'print',
		sub_type = HenVirtualCNode.SubType.VOID,
		category = 'native',
		inputs = [
			{
				name = 'content',
				type = 'Variant'
			}
		],
		route = HenTest.get_base_route()
	})

	print(
		HenTest.get_virtual_cnode_with_connections(vc, [
			HenTest.CNodeConnection.new(vc, vc_flow_1),
			HenTest.CNodeConnection.new(vc_flow_1, vc_flow_2),
		], refs)
	)


# func test_for_code() -> void:
# 	var vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
# 			id = 99,
# 			name = 'For -> Range',
# 			type = HenVirtualCNode.Type.FOR,
# 			sub_type = HenVirtualCNode.SubType.FOR,
# 			inputs = [
# 				{
# 					name = 'start',
# 					type = 'int'
# 				},
# 				{
# 					name = 'end',
# 					type = 'int'
# 				},
# 				{
# 					name = 'step',
# 					type = 'int'
# 				}
# 			],
# 			outputs = [
# 				{
# 					name = 'index',
# 					type = 'int'
# 				}
# 			],
# 			route = HenTest.get_base_route()
# 		})
# 	var refs: HenSaveCodeType.References = HenSaveCodeType.References.new()
# 	var data: HenSaveCodeType.CNode = HenCodeGeneration._get_cnode_from_dict(vc.get_save(), refs)

# 	var code: String = HenCodeGeneration.parse_token_by_type(
# 		data.get_for_token([])
# 	).trim_prefix('\n').trim_suffix('\n')

# 	assert_eq(code, 'for index_99 in range(0, 0, 0):\n\tpass')
