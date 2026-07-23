@tool
extends HenScriptMacroBase

# test fixture: Value's effective type follows whatever Target is bound to


func get_id() -> StringName:
	return &'test_action_typed'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Target',
			type = 'Variant',
			id = &'target',
			default_value = null
		},
		{
			name = 'Value',
			type = 'Variant',
			id = &'value',
			type_from = &'target',
			default_value = 0
		}
	]


func get_flow_inputs() -> Array[Dictionary]:
	return [ {name = 'Update', id = &'update'}]


func get_flow_update() -> String:
	return '{{target}} = {{value}}'
