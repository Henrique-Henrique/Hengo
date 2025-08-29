class_name HenSignalData extends RefCounted

var id: int = HenGlobal.get_new_node_counter()
var name: String = 'signal ' + str(Time.get_ticks_usec())
var inputs: Array


func on_change_name(_name: String) -> void:
	name = _name
	HenGlobal.SIDE_BAR_LIST.list_changed.emit()


func create_param() -> HenParamData:
	var in_out: HenParamData = HenParamData.new()

	in_out.name = 'name ' + str(inputs.size())
	inputs.append(in_out)
		
	return in_out


func delete_param(_ref: HenParamData) -> void:
	inputs.erase(_ref)
	_ref.deleted.emit(true)


func move_param(_direction: HenArrayItem.ArrayMove, _ref: HenParamData) -> void:
	var can_move: bool = false
	var arr: Array

	arr = inputs

	match _direction:
		HenArrayItem.ArrayMove.UP:
			can_move = HenUtils.move_array_item(arr, _ref, 1)
		HenArrayItem.ArrayMove.DOWN:
			can_move = HenUtils.move_array_item(arr, _ref, -1)


func load_save(_data: Dictionary) -> void:
	name = _data.name
	id = _data.id

	HenGlobal.SIDE_BAR_LIST_CACHE[id] = self

	for item_data: Dictionary in _data.inputs:
		var item: HenParamData = HenParamData.new()
		item.load_save(item_data)
		inputs.append(item)


func get_save() -> Dictionary:
	return {
		id = id,
		name = name,
		inputs = inputs.map(func(x: HenParamData) -> Dictionary: return x.get_save()),
	}


func get_inspector_array_list() -> Array:
	return [
		HenProp.new({
			name = 'name',
			type = HenProp.Type.STRING,
			default_value = name,
			on_value_changed = on_change_name
		}),
		HenProp.new({
			name = 'Inputs',
			type = HenProp.Type.ARRAY,
			on_item_create = create_param,
			prop_list = inputs.map(func(x: HenParamData) -> HenProp: return HenProp.new({
				name = 'name',
				type = HenProp.Type.STRING,
				default_value = x.name,
				on_value_changed = x.on_change_name,
				on_item_delete = delete_param.bind(x),
				on_item_move = move_param.bind(x),
			})),
		})
	] as Array[HenProp]