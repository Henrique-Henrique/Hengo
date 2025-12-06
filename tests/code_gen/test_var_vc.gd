extends GdUnitTestSuite


func test_get_var_code() -> void:
    var refs: HenTypeReferences = HenTypeReferences.new()
    var var_vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
        name = 'Get HenTypeVariable',
        sub_type = HenVirtualCNode.SubType.VAR,
        outputs = [
            {
                name = 'var name',
                type = 'Variant',
            }
        ],
        route = HenTest.get_base_route()
    })

    assert_str(HenTest.construct_and_get_code(var_vc, [], refs)).is_equal('var_name')


func test_set_var_code() -> void:
    var refs: HenTypeReferences = HenTypeReferences.new()
    var var_vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
        name = 'Set HenTypeVariable',
        sub_type = HenVirtualCNode.SubType.SET_VAR,
        inputs = [
            {
                name = 'var name',
                type = 'Vector2',
            }
        ],
        route = HenTest.get_base_route()
    })

    assert_str(HenTest.construct_and_get_code(var_vc, [], refs)).is_equal('var_name = Vector2(0, 0)')
