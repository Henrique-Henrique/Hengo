@tool
class_name TestHenStateViewerLayout extends GdUnitTestSuite


const PAD_TOP: float = HenStateViewerLayoutEngine.COMPOUND_PAD_TOP


func _node(_id: String, _children: Array) -> HenStateViewerGraphTypes.DirectedGraphNode:
	return HenStateViewerGraphTypes.DirectedGraphNode.new({
		id = _id,
		state_node = {},
		children = _children
	})


func test_tall_compound_header_pushes_its_children_down() -> void:
	var child: HenStateViewerGraphTypes.DirectedGraphNode = _node('root.parent.child', [])
	var parent: HenStateViewerGraphTypes.DirectedGraphNode = _node('root.parent', [child])
	var root: HenStateViewerGraphTypes.DirectedGraphNode = _node('root', [parent])

	var header: PanelContainer = auto_free(PanelContainer.new())
	header.custom_minimum_size = Vector2(200, PAD_TOP * 2.0)
	add_child(header)

	HenStateViewerUIMeasurer.new().calculate_rects(root, ThemeDB.fallback_font, 14, true, {parent: header})
	HenStateViewerLayoutEngine.new().execute_layout(root)

	assert_float(parent.layout.top_pad).is_greater(PAD_TOP)
	assert_float(child.layout.y).is_equal(parent.layout.top_pad)
	assert_float(child.layout.y - header.custom_minimum_size.y) \
		.is_equal(HenStateViewerLayoutEngine.COMPOUND_HEADER_GAP)


func test_short_compound_header_keeps_the_constant_pad() -> void:
	var child: HenStateViewerGraphTypes.DirectedGraphNode = _node('root.parent.child', [])
	var parent: HenStateViewerGraphTypes.DirectedGraphNode = _node('root.parent', [child])
	var root: HenStateViewerGraphTypes.DirectedGraphNode = _node('root', [parent])

	var header: PanelContainer = auto_free(PanelContainer.new())
	header.custom_minimum_size = Vector2(200, 40)
	add_child(header)

	HenStateViewerUIMeasurer.new().calculate_rects(root, ThemeDB.fallback_font, 14, true, {parent: header})
	HenStateViewerLayoutEngine.new().execute_layout(root)

	assert_float(child.layout.y).is_equal(PAD_TOP)
