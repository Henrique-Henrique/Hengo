class_name HenOperatorData extends RefCounted

const OPERATOR_CATEGORIES: Array = [
	{
		name = 'Comparison',
		icon = 'equal',
		color = '#ef4444',
		sub_categories = [
			{
				name = 'String',
				operators = [
					{name = 'Equal', code = '==', input_0_type = 'String', input_1_type = 'String', output_type = 'bool'},
					{name = 'Not Equal', code = '!=', input_0_type = 'String', input_1_type = 'String', output_type = 'bool'}
				]
			},
			{
				name = 'int',
				operators = [
					{name = 'Greater Than', code = '>', input_0_type = 'int', input_1_type = 'int', output_type = 'bool'},
					{name = 'Less Than', code = '<', input_0_type = 'int', input_1_type = 'int', output_type = 'bool'},
					{name = 'Greater or Equal', code = '>=', input_0_type = 'int', input_1_type = 'int', output_type = 'bool'},
					{name = 'Less or Equal', code = '<=', input_0_type = 'int', input_1_type = 'int', output_type = 'bool'},
					{name = 'Equal', code = '==', input_0_type = 'int', input_1_type = 'int', output_type = 'bool'},
					{name = 'Not Equal', code = '!=', input_0_type = 'int', input_1_type = 'int', output_type = 'bool'}
				]
			},
			{
				name = 'float',
				operators = [
					{name = 'Greater Than', code = '>', input_0_type = 'float', input_1_type = 'float', output_type = 'bool'},
					{name = 'Less Than', code = '<', input_0_type = 'float', input_1_type = 'float', output_type = 'bool'},
					{name = 'Greater or Equal', code = '>=', input_0_type = 'float', input_1_type = 'float', output_type = 'bool'},
					{name = 'Less or Equal', code = '<=', input_0_type = 'float', input_1_type = 'float', output_type = 'bool'},
					{name = 'Equal', code = '==', input_0_type = 'float', input_1_type = 'float', output_type = 'bool'},
					{name = 'Not Equal', code = '!=', input_0_type = 'float', input_1_type = 'float', output_type = 'bool'}
				]
			},
			{
				name = 'Variant',
				operators = [
					{name = 'Equal', code = '==', input_0_type = 'Variant', input_1_type = 'Variant', output_type = 'bool'},
					{name = 'Not Equal', code = '!=', input_0_type = 'Variant', input_1_type = 'Variant', output_type = 'bool'}
				]
			}
		]
	},
	{
		name = 'Logical',
		icon = 'sparkles',
		color = '#f59e0b',
		sub_categories = [
			{
				name = 'bool',
				operators = [
					{name = 'NOT', code = '!', op_type = 'unary', input_0_type = 'bool', output_type = 'bool'},
					{name = 'AND', code = '&&', input_0_type = 'bool', input_1_type = 'bool', output_type = 'bool'},
					{name = 'OR', code = '||', input_0_type = 'bool', input_1_type = 'bool', output_type = 'bool'}
				]
			}
		]
	},
	{
		name = 'Compound Assignment',
		icon = 'plus',
		color = '#22c55e',
		sub_categories = [
			{
				name = 'String',
				operators = [
					{name = 'Add To', code = '+=', op_type = 'compound', input_0_type = 'String', input_1_type = 'String', output_type = 'void'}
				]
			},
			{
				name = 'int',
				operators = [
					{name = 'Add To', code = '+=', op_type = 'compound', input_0_type = 'int', input_1_type = 'int', output_type = 'void'},
					{name = 'Subtract From', code = '-=', op_type = 'compound', input_0_type = 'int', input_1_type = 'int', output_type = 'void'},
					{name = 'Multiply By', code = '*=', op_type = 'compound', input_0_type = 'int', input_1_type = 'int', output_type = 'void'},
					{name = 'Divide By', code = '/=', op_type = 'compound', input_0_type = 'int', input_1_type = 'int', output_type = 'void'}
				]
			},
			{
				name = 'float',
				operators = [
					{name = 'Add To', code = '+=', op_type = 'compound', input_0_type = 'float', input_1_type = 'float', output_type = 'void'},
					{name = 'Subtract From', code = '-=', op_type = 'compound', input_0_type = 'float', input_1_type = 'float', output_type = 'void'},
					{name = 'Multiply By', code = '*=', op_type = 'compound', input_0_type = 'float', input_1_type = 'float', output_type = 'void'},
					{name = 'Divide By', code = '/=', op_type = 'compound', input_0_type = 'float', input_1_type = 'float', output_type = 'void'}
				]
			}
		]
	},
	{
		name = 'Bitwise (int)',
		icon = 'binary',
		color = '#8b5cf6',
		operators = [
			{name = 'AND', code = '&', input_0_type = 'int', input_1_type = 'int', output_type = 'int'},
			{name = 'OR', code = '|', input_0_type = 'int', input_1_type = 'int', output_type = 'int'},
			{name = 'XOR', code = '^', input_0_type = 'int', input_1_type = 'int', output_type = 'int'},
			{name = 'Left Shift', code = '<<', input_0_type = 'int', input_1_type = 'int', output_type = 'int'},
			{name = 'Right Shift', code = '>>', input_0_type = 'int', input_1_type = 'int', output_type = 'int'}
		]
	},
	{
		name = 'Bitwise (bool)',
		icon = 'binary',
		color = '#a855f7',
		operators = [
			{name = 'AND', code = '&', input_0_type = 'bool', input_1_type = 'bool', output_type = 'bool'},
			{name = 'OR', code = '|', input_0_type = 'bool', input_1_type = 'bool', output_type = 'bool'},
			{name = 'XOR', code = '^', input_0_type = 'bool', input_1_type = 'bool', output_type = 'bool'}
		]
	},
	{
		name = 'Ternary',
		icon = 'equal-not',
		color = '#06b6d4',
		operators = [
			{name = 'If Then Else', code = '?:', op_type = 'ternary', input_0_type = 'bool', input_1_type = 'Variant', input_2_type = 'Variant', output_type = 'Variant'}
		]
	}
]


