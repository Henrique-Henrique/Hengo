extends GdUnitTestSuite

func test_void_code() -> void:
    var refs: HenSaveCodeType.References = HenSaveCodeType.References.new()
    var vc: HenVirtualCNode = HenTest.get_void()

    assert_str(HenTest.construct_and_get_code(vc, [], refs)).is_equal(
        'test_void()'
    )