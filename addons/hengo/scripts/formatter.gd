class_name HenFormatter extends Node

const Y_GAP = 250


class FormatterData:
	var x_limit: float = 0.
	var list: Array[HenVirtualCNode] = []
	var vc_map: Dictionary = {}


class VCFormatData:
	var format_center: bool = false
	var format_to_parent: HenVirtualCNode
	var moved: bool = false
	var flow_connection_list: Array[HenVCFlowConnectionData] = []


static func format_virtual_cnode_list(_virtual_cnode_list: Array) -> void: # Array[HenVirtualCNode]
	var data: FormatterData = FormatterData.new()

	for vc: HenVirtualCNode in _virtual_cnode_list:
		if vc.identity.sub_type == HenVirtualCNode.SubType.VIRTUAL:
			start_map(vc, data)

	data.list.reverse()

	for vc: HenVirtualCNode in data.list:
		print(vc.identity.id)
		var vc_format_data: VCFormatData = data.vc_map[vc.identity.id]
		if vc_format_data.moved:
			continue
		if vc_format_data.format_to_parent:
			vc.set_position(Vector2(vc_format_data.format_to_parent.visual.position.x, vc.visual.position.y))
			continue
		if vc_format_data.flow_connection_list.size() > 2:
			if vc_format_data.flow_connection_list.size() % 2 != 0:
				var middle_connection: HenVCFlowConnectionData = vc_format_data.flow_connection_list[int(vc_format_data.flow_connection_list.size() / 2.)]
				vc.set_position(Vector2(middle_connection.get_to().visual.position.x, vc.visual.position.y))
			else:
				var limit_left: float = INF
				var limit_right: float = - INF

				for flow_connection: HenVCFlowConnectionData in vc_format_data.flow_connection_list:
					limit_left = min(limit_left, flow_connection.get_to().visual.position.x)
					limit_right = max(limit_right, flow_connection.get_to().visual.position.x)

				vc.set_position(Vector2((limit_left + limit_right) / 2., vc.visual.position.y))
		elif vc_format_data.format_center:
			var flow_connection: HenVCFlowConnectionData = vc.get_flow_output_connection(vc.flow.flow_inputs[0].id)
			vc.set_position(Vector2(flow_connection.get_to().visual.position.x, vc.visual.position.y))
		else:
			vc.set_position(Vector2(data.x_limit - vc.visual.size.x, vc.visual.position.y))
			data.x_limit = min(data.x_limit, vc.visual.position.x)
		
		vc_format_data.moved = true


static func start_map(_vc: HenVirtualCNode, _data: FormatterData) -> void:
	var vc_format_data: VCFormatData = VCFormatData.new()
	_data.vc_map[_vc.identity.id] = vc_format_data
	_data.list.append(_vc)
	_vc.visual.position.x = 0
	for flow: HenVCFlow in _vc.flow.flow_outputs:
		var flow_connection: HenVCFlowConnectionData = _vc.get_flow_output_connection(flow.id)
		if flow_connection:
			vc_format_data.flow_connection_list.append(flow_connection)

	if _vc.flow.flow_outputs.size() == 1 and vc_format_data.flow_connection_list.size() == 1:
		vc_format_data.format_center = true

	var idx = 0
	for flow_connection: HenVCFlowConnectionData in vc_format_data.flow_connection_list:
		if idx == 1:
			if vc_format_data.flow_connection_list.size() == 2:
				_data.list.append(_vc)
		start_map(flow_connection.get_to(), _data)
		idx += 1
	
	if _vc.flow.flow_outputs.size() > 1:
		if vc_format_data.flow_connection_list.size() == 1:
			if vc_format_data.flow_connection_list[0].from_id == _vc.flow.flow_outputs[0].id:
				_data.list.append(_vc)
			elif vc_format_data.flow_connection_list[0].from_id == _vc.flow.flow_outputs[-1].id:
				pass
			else:
				_data.list.append(_vc)
				_data.vc_map[vc_format_data.flow_connection_list[0].get_to().identity.id].format_to_parent = _vc