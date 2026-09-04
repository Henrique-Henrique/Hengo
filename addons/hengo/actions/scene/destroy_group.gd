@tool
class_name HenActionDestroyGroup extends HenScriptMacroBase


func get_id() -> StringName:
	return &'destroy_group'


func get_description() -> String:
	return 'Removes every node of a group from the scene at the end of the frame. It suits clearing all enemies or all bullets when a round ends.'


func get_display_name() -> String:
	return 'Destroy Group'


func get_icon() -> String:
	return 'trash-2'


func get_default_phase() -> StringName:
	return &'enter'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Group',
			type = 'StringName',
			id = &'group',
			picker = 'group',
			doc = 'The group whose nodes are removed.',
			default_value = 'enemies'
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
	return 'for node_{{VCNODE_ID}} in _ref.get_tree().get_nodes_in_group({{group}}):\n' \
		+ '\tnode_{{VCNODE_ID}}.queue_free()'
