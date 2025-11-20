class_name HenCheckerScriptData extends RefCounted

const SCRIPT_DATA_SCHEMA = preload('res://addons/hengo/assets/data/script_data_schema.json')


static func is_script_data_valid(_script_data: HenScriptData) -> bool:
	if not _script_data:
		return false
	
	var errors: Array = HenJSONSchema.validate(_script_data.get_save(), SCRIPT_DATA_SCHEMA.get_data())
	
	if not errors.is_empty():
		var toast: HenToast = Engine.get_singleton(&'ToastContainer')
		toast.notify.call_deferred("Script data is invalid: " + _script_data.path, HenToast.MessageType.ERROR)
		for error in errors:
			var msg: String = (error as Dictionary).get('message', error) if error is Dictionary else error
			toast.notify.call_deferred("Error: " + msg, HenToast.MessageType.ERROR)
		return false
	
	# custom errors handling
	if not check_func_input_output(_script_data):
		return false

	return true


static func check_func_input_output(_script_data: HenScriptData) -> bool:
	for func_data: Dictionary in _script_data.side_bar_list.func_list:
		var has_input: bool = false
		var has_output: bool = false
		
		for vc: Dictionary in func_data.virtual_cnode_list:
			if vc.sub_type == HenVirtualCNode.SubType.FUNC_INPUT:
				has_input = true
			elif vc.sub_type == HenVirtualCNode.SubType.FUNC_OUTPUT:
				has_output = true
			
			if has_input and has_output:
				return true
		
		if not has_input or not has_output:
			return false

	return true
