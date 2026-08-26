@tool
class_name HenActionClearChildren extends HenScriptMacroBase


func get_id() -> StringName:
	return &'clear_children'


func get_description() -> String:
	return 'Removes every child of a node at the end of the frame. It is the pair of Spawn Into, which fills the same list again.'


func get_display_name() -> String:
	return 'Clear Children'


func get_icon() -> String:
	return 'list-x'


func get_default_phase() -> StringName:
	return &'enter'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Parent',
			type = 'Node',
			id = &'parent',
			doc = 'The node whose children are removed. Leave it empty to clear this node.',
			bind_only = true,
			optional = true,
			default_value = null
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
	return 'for child_{{VCNODE_ID}} in {{parent}}.get_children():\n' \
		+ '\tchild_{{VCNODE_ID}}.queue_free()'
