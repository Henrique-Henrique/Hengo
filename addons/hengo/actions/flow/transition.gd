@tool
class_name HenActionTransition extends HenScriptMacroBase


# unconditional transition: its single flow output is a branch bound to a state,
# sub-state or a state of another script, set per action in the inspector.


func get_id() -> StringName:
	return &'transition'


func get_description() -> String:
	return 'Immediately transitions to another state, sub-state, or a state of another script.'


func get_display_name() -> String:
	return 'Transition'


func get_icon() -> String:
	return 'arrow-right-to-line'


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'}
	]


# the only flow output; the action binds it to the target state
func get_flow_outputs() -> Array[Dictionary]:
	return [
		{name = 'To', id = &'to', doc = 'Where to transition to.'}
	]


func get_flow_enter() -> String:
	return '{{to}}'


func get_flow_update() -> String:
	return '{{to}}'


func get_flow_physics() -> String:
	return '{{to}}'
