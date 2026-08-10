@tool
class_name TestHenStateViewerLayout extends GdUnitTestSuite


const PAD_TOP: float = HenStateViewerLayoutEngine.COMPOUND_PAD_TOP


# the measurer only asks a panel for compute_size, so a header of a given size is
# all these cases need
class HeaderStub extends RefCounted:
	var size: Vector2


	func compute_size() -> Vector2:
		return size


func _node(_id: String, _children: Array) -> HenStateViewerGraphTypes.DirectedGraphNode:
	return HenStateViewerGraphTypes.DirectedGraphNode.new({
		id = _id,
		state_node = {},
		children = _children
	})


func _header(_size: Vector2) -> HeaderStub:
	var stub: HeaderStub = HeaderStub.new()
	stub.size = _size

	return stub


func _layout(_header_size: Vector2) -> Dictionary:
	var child: HenStateViewerGraphTypes.DirectedGraphNode = _node('root.parent.child', [])
	var parent: HenStateViewerGraphTypes.DirectedGraphNode = _node('root.parent', [child])
	var root: HenStateViewerGraphTypes.DirectedGraphNode = _node('root', [parent])

	HenStateViewerUIMeasurer.new().calculate_rects(root, ThemeDB.fallback_font, 14, true, {parent: _header(_header_size)})
	HenStateViewerLayoutEngine.new().execute_layout(root)

	return {child = child, parent = parent}


func test_tall_compound_header_pushes_its_children_down() -> void:
	var header_h: float = PAD_TOP * 2.0
	var laid: Dictionary = _layout(Vector2(200, header_h))

	assert_float(laid.parent.layout.top_pad).is_greater(PAD_TOP)
	assert_float(laid.child.layout.y).is_equal(laid.parent.layout.top_pad)
	assert_float(laid.child.layout.y - header_h) \
		.is_equal(HenStateViewerLayoutEngine.COMPOUND_HEADER_GAP)


func test_short_compound_header_keeps_the_constant_pad() -> void:
	var laid: Dictionary = _layout(Vector2(200, 40))

	assert_float(laid.child.layout.y).is_equal(PAD_TOP)
