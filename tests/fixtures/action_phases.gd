@tool
extends HenScriptMacroBase

# test fixture: an action macro that supports all three lifecycle phases.
# no class_name on purpose — fixtures shouldn't pollute the global class list.


func get_id() -> StringName:
	return &'test_action_phases'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Value',
			type = 'Variant',
			id = &'value',
			default_value = 'hi'
		}
	]


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'},
		{name = 'Exit', id = &'exit'}
	]


func get_flow_enter() -> String:
	return 'test_enter({{value}})'


func get_flow_update() -> String:
	return 'test_update({{value}})'


func get_flow_exit() -> String:
	return 'test_exit({{value}})'
