class_name HenNativeItems extends RefCounted

const NATIVE_ITEMS: Array = [
	{
		name = 'Expression',
		icon = 'calculator',
		color = '#8b5cf6',
		is_native = true,
		data = {
			name = 'Expression',
			type = HenVirtualCNode.Type.EXPRESSION,
			sub_type = HenVirtualCNode.SubType.EXPRESSION,
			category = 'native',
			inputs = [
				{
					name = '',
					type = 'Variant',
					sub_type = 'expression',
					is_static = true
				}
			],
			outputs = [
				{
					name = 'result',
					type = 'Variant'
				}
			],
			route = null
		}
	},
	{
		name = 'Make Transition',
		icon = 'arrow-right-left',
		color = '#06b6d4',
		is_native = true,
		data = {
			name = 'make_transition',
			sub_type = HenVirtualCNode.SubType.MAKE_TRANSITION,
			category = 'native',
			inputs = [
				{
					name = 'name',
					type = 'StringName',
					sub_type = '@dropdown',
					code_value = '',
					category = 'state_transition'
				}
			],
			route = null
		}
	},
	{
		name = 'print',
		icon = 'terminal',
		color = '#10b981',
		is_native = true,
		data = {
			name = 'print',
			sub_type = HenVirtualCNode.SubType.VOID,
			category = 'native',
			inputs = [
				{
					name = 'content',
					type = 'Variant'
				}
			],
			route = null
		}
	},
	{
		name = 'Print Text',
		icon = 'text-cursor',
		color = '#10b981',
		is_native = true,
		data = {
			name = 'print',
			sub_type = HenVirtualCNode.SubType.VOID,
			category = 'native',
			inputs = [
				{
					name = 'content',
					type = 'String'
				}
			],
			route = null
		}
	},
	{
		name = 'IF Condition',
		icon = 'git-branch',
		color = '#f97316',
		is_native = true,
		data = {
			name = 'IF',
			type = HenVirtualCNode.Type.IF,
			sub_type = HenVirtualCNode.SubType.IF,
			route = null,
			inputs = [
				{
					name = 'condition',
					type = 'bool'
				}
			]
		}
	},
	{
		name = 'For -> Range',
		icon = 'repeat',
		color = '#ec4899',
		is_native = true,
		data = {
			name = 'For -> Range',
			type = HenVirtualCNode.Type.FOR,
			sub_type = HenVirtualCNode.SubType.FOR,
			inputs = [
				{
					name = 'start',
					type = 'int'
				},
				{
					name = 'end',
					type = 'int'
				},
				{
					name = 'step',
					type = 'int',
					value = 1,
					code_value = '1'
				}
			],
			outputs = [
				{
					name = 'index',
					type = 'int'
				}
			],
			route = null
		}
	},
	{
		name = 'For -> Item',
		icon = 'list',
		color = '#ec4899',
		is_native = true,
		data = {
			name = 'For -> Item',
			type = HenVirtualCNode.Type.FOR,
			sub_type = HenVirtualCNode.SubType.FOR_ARR,
			inputs = [
				{
					name = 'array',
					type = 'Array'
				}
			],
			outputs = [
				{
					name = 'item',
					type = 'Variant'
				}
			],
			route = null
		}
	},
	{
		name = 'break',
		icon = 'circle-slash',
		color = '#ef4444',
		is_native = true,
		data = {
			name = 'break',
			sub_type = HenVirtualCNode.SubType.BREAK,
			category = 'native',
			route = null
		}
	},
	{
		name = 'continue',
		icon = 'fast-forward',
		color = '#eab308',
		is_native = true,
		data = {
			name = 'continue',
			sub_type = HenVirtualCNode.SubType.CONTINUE,
			category = 'native',
			route = null
		}
	},
	{
		name = 'Raw Code',
		icon = 'code',
		color = '#6366f1',
		is_native = true,
		data = {
			name = 'Raw Code',
			sub_type = HenVirtualCNode.SubType.RAW_CODE,
			category = 'native',
			inputs = [
				{
					name = '',
					category = 'disabled',
					type = 'String'
				}
			],
			outputs = [
				{
					name = 'code',
					type = 'Variant'
				}
			],
			route = null
		}
	},
	{
		name = 'On Key Pressed',
		icon = 'keyboard',
		color = '#22c55e',
		is_native = true,
		data = {
			name = 'On Key Pressed',
			sub_type = HenVirtualCNode.SubType.INPUT_EVENT_CHECK,
			category = 'native',
			input_code_value_map = {
				event_type = 'InputEventKey',
				check_pressed = true,
				property = 'keycode'
			},
			inputs = [
				{
					name = 'event',
					type = 'InputEvent'
				},
				{
					name = 'key',
					type = 'int',
					sub_type = '@dropdown',
					category = 'key_code'
				}
			],
			outputs = [
				{
					name = 'result',
					type = 'bool'
				}
			],
			route = null
		}
	},
	{
		name = 'On Key Released',
		icon = 'keyboard',
		color = '#ef4444',
		is_native = true,
		data = {
			name = 'On Key Released',
			sub_type = HenVirtualCNode.SubType.INPUT_EVENT_CHECK,
			category = 'native',
			input_code_value_map = {
				event_type = 'InputEventKey',
				check_pressed = false,
				property = 'keycode'
			},
			inputs = [
				{
					name = 'event',
					type = 'InputEvent'
				},
				{
					name = 'key',
					type = 'int',
					sub_type = '@dropdown',
					category = 'key_code'
				}
			],
			outputs = [
				{
					name = 'result',
					type = 'bool'
				}
			],
			route = null
		}
	},
	{
		name = 'On Mouse Button Pressed',
		icon = 'mouse-pointer-click',
		color = '#3b82f6',
		is_native = true,
		data = {
			name = 'On Mouse Button Pressed',
			sub_type = HenVirtualCNode.SubType.INPUT_EVENT_CHECK,
			category = 'native',
			input_code_value_map = {
				event_type = 'InputEventMouseButton',
				check_pressed = true,
				property = 'button_index'
			},
			inputs = [
				{
					name = 'event',
					type = 'InputEvent'
				},
				{
					name = 'button',
					type = 'int',
					sub_type = '@dropdown',
					category = 'mouse_button'
				}
			],
			outputs = [
				{
					name = 'result',
					type = 'bool'
				}
			],
			route = null
		}
	},
	{
		name = 'On Mouse Button Released',
		icon = 'mouse-pointer-click',
		color = '#ef4444',
		is_native = true,
		data = {
			name = 'On Mouse Button Released',
			sub_type = HenVirtualCNode.SubType.INPUT_EVENT_CHECK,
			category = 'native',
			input_code_value_map = {
				event_type = 'InputEventMouseButton',
				check_pressed = false,
				property = 'button_index'
			},
			inputs = [
				{
					name = 'event',
					type = 'InputEvent'
				},
				{
					name = 'button',
					type = 'int',
					sub_type = '@dropdown',
					category = 'mouse_button'
				}
			],
			outputs = [
				{
					name = 'result',
					type = 'bool'
				}
			],
			route = null
		}
	},
	{
		name = 'On Action Pressed',
		icon = 'gamepad-2',
		color = '#f97316',
		is_native = true,
		data = {
			name = 'On Action Pressed',
			sub_type = HenVirtualCNode.SubType.INPUT_ACTION_CHECK,
			category = 'native',
			input_code_value_map = {
				method = 'is_action_pressed'
			},
			inputs = [
				{
					name = 'event',
					type = 'InputEvent'
				},
				{
					name = 'action',
					type = 'StringName',
					sub_type = '@dropdown',
					category = 'action'
				}
			],
			outputs = [
				{
					name = 'result',
					type = 'bool'
				}
			],
			route = null
		}
	},
	{
		name = 'On Action Released',
		icon = 'gamepad-2',
		color = '#f97316',
		is_native = true,
		data = {
			name = 'On Action Released',
			sub_type = HenVirtualCNode.SubType.INPUT_ACTION_CHECK,
			category = 'native',
			input_code_value_map = {
				method = 'is_action_released'
			},
			inputs = [
				{
					name = 'event',
					type = 'InputEvent'
				},
				{
					name = 'action',
					type = 'StringName',
					sub_type = '@dropdown',
					category = 'action'
				}
			],
			outputs = [
				{
					name = 'result',
					type = 'bool'
				}
			],
			route = null
		}
	},
	{
		name = 'Input Action Pressed',
		icon = 'gamepad-2',
		color = '#06b6d4',
		is_native = true,
		data = {
			name = 'Input Action Pressed',
			sub_type = HenVirtualCNode.SubType.INPUT_POLLING,
			category = 'native',
			input_code_value_map = {
				method = 'is_action_pressed'
			},
			inputs = [
				{
					name = 'action',
					type = 'StringName',
					sub_type = '@dropdown',
					category = 'action'
				}
			],
			outputs = [
				{
					name = 'result',
					type = 'bool'
				}
			],
			route = null
		}
	},
	{
		name = 'Input Action Just Pressed',
		icon = 'gamepad-2',
		color = '#06b6d4',
		is_native = true,
		data = {
			name = 'Input Action Just Pressed',
			sub_type = HenVirtualCNode.SubType.INPUT_POLLING,
			category = 'native',
			input_code_value_map = {
				method = 'is_action_just_pressed'
			},
			inputs = [
				{
					name = 'action',
					type = 'StringName',
					sub_type = '@dropdown',
					category = 'action'
				}
			],
			outputs = [
				{
					name = 'result',
					type = 'bool'
				}
			],
			route = null
		}
	},
	{
		name = 'Input Action Just Released',
		icon = 'gamepad-2',
		color = '#06b6d4',
		is_native = true,
		data = {
			name = 'Input Action Just Released',
			sub_type = HenVirtualCNode.SubType.INPUT_POLLING,
			category = 'native',
			input_code_value_map = {
				method = 'is_action_just_released'
			},
			inputs = [
				{
					name = 'action',
					type = 'StringName',
					sub_type = '@dropdown',
					category = 'action'
				}
			],
			outputs = [
				{
					name = 'result',
					type = 'bool'
				}
			],
			route = null
		}
	}
]


static func get_native_items() -> Array:
	return NATIVE_ITEMS


static func filter_by_connection(_io_type: StringName, _type: StringName) -> Array:
	var arr: Array = []

	for item: Dictionary in NATIVE_ITEMS:
		var has_valid_connection: bool = false
		var input_idx: int = -1
		var output_idx: int = -1

		if not _io_type:
			has_valid_connection = true
		elif _io_type == 'in':
			var params: Array = (item.data as Dictionary).get('outputs', [])
			output_idx = HenAPIProcessors.check_param_validity(params, _type, false)
			if output_idx != -1:
				has_valid_connection = true

		elif _io_type == 'out':
			var params: Array = (item.data as Dictionary).get('inputs', [])
			input_idx = HenAPIProcessors.check_param_validity(params, _type, true)
			if input_idx != -1:
				has_valid_connection = true

		if has_valid_connection:
			var new_item: Dictionary = item.duplicate()
			if input_idx != -1:
				new_item.input_io_idx = input_idx
			if output_idx != -1:
				new_item.output_io_idx = output_idx
			arr.append(new_item)

	return arr
