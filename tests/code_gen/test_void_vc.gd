extends HenTestSuite

func test_void_code() -> void:
    var vc: HenVirtualCNode = HenTest.get_void()
    assert_str(HenTest.get_vc_code(vc)).is_equal('test_void()')