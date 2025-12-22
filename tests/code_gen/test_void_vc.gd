extends GdUnitTestSuite

func test_void_code() -> void:
    var vc: HenVirtualCNode = HenTest.get_void()
    assert_str(HenVirtualCNodeCode.get_virtual_cnode_code(vc)).is_equal('test_void()')