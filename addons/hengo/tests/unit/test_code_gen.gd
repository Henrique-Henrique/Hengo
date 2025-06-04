extends GutTest


func test_if_code() -> void:
	var vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		id = 0,
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
	var refs: HenSaveCodeType.References = HenSaveCodeType.References.new()
	var data: HenSaveCodeType.CNode = HenCodeGeneration._get_cnode_from_dict(vc.get_save(), refs)

	var code: String = HenCodeGeneration.parse_token_by_type(
		data.get_if_token([])
	).trim_prefix('\n').trim_suffix('\n')

	assert_eq(code, 'if false:\n\tpass')

	var vc_flow_1: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		id = 1,
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

	vc.add_flow_connection(0, 0, vc_flow_1).add()

	var data_flow_1: HenSaveCodeType.CNode = HenCodeGeneration._get_cnode_from_dict(vc.get_save(), refs)
	HenCodeGeneration._get_cnode_from_dict(vc_flow_1.get_save(), refs)

	HenCodeGeneration._parse_connections(refs)

	var code_flow_1: String = ''

	for token in data_flow_1.get_flow_tokens(0):
		code_flow_1 += HenCodeGeneration.parse_token_by_type(token)

	code_flow_1 = code_flow_1.trim_prefix('\n').trim_suffix('\n\n')

	assert_eq(code_flow_1, 'if false:\n\tprint(null)')


func test_for_code() -> void:
	var vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
			id = 99,
			name = 'For -> Range',
			type = HenVirtualCNode.Type.FOR,
			sub_type = HenVirtualCNode.SubType.FOR,
			inputs = [
				{
					name = 'start',
					type = 'int'
				},
				{
					name = 'end',
					type = 'int'
				},
				{
					name = 'step',
					type = 'int'
				}
			],
			outputs = [
				{
					name = 'index',
					type = 'int'
				}
			],
			route = HenTest.get_base_route()
		})
	var refs: HenSaveCodeType.References = HenSaveCodeType.References.new()
	var data: HenSaveCodeType.CNode = HenCodeGeneration._get_cnode_from_dict(vc.get_save(), refs)

	var code: String = HenCodeGeneration.parse_token_by_type(
		data.get_for_token([])
	).trim_prefix('\n').trim_suffix('\n')

	assert_eq(code, 'for index_99 in range(0, 0, 0):\n\tpass')
