@tool
class_name HenActionExists extends HenScriptMacroBase


func get_id() -> StringName:
	return &'exists'


func get_description() -> String:
	return 'Stores whether an object still points at a live instance. It is the Is Valid answer as a value, to feed Do If or Combine Checks.'


func get_display_name() -> String:
	return 'Exists'


func get_icon() -> String:
	return 'circle-check'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Object',
			type = 'Variant',
			id = &'object',
			doc = 'The variable holding the object to check.',
			bind_only = true,
			default_value = null
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Result', type = 'bool', id = &'result', doc = 'True while the object is alive.'}
	]


func get_output_result() -> String:
	return 'is_instance_valid({{object}})'


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
	return '{{out:result}}'
