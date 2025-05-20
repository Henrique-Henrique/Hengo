@tool
class_name HenSaver extends Node


static func save(_debug_symbols: Dictionary, _generate_code: bool = false) -> void:
	# check if save dierctory exists
	if not DirAccess.dir_exists_absolute('res://hengo'):
		DirAccess.make_dir_absolute('res://hengo')

	if not DirAccess.dir_exists_absolute('res://hengo/save'):
		DirAccess.make_dir_absolute('res://hengo/save')
	
	if not FileAccess.file_exists('res://hengo/save/references.res'):
		ResourceSaver.save(HenSideBarReferences.new(), 'res://hengo/save/references.res')

	var side_bar_refs: HenSideBarReferences = ResourceLoader.load('res://hengo/save/references.res')

	HenGlobal.FROM_REFERENCES = side_bar_refs

	var script_data: HenScriptData = HenScriptData.new()

	script_data.path = HenGlobal.script_config.path
	script_data.type = HenGlobal.script_config.type
	script_data.node_counter = HenGlobal.node_counter
	script_data.prop_counter = HenGlobal.prop_counter
	script_data.debug_symbols = _debug_symbols

	# ---------------------------------------------------------------------------- #
	# Side Bar List
	script_data.side_bar_list = HenGlobal.SIDE_BAR_LIST.get_save()

	# ---------------------------------------------------------------------------- #
	var v_cnode_list: Array[Dictionary] = []

	for v_cnode: HenVirtualCNode in HenGlobal.BASE_ROUTE.ref.virtual_cnode_list:
		v_cnode_list.append(v_cnode.get_save())

		if v_cnode.type == HenVirtualCNode.Type.STATE_EVENT:
			script_data.state_event_list.append(v_cnode.name)
			
	script_data.virtual_cnode_list = v_cnode_list

	var data_path: StringName = 'res://hengo/save/' + str(HenGlobal.script_config.id) + '.res'

	# saving data
	var error: int = ResourceSaver.save(script_data, data_path)

	if error != OK:
		printerr('Error saving script data.')
		return


	if not HenGlobal.FROM_REFERENCES.references.is_empty():
		ResourceSaver.save(HenGlobal.FROM_REFERENCES)

	# ---------------------------------------------------------------------------- #
	if _generate_code:
		generate(script_data, data_path, ResourceUID.get_id_path(HenGlobal.script_config.id))


		# generation dependencies
		if HenGlobal.FROM_REFERENCES.references.get(HenGlobal.script_config.id) is Array:
			for id: int in HenGlobal.FROM_REFERENCES.references.get(HenGlobal.script_config.id):
				var need_reload: bool = false

				var res: HenScriptData = ResourceLoader.load('res://hengo/save/' + str(id) + '.res')

				for vc: Dictionary in res.virtual_cnode_list:
					if vc.sub_type == HenVirtualCNode.SubType.GET_FROM_PROP:
						# TODO
						print('vuu ')

					if vc.has(&'virtual_cnode_list'):
						for vc_chd: Dictionary in vc.virtual_cnode_list:
							if vc_chd.sub_type == HenVirtualCNode.SubType.GET_FROM_PROP:
								var output: Dictionary = vc_chd.outputs[0]
								
								for var_data: HenSideBar.VarData in HenGlobal.SIDE_BAR_LIST.var_list:
									if var_data.id == output.from_side_bar_id:
										if var_data.name != output.value or var_data.type != output.type:
											output.code_value = var_data.name
											output.value = var_data.name

											# TODO - CHANGE TYPE

											need_reload = true

				if need_reload:
					var res_error: int = ResourceSaver.save(res)

					if res_error == OK:
						generate(res, data_path, ResourceUID.get_id_path(id))

				print('vuu ', need_reload)
				print('vu2 ', JSON.stringify(res.get_save()))


static func generate(_script_data: HenScriptData, _data_path: String, _path: StringName) -> void:
	var code: String = HenCodeGeneration.get_code(_script_data)

	var script: GDScript = GDScript.new()
	script.source_code = '#[hengo] ' + _data_path + '\n\n' + code

	var reload_err: int = script.reload()

	if reload_err == OK:
		print('vii ', ResourceUID.get_id_path(HenGlobal.script_config.id))
		var err: int = ResourceSaver.save(script, _path)

		if err == OK:
			print('SAVED HENGO SCRIPT')