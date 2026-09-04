@tool
extends HenScriptMacroBase

# test fixture: an action macro whose input is emitted verbatim (raw), plus a
# quoted twin to prove the flag is what changes the output.
# no class_name on purpose — fixtures shouldn't pollute the global class list.


func get_id() -> StringName:
	return &'test_action_raw'


func get_display_name() -> String:
	return 'Raw Fixture'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Code',
			type = 'String',
			id = &'code',
			raw = true,
			default_value = 'pass'
		},
		{
			name = 'Text',
			type = 'String',
			id = &'text',
			default_value = 'pass'
		}
	]


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Update', id = &'update'}
	]


func get_flow_update() -> String:
	return 'test_raw({{code}}, {{text}})'
