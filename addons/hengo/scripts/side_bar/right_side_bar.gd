@tool
class_name HenRightSideBar extends MarginContainer

@onready var elements_tree: Tree = %Elements

var timer: SceneTreeTimer
 
func _ready() -> void:
	custom_minimum_size = Vector2(HenUtils.get_scaled_size(250), 0)
	var margin: int = HenUtils.get_scaled_size(8)
	add_theme_constant_override('margin_left', margin)
	add_theme_constant_override('margin_right', margin)
	add_theme_constant_override('margin_top', margin)
	add_theme_constant_override('margin_bottom', margin)
	elements_tree.item_selected.connect(_on_tree_item_selected)


func clear() -> void:
	elements_tree.clear()


func update(_route: HenRouteData) -> void:
	if not _route:
		clear()
		return
	
	if timer:
		timer.timeout.disconnect(update_elements.bind(_route))
		timer = null
	
	timer = get_tree().create_timer(0.1)
	timer.timeout.connect(update_elements.bind(_route))


func update_elements(_route: HenRouteData) -> void:
	elements_tree.clear()
	
	var root: TreeItem = elements_tree.create_item()
	var vc_root_arr: Array = []

	for item: HenVirtualCNode in _route.virtual_cnode_list:
		if HenUtils.is_circular_dependent(item.sub_type) \
		or item.sub_type == HenVirtualCNode.SubType.STATE_START \
		or item.sub_type == HenVirtualCNode.SubType.OVERRIDE_VIRTUAL \
		or item.sub_type == HenVirtualCNode.SubType.VIRTUAL:
			vc_root_arr.append(item)
	
	for item: HenVirtualCNode in vc_root_arr:
		update_vc_tree(item, root)
	

func update_vc_tree(_vc: HenVirtualCNode, _parent: TreeItem = null, _flow_head: TreeItem = null, _color: Variant = null) -> void:
	var root: TreeItem
	if _flow_head:
		root = elements_tree.create_item(_flow_head)
	else:
		root = elements_tree.create_item(_parent)
		_flow_head = root

	root.set_text(0, _vc.name)
	root.set_icon(0, HenUtils.get_icon_for_subtype(_vc.sub_type))
	root.set_icon_modulate(0, HenUtils.get_color_for_subtype(_vc.sub_type))
	root.set_metadata(0, _vc)
	
	if _color is Color:
		root.set_custom_bg_color(0, _color)

	var global: HenGlobal = Engine.get_singleton(&'Global')
	var outgoing_nodes: Array[Dictionary] = []
	for flow_connection: HenVCFlowConnectionData in global.SAVE_DATA.get_flow_connection_from_vc(_vc):
		var from: HenVirtualCNode = flow_connection.get_from()
		if from != _vc:
			continue
		
		var to: HenVirtualCNode = flow_connection.get_to()
		if to:
			var output_index: int = 0
			for i: int in range(_vc.flow_outputs.size()):
				if _vc.flow_outputs[i].id == flow_connection.from_id:
					output_index = i
					break
			
			outgoing_nodes.append({node = to, index = output_index})
	
	outgoing_nodes.sort_custom(func(a, b): return a.index < b.index)

	var is_branching: bool = _vc.flow_outputs.size() > 1
	var has_multiple_outputs: bool = _vc.flow_outputs.size() > 1
	
	for data in outgoing_nodes:
		var next_color: Variant = _color
		
		if is_branching or outgoing_nodes.size() > 1:
			if has_multiple_outputs:
				next_color = HenEnums.FLOW_COLORS[data.index % HenEnums.FLOW_COLORS.size()]
			
			update_vc_tree(data.node, root, null, next_color)
		else:
			if next_color is Color:
				next_color.a = 0.05
			update_vc_tree(data.node, root, _flow_head, next_color)


func _on_tree_item_selected() -> void:
	var selected: TreeItem = elements_tree.get_selected()
	if not selected:
		return
	
	var vc: HenVirtualCNode = selected.get_metadata(0)
	if vc and is_instance_valid(vc):
		var global: HenGlobal = Engine.get_singleton(&'Global')
		for _vc: HenVirtualCNode in global.SELECTED_VIRTUAL_CNODE.duplicate():
			_vc.unselect()

		vc.select()
		if global.CAM:
			global.CAM.go_to_center(vc.position)
