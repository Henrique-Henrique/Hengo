extends GutTest

#
#
#
#
#
#
func test_signal_code() -> void:
	HenTest.set_global_config()

	HenGlobal.SIDE_BAR_LIST.type = HenSideBar.AddType.SIGNAL
	HenGlobal.SIDE_BAR_LIST.add()

	var signal_data: HenSignalData = HenGlobal.SIDE_BAR_LIST.signal_list[0]

	signal_data.name = 'my signal'
	signal_data.set_signal_params('BaseButton', 'toggled')

	var script_data: HenScriptData = HenSaver.generate_script_data()
	var code: String = HenCodeGeneration.get_code(script_data)

	assert_true(
		code.contains('\nfunc _on_my_signal_signal_(toggled_on):\n\tpass'),
		'Testing signal empty'
	)

	var vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'test_void',
		sub_type = HenVirtualCNode.SubType.VOID,
		inputs = [],
		route = signal_data.route
	})
	
	signal_data.signal_enter.add_flow_connection(0, 0, vc).add()

	var script_data_2: HenScriptData = HenSaver.generate_script_data()
	var code_2: String = HenCodeGeneration.get_code(script_data_2)

	assert_true(
		code_2.contains('\nfunc _on_my_signal_signal_(toggled_on):\n\ttest_void()'),
		'Testing signal with vc connection'
	)

	var vc_input: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'test_void',
		sub_type = HenVirtualCNode.SubType.FUNC,
		inputs = [
			{
				id = 0,
				name = 'content',
				type = 'Variant'
			}
		],
		route = signal_data.route
	})
	
	signal_data.signal_enter.add_flow_connection(0, 0, vc_input).add()
	vc_input.get_new_input_connection_command(0, signal_data.signal_enter.io.outputs[0].id, signal_data.signal_enter).add()

	var script_input_data: HenScriptData = HenSaver.generate_script_data()
	var code_input: String = HenCodeGeneration.get_code(script_input_data)

	assert_true(
		code_input.contains('\nfunc _on_my_signal_signal_(toggled_on):\n\ttest_void(toggled_on)'),
		'Testing signal with vc connection and param connection'
	)

#
#
#
#
#
#
func test_connection_code() -> void:
	var refs: HenSaveCodeType.References = HenSaveCodeType.References.new()
	var signal_data: HenSignalData = HenGlobal.SIDE_BAR_LIST.signal_list[0]
	var dt: Dictionary = signal_data.get_connect_cnode_data()
	var script_data: HenScriptData = HenScriptData.new()

	dt.route = HenTest.get_base_route()
	HenFactorySignal.get_signal_from_dict(signal_data.get_save(script_data), refs)

	var vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode(dt)
	
	assert_eq(
		HenTest.get_virtual_cnode_code(vc, refs).code,
		'connect("toggled", _on_my_signal_signal_)'
	)

	var param: HenParamData = signal_data.create_param()
	param.name = 'a'

	assert_eq(
		HenTest.get_virtual_cnode_code(vc, refs).code,
		'connect("toggled", _on_my_signal_signal_.bind(null))'
	)

# #
# #
# #
# #
# #
# #
func test_disconnection_code() -> void:
	var refs: HenSaveCodeType.References = HenSaveCodeType.References.new()
	var signal_data: HenSignalData = HenGlobal.SIDE_BAR_LIST.signal_list[0]
	var dt: Dictionary = signal_data.get_diconnect_cnode_data()
	var script_data: HenScriptData = HenScriptData.new()
	
	dt.route = HenTest.get_base_route()
	HenFactorySignal.get_signal_from_dict(signal_data.get_save(script_data), refs)

	var vc: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode(dt)
	
	assert_eq(
		HenTest.get_virtual_cnode_code(vc, refs).code,
		'disconnect("toggled", _on_my_signal_signal_)'
	)
