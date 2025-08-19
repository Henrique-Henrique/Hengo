extends GutTest


func test_void_code() -> void:
    var refs: HenSaveCodeType.References = HenSaveCodeType.References.new()
    var vc: HenVirtualCNode = HenTest.get_void()

    assert_eq(
        HenTest.construct_and_get_code(vc, [], refs),
        'test_void()'
    )