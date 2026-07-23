@tool
extends HenScriptMacroBase

# test fixture: declares no flow inputs, so its body comes from the _process
# override — update only. asking it for an enter/exit body must fail loudly.


func get_id() -> StringName:
	return &'test_action_process'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Speed',
			type = 'float',
			id = &'speed',
			default_value = 90.0
		}
	]


func get_function_overrides() -> Array[Dictionary]:
	return [
		{
			name = '_process',
			params = [ {name = 'delta', type = 'float'} ],
			body = 'test_process({{speed}} * delta)'
		}
	]
