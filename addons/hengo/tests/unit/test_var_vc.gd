extends GutTest


func test_get_var_code() -> void:
    var refs: HenSaveCodeType.References = HenSaveCodeType.References.new()
    var var_vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
        name = 'Get Variable',
        sub_type = HenVirtualCNode.SubType.VAR,
        outputs = [
            {
                name = 'var name',
                type = 'Variant',
            }
        ],
        route = HenTest.get_base_route()
    })

    assert_eq(
        HenTest.get_virtual_cnode_code(var_vc, refs).code,
        'var_name'
    )


func test_set_var_code() -> void:
    var refs: HenSaveCodeType.References = HenSaveCodeType.References.new()
    var var_vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
        name = 'Set Variable',
        sub_type = HenVirtualCNode.SubType.SET_VAR,
        inputs = [
            {
                name = 'var name',
                type = 'Vector2',
            }
        ],
        route = HenTest.get_base_route()
    })

    assert_eq(
        HenTest.get_virtual_cnode_code(var_vc, refs).code,
        'var_name = Vector2(0, 0)'
    )