@tool
class_name HenActionAddToValue extends HenScriptMacroBase


# accumulates Amount into Target. Target must be BOUND to a variable/property
# (it becomes the assignment lvalue `_ref.<name>`); an unbound Target is reported
# as unresolved. body has no delta, so it works in every phase.


func get_id() -> StringName:
	return &'add_to_value'


func get_description() -> String:
	return 'Adds an amount to a variable or property, accumulating the result each time it runs.'


func get_icon() -> String:
	return 'plus'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Target',
			type = 'Variant',
			id = &'target',
				doc = 'The variable or property to add to.',
			lvalue = true,
			default_value = null
		},
		{
			name = 'Amount',
			type = 'Variant',
			id = &'amount',
				doc = 'The amount to add each time.',
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
		{name = 'Physics', id = &'physics'},
		{name = 'Exit', id = &'exit'}
	]


func get_flow_enter() -> String:
	return '{{target}} += {{amount}}'


func get_flow_update() -> String:
	return '{{target}} += {{amount}}'


func get_flow_physics() -> String:
	return '{{target}} += {{amount}}'


func get_flow_exit() -> String:
	return '{{target}} += {{amount}}'
