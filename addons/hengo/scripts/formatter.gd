class_name HenFormatter extends Node

const DEBUG_FORMATTER = preload('res://debug_formatter.gd')
const Y_GAP = 250

class FormatterData:
	var x_layer: int = 0
	var X_LAYER_HEIGHT: Dictionary[StringName, Rect2] = {}
	var Y_LAYER_WIDTH: Dictionary[StringName, Rect2] = {}

static func format_virtual_cnode_list(_virtual_cnode_list: Array) -> void: # Array[HenVirtualCNode]
	var data: FormatterData = FormatterData.new()

	for vc: HenVirtualCNode in _virtual_cnode_list:
		if vc.identity.sub_type == HenVirtualCNode.SubType.VIRTUAL:
			start_navigation(vc, data)
			vc.set_position(Vector2.ZERO)
			break
		

static func start_navigation(_vc: HenVirtualCNode, _data: FormatterData) -> void:
	update_x_layer(_vc, _data)
	start_navigation_flow(_vc, _data)


static func start_navigation_flow(_vc: HenVirtualCNode, _data: FormatterData) -> void:
	_data.x_layer += 1

	if _vc.flow.flow_outputs.size() == 1:
		for connection: HenVCFlowConnectionData in _vc.flow.flow_connections_2:
			if connection.get_from() == _vc:
				start_navigation(connection.get_to(), _data)
				break


static func update_x_layer(_vc: HenVirtualCNode, _data: FormatterData) -> void:
	var rect: Rect2 = _data.X_LAYER_HEIGHT.get(str(_vc.identity.id), Rect2())
	_data.X_LAYER_HEIGHT[str(_vc.identity.id)] = rect.merge(Rect2(Vector2.ONE, _vc.visual.size))
	print(_data.X_LAYER_HEIGHT[str(_vc.identity.id)])
	var rect_2: Rect2 = _data.X_LAYER_HEIGHT[str(_vc.identity.id)]
	var pos: Vector2 = Vector2(rect_2.position.x, rect_2.position.y + (Y_GAP * _data.x_layer))

	_vc.set_position(pos)
	create_rect(pos, rect_2.size)


static func clean_rects() -> void:
	for rect in HenGlobal.HENGO_ROOT.get_node('%CommentContainer').get_children():
		if rect is ReferenceRect:
			rect.queue_free()
		
	
static func create_rect(_position: Vector2, _size: Vector2) -> void:
	var rect: ReferenceRect = ReferenceRect.new()
	rect.position = _position
	rect.size = _size
	rect.border_width = 4
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.process_mode = Control.PROCESS_MODE_DISABLED
	HenGlobal.HENGO_ROOT.get_node('%CommentContainer').add_child(rect)