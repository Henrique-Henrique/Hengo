@tool
extends PanelContainer

# imports
const _Global = preload('res://addons/hengo/scripts/global.gd')
const PropContainerScene = preload('res://addons/hengo/scenes/prop_container.tscn')


func show_props(_config: Dictionary, _ref) -> void:
	position = _ref.global_position + Vector2(_ref.size.x * _Global.STATE_CAM.transform.x.x + 10, 0)

	# clear
	for chd in get_child(0).get_children():
		chd.free()


	for prop in _config.list:
		var prop_ref = PropContainerScene.instantiate()
		prop_ref.get_child(0).text = prop.name

		match prop.type:
			'String':
				var ref = load('res://addons/hengo/scenes/props/string.tscn').instantiate()

				if prop.has('value'):
					ref.set_default(prop.value)
				
				if prop.name == 'name':
					ref.value_changed.connect(func(_name):
						_ref.change_name(_name)
						prop.value = _name

						for node_ref in _Global.GROUP.get_nodes_from_group('f_' + str(_ref.hash)):
							node_ref.change_name('Func -> ' + _name)
						)

				prop_ref.add_child(ref)
			'in_out':
				var ref = load('res://addons/hengo/scenes/props/function_input_output.tscn').instantiate()
				var in_out_type: StringName = ''

				match prop.name:
					'inputs':
						in_out_type = 'in'
					'outputs':
						in_out_type = 'out'

				for prop_data in prop.value:
					ref._add(prop_data)

				# added input/output
				ref.added_param.connect(func():
					var new_prop: Dictionary = {
						name = 'param 2',
						# fi = func input
						# fo = func ouput
						# TODO: refact group names
						group = 'fi_' + str(_ref.hash) + '_' + str(prop.value.size()) if in_out_type == 'in' else 'fo_' + str(_ref.hash) + '_' + str(prop.value.size())
					}

					prop.value.append(new_prop)
					ref.removed_param.connect(func():
						prop.value.erase(new_prop)
						)

					for node_ref in _Global.GROUP.get_nodes_from_group('f_' + str(_ref.hash)):
						match in_out_type:
							'in':
								match node_ref.type:
									'func_output':
										pass
									'func_input':
										node_ref.add_output(new_prop)
									_:
										node_ref.add_input(new_prop)
							'out':
								match node_ref.type:
									'func_input', 'signal_disconnection':
										pass
									'signal_connection', 'signal_emit', 'func_output':
										node_ref.add_input(new_prop)
									_:
										node_ref.add_output(new_prop)

					)
				
				ref.removed_param.connect(func(_idx: int):
					prop.value.remove_at(_idx)
					)

				ref.type_changed.connect(func(_type: String, _idx: int):
					prop.value[_idx].type = _type
					
					var group_name: StringName = StringName('fi_' + str(_ref.hash) + '_' + str(_idx)) if in_out_type == 'in' else StringName('fo_' + str(_ref.hash) + '_' + str(_idx))
					for node_ref in _Global.GROUP.get_nodes_from_group(group_name):
						node_ref.change_type(_type)

					)

				ref.name_changed.connect(func(_name: String, _idx: int):
					prop.value[_idx].name = _name

					var group_name: StringName = StringName('fi_' + str(_ref.hash) + '_' + str(_idx)) if in_out_type == 'in' else StringName('fo_' + str(_ref.hash) + '_' + str(_idx))

					for node_ref in _Global.GROUP.get_nodes_from_group(group_name):
						node_ref.change_name(_name)

					)

				prop_ref.add_child(ref)

		get_child(0).add_child(prop_ref)

	size = Vector2.ZERO
	get_parent().show()