@tool
class_name HenActionChangeValue extends HenScriptMacroBase


# applies Operator with Amount to Target and stores the result back, clamped to
# Min..Max. it is the `max(0, hp - dmg)` / `min(max_hp, hp + heal)` pattern that
# resources need, in one step instead of an add plus a separate clamp.


func get_id() -> StringName:
	return &'change_value'


func get_description() -> String:
	return 'Changes a variable by an amount and keeps the result within Min and Max. This is the one-step way to spend, damage or heal without letting a value run past zero or a cap.'


func get_display_name() -> String:
	return 'Adjust Value'


func get_icon() -> String:
	return 'plus'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Target',
			type = 'Variant',
			id = &'target',
			doc = 'The variable or property to change.',
			lvalue = true,
			default_value = null
		},
		{
			name = 'Operator',
			type = 'String',
			id = &'op',
			doc = 'How the amount changes the value.',
			raw = true,
			options = ['+', '-', '*'],
			default_value = '+'
		},
		{
			name = 'Amount',
			type = 'Variant',
			id = &'amount',
			doc = 'How much to change it by.',
			type_from = &'target',
			default_value = 1
		},
		{
			name = 'Min',
			type = 'Variant',
			id = &'min',
			doc = 'The lowest the result may reach.',
			type_from = &'target',
			default_value = 0
		},
		{
			name = 'Max',
			type = 'Variant',
			id = &'max',
			doc = 'The highest the result may reach.',
			type_from = &'target',
			default_value = 100
		}
	]


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'},
		{name = 'Exit', id = &'exit'}
	]


func get_flow_enter() -> String:
	return _body()


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


func get_flow_exit() -> String:
	return _body()


func _body() -> String:
	return '{{target}} = clamp({{target}} {{op}} {{amount}}, {{min}}, {{max}})'
