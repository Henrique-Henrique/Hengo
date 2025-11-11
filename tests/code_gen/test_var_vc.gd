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


func test_deep_prop_code() -> void:
    var refs: HenTypeReferences = HenTypeReferences.new()
    var vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
        name = 'Get Property',
        name_to_code = 'position.x',
        sub_type = HenVirtualCNode.SubType.DEEP_PROP,
        outputs = [
            {
                name = 'position -> x',
                type = 'float',
            }
        ],
        route = HenTest.get_base_route()
    })

    assert_str(HenTest.construct_and_get_code(vc, [], refs)).is_equal('position.x')


func test_set_deep_prop_code() -> void:
    var refs: HenTypeReferences = HenTypeReferences.new()
    var vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
        name = 'Set Property',
        sub_type = HenVirtualCNode.SubType.SET_DEEP_PROP,
        name_to_code = 'position.x',
        inputs = [
            {
                id = 0,
                name = 'Sprite2D',
                type = 'Sprite2D',
                is_ref = true
            },
            {
                id = 1,
                name = 'position -> x',
                type = 'float',
            }
        ],
        route = HenTest.get_base_route(),
    })

    assert_str(HenTest.construct_and_get_code(vc, [], refs)).is_equal('position.x = 0.')