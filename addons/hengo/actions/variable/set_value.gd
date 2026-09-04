@tool
class_name HenActionSetValue extends HenScriptMacroBase


# native test action: writes Value into Target.
# Target must be BOUND to a variable/property (it becomes the assignment lvalue
# `_ref.<name>`); an unbound Target is reported as unresolved.
# body has no delta, so it works in every lifecycle phase.


func get_id() -> StringName:
	return &'set_value'


func get_description() -> String:
	return 'Sets a variable or property to a value.'


func get_icon() -> String:
	return 'equal'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Target',
			type = 'Variant',
			id = &'target',
				doc = 'The variable or property to write to.',
			lvalue = true,
			default_value = null
		},
		{
			name = 'Value',
			type = 'Variant',
			id = &'value',
				doc = 'The value to store.',
			# effective type follows whatever Target is bound to (var/prop)
			type_from = &'target',
			default_value = 0
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
	return '{{target}} = {{value}}'


func get_flow_update() -> String:
	return '{{target}} = {{value}}'


func get_flow_physics() -> String:
	return '{{target}} = {{value}}'


func get_flow_exit() -> String:
	return '{{target}} = {{value}}'
