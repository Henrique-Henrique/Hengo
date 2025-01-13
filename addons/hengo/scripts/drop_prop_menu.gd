@tool
class_name HenDropPropMenu extends PopupMenu

enum Type {
	VAR
}

var type: Type
var reference: Node
var custom_data: Dictionary = {}

# private
#
func _ready() -> void:
	id_pressed.connect(_on_id_press)

func _on_id_press(_id: int) -> void:
	add_instance(_id)

func _map_inputs(_in_prop_data: Dictionary, _inputs: Array) -> void:
	if not _in_prop_data.is_empty():
		var count: int = 0

		for input_config: Dictionary in _inputs:
			var id = str(count)

			if _in_prop_data.has(id):
				input_config[HenCnode.SUB_TYPE.IN_PROP] = _in_prop_data[str(count)]
			
			count += 1

# public
#
func add_instance(_id: int, _config: Dictionary = {}) -> HenCnode:
	var ref = null
	var pos: Vector2 = HenGlobal.CNODE_CONTAINER.get_local_mouse_position() if not _config.has('pos') else str_to_var(_config.get('pos'))
	var route = HenRouter.current_route if not _config.has('route') else _config.get('route')
	var in_prop_data: Dictionary = _config.get('in_prop_data') if _config.has('in_prop_data') else {}

	match type:
		HenCnode.SUB_TYPE.VAR, HenCnode.SUB_TYPE.LOCAL_VAR:
			match _id:
				0:
					var res = custom_data.get('var_res')
					var cnode = HenCnode.instantiate_and_add({
						name = '',
						sub_type = HenCnode.SUB_TYPE.VAR if type == Type.VAR else HenCnode.SUB_TYPE.LOCAL_VAR,
						position = pos,
						outputs = [ {
							res = res
						}],
						route = route
					})
					reference.instance_reference.append(cnode)
					ref = cnode
				1:
					var res = custom_data.get('var_res')
					var input_data: Dictionary = {
						res = res
					}

					if not in_prop_data.is_empty():
						input_data[HenCnode.SUB_TYPE.IN_PROP] = in_prop_data['0']

					var cnode = HenCnode.instantiate_and_add({
						name = 'Set Var',
						sub_type = HenCnode.SUB_TYPE.SET_VAR if type == Type.VAR else HenCnode.SUB_TYPE.SET_LOCAL_VAR,
						inputs = [input_data],
						position = pos,
						route = route
					})
					reference.instance_reference.append(cnode)
					ref = cnode
		'state_signal':
			var signal_inputs = custom_data.get('signal_params').outputs
			var obj_arr = [ {
				name = reference.data.signal_data.object_name,
				type = reference.data.signal_data.object_name,
				ref = true
			}]
			var inputs = obj_arr + signal_inputs
			var data = reference.data.signal_data
			data.merge({item_ref = reference})

			_map_inputs(in_prop_data, inputs)

			match _id:
				0:
					var cnode = HenCnode.instantiate_and_add({
						name = 'Connect -> ' + reference.res[0].value,
						data = data,
						sub_type = 'signal_connection',
						inputs = inputs,
						position = pos,
						route = route
					})
					reference.instance_reference.append(cnode)
					ref = cnode
				1:
					var cnode = HenCnode.instantiate_and_add({
						name = 'Disconnect -> ' + reference.res[0].value,
						data = data,
						sub_type = 'signal_disconnection',
						inputs = obj_arr,
						position = pos,
						route = route
					})
					reference.instance_reference.append(cnode)
					ref = cnode
				2:
					var cnode = HenCnode.instantiate_and_add({
						name = 'Emit Signal -> ' + reference.res[0].value,
						data = data,
						sub_type = 'signal_emit',
						inputs = inputs,
						position = pos,
						route = route
					})
					reference.instance_reference.append(cnode)
					ref = cnode
		'function':
			var func_res = custom_data.get('func_res')
			var inputs_res = custom_data.get('inputs_res')
			var outputs_res = custom_data.get('outputs_res')
			var inputs: Array = inputs_res.get('inputs')

			_map_inputs(in_prop_data, inputs)

			var cnode = HenCnode.instantiate_and_add({
				name = func_res.value,
				sub_type = HenCnode.SUB_TYPE.USER_FUNC,
				inputs = inputs_res.get('inputs'),
				outputs = outputs_res.get('outputs'),
				position = pos,
				route = route
			})
			reference.instance_reference.append(cnode)
			ref = cnode

	return ref

func mount(_type: Type, _ref: Node = null, _custom_data: Dictionary = {}, _create_menu: bool = true) -> void:
	clear()
	type = _type
	reference = _ref
	custom_data = _custom_data
	
	if _create_menu:
		match _type:
			HenCnode.SUB_TYPE.VAR, HenCnode.SUB_TYPE.LOCAL_VAR:
				add_item('Get')
				add_item('Set')
			'state_signal':
				add_item('Connect')
				add_item('Disconnect')
				add_item('Emit Signal')
			'function':
				add_instance(-1)