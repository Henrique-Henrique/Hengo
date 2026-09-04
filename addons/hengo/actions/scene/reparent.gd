@tool
class_name HenActionReparent extends HenScriptMacroBase


# moves Node under New Parent while keeping its place on screen. both are bound
# by variable or node path.


func get_id() -> StringName:
	return &'reparent'


func get_description() -> String:
	return 'Moves a node under a new parent while keeping it in the same place on screen. Useful to pick up an item into a hand or a slot.'


func get_display_name() -> String:
	return 'Change Parent'


func get_icon() -> String:
	return 'move'


func get_default_phase() -> StringName:
	return &'enter'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Node',
			type = 'Node',
			id = &'node',
			doc = 'The node to move. Leave it empty to move this node.',
			bind_only = true,
			optional = true,
			default_value = null
		},
		{
			name = 'New Parent',
			type = 'Node',
			id = &'new_parent',
			doc = 'The node it becomes a child of.',
			bind_only = true,
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
	return '{{node}}.reparent({{new_parent}})'
