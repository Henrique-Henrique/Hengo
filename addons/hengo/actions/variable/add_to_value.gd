@tool
class_name HenActionAddToValue extends HenScriptMacroBase


# accumulates Amount into Target. Target must be BOUND to a variable/property
# (it becomes the assignment lvalue `_ref.<name>`); an unbound Target is reported
# as unresolved. body has no delta, so it works in every phase.


func get_id() -> StringName:
	return &'add_to_value'


func get_icon() -> String:
	return 'plus'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Target',
			type = 'Variant',
			id = &'target',
			lvalue = true,
			default_value = null
		},
		{
			name = 'Amount',
			type = 'Variant',
			id = &'amount',
			# effective type follows whatever Target is bound to (var/prop)
			type_from = &'target',
			default_value = 1
		}
	]


# lifecycle phases this action supports
func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'},
		{name = 'Exit', id = &'exit'}
	]


func get_flow_enter() -> String:
	return '{{target}} += {{amount}}'


func get_flow_update() -> String:
	return '{{target}} += {{amount}}'


func get_flow_exit() -> String:
	return '{{target}} += {{amount}}'
