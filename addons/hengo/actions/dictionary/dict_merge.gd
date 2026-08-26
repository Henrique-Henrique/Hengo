@tool
class_name HenActionDictMerge extends HenScriptMacroBase


# copies every pair of Other into Dictionary. Dictionary must be bound to a
# variable/property. Overwrite decides what happens on a shared key.


func get_id() -> StringName:
	return &'dict_merge'


func get_description() -> String:
	return 'Copies all pairs from another dictionary into this one. Overwrite decides whether a shared key keeps the old value or takes the new one.'


func get_display_name() -> String:
	return 'Dictionary Merge'


func get_icon() -> String:
	return 'git-merge'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Dictionary',
			type = 'Dictionary',
			id = &'dict',
			doc = 'The dictionary that receives the pairs. Must be bound to a variable or property.',
			bind_only = true,
			default_value = null
		},
		{
			name = 'Other',
			type = 'Dictionary',
			id = &'other',
			doc = 'The dictionary to copy pairs from.',
			bind_only = true,
			default_value = null
		},
		{
			name = 'Overwrite',
			type = 'bool',
			id = &'overwrite',
			doc = 'True to let shared keys take the new value, false to keep the old one.',
			default_value = true
		}
	]


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
	return '{{dict}}.merge({{other}}, {{overwrite}})'
