@tool
class_name TestHenClipboard extends HenTestSuite


class MockCam extends HenCam:
	func _ready() -> void:
		pass
		
	func get_rect() -> Rect2:
		return Rect2(0, 0, 1920, 1080)

func before_test() -> void:
	super ()
	var global: HenGlobal = Engine.get_singleton('Global')
	global.CAM = MockCam.new()

func after_test() -> void:
	var global: HenGlobal = Engine.get_singleton('Global')
	if global.CAM:
		global.CAM.free()
	super ()


# tests copy and paste functionality for all subtypes
func test_copy_paste_all_subtypes() -> void:
	var sub_types = HenVirtualCNode.SubType.values()
	var global: HenGlobal = Engine.get_singleton('Global')
	
	for sub_type in sub_types:
		if sub_type == HenVirtualCNode.SubType.INVALID:
			continue
			
		var node_config = {
			'name': 'TestNode_' + str(sub_type),
			'sub_type': sub_type,
			'route': save_data.get_base_route(),
			'position': Vector2(100, 200)
		}
		
		match sub_type:
			HenVirtualCNode.SubType.IF:
				node_config['type'] = HenVirtualCNode.Type.IF
			HenVirtualCNode.SubType.FOR:
				node_config['type'] = HenVirtualCNode.Type.FOR
			HenVirtualCNode.SubType.STATE_START:
				node_config['type'] = HenVirtualCNode.Type.STATE_START
		
		var node = HenVirtualCNode.instantiate_virtual_cnode(node_config)
		
		if not node:
			continue
			
		HenClipboard.copy([node])
		
		var target_pos: Vector2 = Vector2(200, 300)
		var pasted_count = HenClipboard.paste(target_pos)
		
		assert_int(pasted_count).is_equal(1)

		if global.SELECTED_VIRTUAL_CNODE.size() > 0:
			var pasted_node = global.SELECTED_VIRTUAL_CNODE[0]
			
			assert_int(pasted_node.sub_type).is_equal(node.sub_type)
			assert_int(pasted_node.type).is_equal(node.type)
			assert_str(pasted_node.name).is_equal(node.name)
			
			assert_float(pasted_node.position.x).is_equal(target_pos.x)
			assert_float(pasted_node.position.y).is_equal(target_pos.y)
			
			assert_int(pasted_node.id).is_not_equal(node.id)
			
			var _route: HenRouteData = save_data.get_base_route()
			if _route.virtual_cnode_list.has(pasted_node):
				_route.virtual_cnode_list.erase(pasted_node)
				
		var route: HenRouteData = save_data.get_base_route()
		if route.virtual_cnode_list.has(node):
			route.virtual_cnode_list.erase(node)
