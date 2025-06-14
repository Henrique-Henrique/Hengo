extends GutTest


func test_void_code() -> void:
    var refs: HenSaveCodeType.References = HenSaveCodeType.References.new()
    var vc: HenVirtualCNode = HenTest.get_void()

    assert_eq(
        HenTest.get_virtual_cnode_code(vc, refs).code,
        'test_void()'
    )