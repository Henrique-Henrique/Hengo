class_name HenCheckerSignal extends RefCounted


static func check_changes_signal(signal_callback_data: Dictionary, refs: HenRegenerateRefs) -> void:
	# find the corresponding signal data in the sidebar list using the ID
	var signal_data: Dictionary
	var signal_id = signal_callback_data.get('custom_id')

	# search for the signal in the sidebar list by ID
	if signal_id:
		for data: Dictionary in refs.side_bar_list.signal_list:
			if data.get('id') == signal_id:
				signal_data = data
				break

	# if signal data is not found, mark as invalid and return
	if signal_data.is_empty():
		if not signal_callback_data.has('invalid') or (signal_callback_data.has('invalid') and not signal_callback_data.invalid):
			signal_callback_data.invalid = true
			refs.reload = true
		return

	# update signal name if it has changed
	if signal_callback_data.signal_name != signal_data.name:
		signal_callback_data.signal_name = signal_data.name
		signal_callback_data.signal_name_to_code = signal_data.name
		refs.reload = true

	# process parameters
	if signal_data.has('inputs'):
		# clear existing params and rebuild from inputs
		var params_array: Array = []
		var inputs: Array = signal_data.inputs as Array
		
		for input in inputs:
			var input_dict: Dictionary = input as Dictionary
			params_array.append({
				'id': input_dict.get('id'),
				'name': input_dict.get('name'),
				'type': input_dict.get('type', 'Variant')
			})
		
		# only update if there are changes
		if str(signal_callback_data.get('params', [])) != str(params_array):
			signal_callback_data.params = params_array
			refs.reload = true

	# create outputs array based on signal inputs
	if signal_data.has('inputs'):
		var outputs_array: Array = []
		var inputs: Array = signal_data.inputs as Array
		
		for input in inputs:
			var input_dict: Dictionary = input as Dictionary
			outputs_array.append({
				'id': input_dict.get('id'),
				'name': input_dict.get('name'),
				'type': input_dict.get('type', 'Variant')
			})
		
		# only update if there are changes
		if str(signal_callback_data.get('outputs', [])) != str(outputs_array):
			signal_callback_data.outputs = outputs_array
			refs.reload = true

	# Process virtual cnode outputs using checker_utils
	if signal_callback_data.has('virtual_cnode_list'):
		var vcnode_list: Array = signal_callback_data.virtual_cnode_list as Array
		if not vcnode_list.is_empty():
			var vcnode: Dictionary = vcnode_list[0] as Dictionary
			
			# ensure vcnode has outputs property
			if not vcnode.has('outputs'):
				vcnode.outputs = []
			
			if vcnode.has('outputs'):
				# prepare definition outputs from signal inputs
				var definition_outputs: Array = []
				var inputs: Array = signal_data.inputs as Array if signal_data.has('inputs') else []
				
				for input_dict: Dictionary in inputs:
					definition_outputs.append({
						'id': input_dict.get('id', 0),
						'name': input_dict.get('name', ''),
						'type': input_dict.get('type', 'Variant'),
						'ref_id': input_dict.get('id', 0)
					})
				
				# use checker_utils to sync outputs
				var result = HenCheckerUtils.sync_node_outputs(
					vcnode,
					definition_outputs,
					vcnode.outputs as Array
				)
				
				# ensure ref_id is set for each output
				for output: Dictionary in result.new_outputs:
					if not output.has('ref_id') and output.has('id'):
						output['ref_id'] = output['id']
				
				# update outputs if they changed
				if result.changed:
					vcnode.outputs = result.new_outputs
					refs.reload = true
			
			# check and update connections if needed (always execute this)
			if HenCheckerUtils.update_connections(refs, vcnode):
				refs.reload = true