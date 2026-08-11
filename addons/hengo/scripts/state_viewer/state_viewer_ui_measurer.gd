@tool
class_name HenStateViewerUIMeasurer
extends RefCounted

const LEAF_MIN_W: float = 80.0
const LEAF_MIN_H: float = 48.0


var _edge_widths: Dictionary = {}

# bottom-up measurement: children first, then parent wraps them
func calculate_rects(node: HenStateViewerGraphTypes.DirectedGraphNode, font: Font, font_size: int, is_root: bool = true, spawned_panels: Dictionary = {}) -> void:
	if is_root:
		_edge_widths.clear()
		_precalc_edge_widths(node)

	for child in node.children:
		calculate_rects(child, font, font_size, false, spawned_panels)

	if node.children.is_empty():
		_measure_leaf(node, font, font_size, spawned_panels)
	else:
		_measure_compound(node, font, font_size, spawned_panels)


func _precalc_edge_widths(root: HenStateViewerGraphTypes.DirectedGraphNode) -> void:
	var all_edges: Array = []
	_collect_all_edges(root, all_edges)
	
	var groups: Dictionary = {}
	for e in all_edges:
		# cross-machine edges ride corridors, not node-hosted lanes, so they reserve no width
		if _top_machine(e.source, root) != _top_machine(e.target, root):
			continue

		var pair: String = e.source.id + "::" + e.target.id
		if not groups.has(pair):
			groups[pair] = {source = e.source, target = e.target, edges = []}
		groups[pair].edges.append(e)
		
	for pair in groups:
		var group: Dictionary = groups[pair]
		var total_w: float = 0.0
		for e in group.edges:
			var label_text: String = e.display_label()

			if label_text.is_empty():
				total_w += 32.0
			else:
				# the reserved lane has to fit the whole pill, icon included
				var pill_w: float = HenStateEdgePill.measure(label_text, not str(e.meta.get('icon', '')).is_empty()).x
				total_w += max(32.0, pill_w + 6.0)
		
		# ensure both the source and target node are wide enough to host these parallel edges
		_edge_widths[group.source.id] = max(_edge_widths.get(group.source.id, 0.0), total_w)
		_edge_widths[group.target.id] = max(_edge_widths.get(group.target.id, 0.0), total_w)


func _collect_all_edges(node: HenStateViewerGraphTypes.DirectedGraphNode, arr: Array) -> void:
	arr.append_array(node.edges)
	for child in node.children:
		_collect_all_edges(child, arr)


# walks up to the ancestor that is a direct child of root
static func _top_machine(node: HenStateViewerGraphTypes.DirectedGraphNode, root: HenStateViewerGraphTypes.DirectedGraphNode) -> HenStateViewerGraphTypes.DirectedGraphNode:
	var current: HenStateViewerGraphTypes.DirectedGraphNode = node
	while current != null and current.parent != null and current.parent != root:
		current = current.parent
	return current


# a card computes its size from font metrics, so one pass is already final. the
# contract is compute_size, not the card type, so a stub can drive the layout
static func _panel_min_size(panel: Variant) -> Vector2:
	if panel and panel.has_method(&'compute_size'):
		return panel.compute_size()

	return Vector2.ZERO


func _measure_leaf(node: HenStateViewerGraphTypes.DirectedGraphNode, font: Font, font_size: int, spawned_panels: Dictionary) -> void:
	var panel: Variant = spawned_panels.get(node)
	var min_size: Vector2 = _panel_min_size(panel)

	if min_size != Vector2.ZERO:
		node.layout.width = max(LEAF_MIN_W, min_size.x)
		node.layout.height = max(LEAF_MIN_H, min_size.y)
	else:
		var short_id: String = node.id.get_slice('.', node.id.get_slice_count('.') - 1)
		var text_size: Vector2 = font.get_string_size(short_id, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		node.layout.width = max(LEAF_MIN_W, text_size.x + 16.0)
		node.layout.height = max(LEAF_MIN_H, text_size.y + 12.0)
	
	var req_w: float = _edge_widths.get(node.id, 0.0)
	node.layout.width = max(node.layout.width, req_w)


func _measure_compound(node: HenStateViewerGraphTypes.DirectedGraphNode, font: Font, font_size: int, spawned_panels: Dictionary) -> void:
	# same plan the layout engine places against, or the parent stops wrapping it
	var plan: Dictionary = HenStateViewerLayoutEngine.plan_bands(node.children)
	var content_w: float = plan.content.x
	var content_h: float = plan.content.y

	var h_size: Vector2 = _panel_min_size(spawned_panels.get(node))
	var header_min_w: float = h_size.x
	var header_min_h: float = h_size.y

	if header_min_w > 0:
		node.layout.width = max(content_w + HenStateViewerLayoutEngine.COMPOUND_PAD_SIDE * 2.0, header_min_w)
	else:
		var short_id: String = node.id.get_slice('.', node.id.get_slice_count('.') - 1)
		var label_size: Vector2 = font.get_string_size(short_id, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		node.layout.width = max(content_w + HenStateViewerLayoutEngine.COMPOUND_PAD_SIDE * 2.0, label_size.x + HenStateViewerLayoutEngine.COMPOUND_PAD_SIDE * 2.0 + 20.0)

	var top_pad: float = max(
		HenStateViewerLayoutEngine.COMPOUND_PAD_TOP,
		header_min_h + HenStateViewerLayoutEngine.COMPOUND_HEADER_GAP
	)
	node.layout.top_pad = top_pad
	node.layout.height = content_h + top_pad + HenStateViewerLayoutEngine.COMPOUND_PAD_BOTTOM
	
	var req_w: float = _edge_widths.get(node.id, 0.0)
	node.layout.width = max(node.layout.width, req_w)
