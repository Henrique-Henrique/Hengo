class_name HenLiteralData extends RefCounted

const LITERAL_TYPES: Array[StringName] = [
	&'bool', &'float', &'int', &'String', &'Vector2i', &'Vector3i', &'Vector4', &'Vector2', &'Vector3', &'Color'
]


static func get_literal_types() -> Array[StringName]:
	return LITERAL_TYPES


static func get_literal_inputs(t: StringName) -> Array:
	match t:
		&'Vector2', &'Vector2i':
			return [
				{name = 'x', type = 'float' if t == &'Vector2' else 'int'},
				{name = 'y', type = 'float' if t == &'Vector2' else 'int'}
			]
		&'Vector3', &'Vector3i':
			return [
				{name = 'x', type = 'float' if t == &'Vector3' else 'int'},
				{name = 'y', type = 'float' if t == &'Vector3' else 'int'},
				{name = 'z', type = 'float' if t == &'Vector3' else 'int'}
			]
		&'Vector4':
			return [
				{name = 'x', type = 'float'},
				{name = 'y', type = 'float'},
				{name = 'z', type = 'float'},
				{name = 'w', type = 'float'}
			]
		&'Color':
			return [
				{name = 'r', type = 'float'},
				{name = 'g', type = 'float'},
				{name = 'b', type = 'float'},
				{name = 'a', type = 'float'}
			]
		_:
			return [ {name = '', type = t, is_static = true}]


static func create_literal_item(t: StringName, _io_type: StringName, _type: StringName, router: HenRouter) -> Variant:
	var connect_valid: bool = false
	var connect_input_idx: int = -1
	var connect_output_idx: int = -1

	if not _io_type:
		connect_valid = true
	elif _io_type == 'in':
		if not _type or HenUtils.is_type_relation_valid(t, _type):
			connect_output_idx = 0
			connect_valid = true
	elif _io_type == 'out':
		if not _type or HenUtils.is_type_relation_valid(_type, t):
			connect_input_idx = 0
			connect_valid = true

	if not connect_valid:
		return null

	var literal_inputs: Array = get_literal_inputs(t)

	var dt: Dictionary = {
		_class_name = 'Literal',
		name = t,
		data = {
			name = t,
			sub_type = HenVirtualCNode.SubType.LITERAL,
			category = 'native',
			inputs = literal_inputs,
			outputs = [ {name = 'value', type = t}],
			route = router.current_route if router else null
		},
		force_valid = true,
		is_match = true
	}
	if connect_input_idx != -1:
		dt.input_io_idx = connect_input_idx
	if connect_output_idx != -1:
		dt.output_io_idx = connect_output_idx

	return dt


static func process_literals(_io_type: StringName, _type: StringName, _arr: Array) -> void:
	var router: HenRouter = Engine.get_singleton(&'Router')
	var literal_category: Dictionary = {
		name = 'Literals',
		icon = 'code',
		color = '#f59e0b',
		method_list = []
	}

	for t: StringName in LITERAL_TYPES:
		var item = create_literal_item(t, _io_type, _type, router)
		if item != null:
			(literal_category.method_list as Array).append(item)

	if not (literal_category.method_list as Array).is_empty():
		_arr.append(literal_category)
