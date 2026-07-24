@tool
class_name HenActionRawCode extends HenScriptMacroBase


# emits a GDScript statement verbatim — the escape hatch for anything the other
# actions don't cover. use `_ref` to reach the owner node (e.g. `_ref.queue_free()`).


func get_id() -> StringName:
	return &'raw_code'


func get_description() -> String:
	return 'Runs a line of GDScript exactly as written. An escape hatch for anything the other actions do not cover.'


func get_icon() -> String:
	return 'code'


# raw = emitted as written, never quoted as a string literal
func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Code',
			type = 'String',
			id = &'code',
			doc = 'The GDScript line to run. Use _ref to reach the owner node.',
			raw = true,
			default_value = 'pass'
		}
	]


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'},
		{name = 'Exit', id = &'exit'}
	]


func get_flow_enter() -> String:
	return '{{code}}'


func get_flow_update() -> String:
	return '{{code}}'


func get_flow_exit() -> String:
	return '{{code}}'
