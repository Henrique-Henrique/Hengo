extends HenTestSuite


# tests that input event check node returns invalid when event input is not connected
func test_input_event_check_invalid_when_not_connected() -> void:
	var vc: HenVirtualCNode = get_input_event_check_vc()
	
	var expected_code = 'HengoState.INVALID_PLACEHOLDER'
	assert_str(HenTest.get_vc_code(vc)).is_equal(expected_code)


# tests input event check node with event connected generates proper code
func test_input_event_check_with_connection() -> void:
	var vc: HenVirtualCNode = get_input_event_check_vc()
	var event_vc: HenVirtualCNode = get_event_param_vc()
	
	vc.get_new_input_connection_command(0, 0, event_vc).add()
	
	var expected_code = 'event is InputEventKey and event.pressed and event.keycode == KEY_SPACE'
	assert_str(HenTest.get_vc_code(vc)).is_equal(expected_code)


# tests input action check node returns invalid when event input is not connected
func test_input_action_check_invalid_when_not_connected() -> void:
	var vc: HenVirtualCNode = get_input_action_check_vc()
	
	var expected_code = 'HengoState.INVALID_PLACEHOLDER'
	assert_str(HenTest.get_vc_code(vc)).is_equal(expected_code)


# tests input action check node with event connected generates proper code
func test_input_action_check_with_connection() -> void:
	var vc: HenVirtualCNode = get_input_action_check_vc()
	var event_vc: HenVirtualCNode = get_event_param_vc()
	
	vc.get_new_input_connection_command(0, 0, event_vc).add()
	
	var expected_code = 'event.is_action_pressed("jump")'
	assert_str(HenTest.get_vc_code(vc)).is_equal(expected_code)


# tests input polling node generates proper code
func test_input_polling_generates_code() -> void:
	var vc: HenVirtualCNode = get_input_polling_vc()
	
	var expected_code = 'Input.is_action_pressed("shoot")'
	assert_str(HenTest.get_vc_code(vc)).is_equal(expected_code)


# helper to create input event check vc
func get_input_event_check_vc() -> HenVirtualCNode:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	
	return HenVirtualCNode.instantiate_virtual_cnode({
		id = global.get_new_node_counter(),
		name = 'On Key Pressed',
		sub_type = HenVirtualCNode.SubType.INPUT_EVENT_CHECK,
		category = 'native',
		input_code_value_map = {
			event_type = 'InputEventKey',
			check_pressed = true,
			property = 'keycode'
		},
		inputs = [
			{id = 0, name = 'event', type = 'InputEvent'},
			{id = 1, name = 'key', type = 'int', code_value = 'KEY_SPACE'}
		],
		outputs = [
			{id = 0, name = 'result', type = 'bool'}
		],
		route = HenTest.get_base_route()
	})


# helper to create input action check vc
func get_input_action_check_vc() -> HenVirtualCNode:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	
	return HenVirtualCNode.instantiate_virtual_cnode({
		id = global.get_new_node_counter(),
		name = 'On Action Pressed',
		sub_type = HenVirtualCNode.SubType.INPUT_ACTION_CHECK,
		category = 'native',
		input_code_value_map = {
			method = 'is_action_pressed'
		},
		inputs = [
			{id = 0, name = 'event', type = 'InputEvent'},
			{id = 1, name = 'action', type = 'StringName', code_value = 'jump'}
		],
		outputs = [
			{id = 0, name = 'result', type = 'bool'}
		],
		route = HenTest.get_base_route()
	})


# helper to create input polling vc
func get_input_polling_vc() -> HenVirtualCNode:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	
	return HenVirtualCNode.instantiate_virtual_cnode({
		id = global.get_new_node_counter(),
		name = 'Input Action Pressed',
		sub_type = HenVirtualCNode.SubType.INPUT_POLLING,
		category = 'native',
		input_code_value_map = {
			method = 'is_action_pressed'
		},
		inputs = [
			{id = 0, name = 'action', type = 'StringName', code_value = 'shoot'}
		],
		outputs = [
			{id = 0, name = 'result', type = 'bool'}
		],
		route = HenTest.get_base_route()
	})


# helper to create an event param vc
func get_event_param_vc() -> HenVirtualCNode:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	
	return HenVirtualCNode.instantiate_virtual_cnode({
		id = global.get_new_node_counter(),
		name = 'event',
		sub_type = HenVirtualCNode.SubType.VIRTUAL,
		outputs = [
			{id = 0, name = 'event', type = 'InputEvent'}
		],
		route = HenTest.get_base_route()
	})
