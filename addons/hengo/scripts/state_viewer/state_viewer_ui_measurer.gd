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
		_precalc_edge_widths(node, font)

	for child in node.children:
		calculate_rects(child, font, font_size, false, spawned_panels)

	if node.children.is_empty():
		_measure_leaf(node, font, font_size, spawned_panels)
	else:
		_measure_compound(node, font, font_size, spawned_panels)


func _precalc_edge_widths(root: HenStateViewerGraphTypes.DirectedGraphNode, font: Font) -> void:
	var all_edges: Array = []
	_collect_all_edges(root, all_edges)
	
	var groups: Dictionary = {}
	for e in all_edges:
		var pair: String = e.source.id + "::" + e.target.id
		if not groups.has(pair):
			groups[pair] = {source = e.source, target = e.target, edges = []}
		groups[pair].edges.append(e)
		
	for pair in groups:
		var group: Dictionary = groups[pair]
		var total_w: float = 0.0
		for e in group.edges:
			if e.label.text.is_empty():
				total_w += 32.0
			else:
				var label_size: Vector2 = font.get_string_size(e.label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14)
				total_w += max(32.0, label_size.x + 20.0)
		
		# ensure both the source and target node are wide enough to host these parallel edges
		_edge_widths[group.source.id] = max(_edge_widths.get(group.source.id, 0.0), total_w)
		_edge_widths[group.target.id] = max(_edge_widths.get(group.target.id, 0.0), total_w)


func _collect_all_edges(node: HenStateViewerGraphTypes.DirectedGraphNode, arr: Array) -> void:
	arr.append_array(node.edges)
	for child in node.children:
		_collect_all_edges(child, arr)


func _measure_leaf(node: HenStateViewerGraphTypes.DirectedGraphNode, font: Font, font_size: int, spawned_panels: Dictionary) -> void:
	var panel: Control = spawned_panels.get(node)
	if panel and panel is PanelContainer:
		var min_size: Vector2 = panel.get_combined_minimum_size()
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
	var layers: Dictionary = HenStateViewerLayoutEngine.group_by_depth(node.children)
	var depth_keys: Array = layers.keys()
	depth_keys.sort()

	var content_w: float = 0.0
	var content_h: float = 0.0

	for depth in depth_keys:
		var nodes_in_layer: Array = layers[depth]
		var max_h: float = 0.0
		var layer_w: float = 0.0

		for child in nodes_in_layer:
			max_h = max(max_h, child.layout.height)
			layer_w += child.layout.width
			
		layer_w += max(0, nodes_in_layer.size() - 1) * HenStateViewerLayoutEngine.NODE_GAP
		
		content_h += max_h
		content_w = max(content_w, layer_w)

	# add gap between layers vertically
	content_h += max(0, depth_keys.size() - 1) * HenStateViewerLayoutEngine.LAYER_GAP

	var header_min_h: float = 0.0
	var header_min_w: float = 0.0
	var panel: Control = spawned_panels.get(node)
	if panel and panel is PanelContainer:
		var h_size: Vector2 = panel.get_combined_minimum_size()
		header_min_w = h_size.x
		header_min_h = h_size.y

	if header_min_w > 0:
		node.layout.width = max(content_w + HenStateViewerLayoutEngine.COMPOUND_PAD_SIDE * 2.0, header_min_w)
	else:
		var short_id: String = node.id.get_slice('.', node.id.get_slice_count('.') - 1)
		var label_size: Vector2 = font.get_string_size(short_id, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		node.layout.width = max(content_w + HenStateViewerLayoutEngine.COMPOUND_PAD_SIDE * 2.0, label_size.x + HenStateViewerLayoutEngine.COMPOUND_PAD_SIDE * 2.0 + 20.0)

	var top_pad: float = max(HenStateViewerLayoutEngine.COMPOUND_PAD_TOP, header_min_h + 4.0)
	node.layout.height = content_h + top_pad + HenStateViewerLayoutEngine.COMPOUND_PAD_BOTTOM
	
	var req_w: float = _edge_widths.get(node.id, 0.0)
	node.layout.width = max(node.layout.width, req_w)