static func get_categories() -> Array:
	return OPERATOR_CATEGORIES


static func create_operator_item(op: Dictionary, _io_type: StringName, _type: StringName, router: HenRouter) -> Variant:
	var connect_valid: bool = false
	var connect_input_idx: int = -1
	var connect_output_idx: int = -1

	var output_type: String = op.get('output_type', 'Variant')

	if not _io_type:
		connect_valid = true
	elif _io_type == 'in':
		if output_type != 'void' and (str(_type).is_empty() or HenUtils.is_type_relation_valid(output_type, _type)):
			connect_output_idx = 0
			connect_valid = true
	elif _io_type == 'out':
		if str(_type).is_empty() or HenUtils.is_type_relation_valid(_type, op.get('input_0_type', 'Variant')):
			connect_input_idx = 0
			connect_valid = true

	if not connect_valid:
		return null

	var op_inputs: Array = []
	var op_type: String = op.get('op_type', 'binary')

	if op_type == 'unary':
		op_inputs = [ {name = 'a', type = op.get('input_0_type', 'Variant')}]
	elif op_type == 'ternary':
		op_inputs = [
			{name = 'condition', type = op.get('input_0_type', 'bool')},
			{name = 'true_val', type = op.get('input_1_type', 'Variant')},
			{name = 'false_val', type = op.get('input_2_type', 'Variant')}
		]
	elif op_type == 'compound':
		op_inputs = [
			{name = 'var_ref', type = op.get('input_0_type', 'Variant')},
			{name = 'value', type = op.get('input_1_type', 'Variant')}
		]
	else:
		op_inputs = [
			{name = 'a', type = op.get('input_0_type', 'Variant')},
			{name = 'b', type = op.get('input_1_type', 'Variant')}
		]

	var outputs: Array = []
	if output_type != 'void':
		outputs = [ {name = 'result', type = output_type}]

	var input_code_value_map: Dictionary = {'operator_type': op_type}
	if op_type == 'compound':
		input_code_value_map['var_type'] = op.get('input_1_type', 'Variant')

	var item: Dictionary = {
		_class_name = 'Operator',
		name = op.get('name', ''),
		data = {
			name = op.get('name', ''),
			name_to_code = op.get('code', ''),
			sub_type = HenVirtualCNode.SubType.OPERATOR,
			operator_type = op_type,
			input_code_value_map = input_code_value_map,
			category = 'native',
			inputs = op_inputs,
			outputs = outputs,
			route = router.current_route if router else null
		},
		force_valid = true,
		is_match = true
	}

	if connect_input_idx != -1:
		item.input_io_idx = connect_input_idx
	if connect_output_idx != -1:
		item.output_io_idx = connect_output_idx

	return item


static func classify_operator_type(code: String) -> String:
	match code:
		'!', 'not':
			return 'unary'
		'+=', '-=', '*=', '/=':
			return 'compound'
		'?:':
			return 'ternary'
		'&', '|', '^', '<<', '>>':
			return 'bitwise'
		_:
			return 'binary'


static func process_operators(_io_type: StringName, _type: StringName, _arr: Array) -> void:
	var router: HenRouter = Engine.get_singleton(&'Router')

	for category: Dictionary in OPERATOR_CATEGORIES:
		var category_data: Dictionary = {
			name = category.name,
			icon = category.icon,
			color = category.color,
			method_list = []
		}

		if category.has('sub_categories'):
			for sub_cat: Dictionary in (category.sub_categories as Array):
				var sub_cat_items: Array = []

				for op: Dictionary in (sub_cat.operators as Array):
					var item = create_operator_item(op, _io_type, _type, router)
					if item != null:
						sub_cat_items.append(item)

				if not sub_cat_items.is_empty():
					var folder_item: Dictionary = {
						name = sub_cat.name,
						icon = category.icon,
						color = category.color,
						recursive_props = sub_cat_items,
						is_match = true
					}
					(category_data.method_list as Array).append(folder_item)
		else:
			for op: Dictionary in (category.operators as Array):
				var item = create_operator_item(op, _io_type, _type, router)
				if item != null:
					(category_data.method_list as Array).append(item)

		if not (category_data.method_list as Array).is_empty():
			_arr.append(category_data)
