extends GutTest


func test_vcnode_instantiation() -> void:
	var vc = HenVirtualCNode.instantiate_virtual_cnode({
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
	
	assert_true(vc is HenVirtualCNode)