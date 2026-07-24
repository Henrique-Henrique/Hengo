@tool
class_name HenActionGetNearest extends HenScriptMacroBase


# writes the closest node of Group (excluding the owner) into Nearest, by
# global-space distance. works for Node2D and Node3D alike.


func get_id() -> StringName:
	return &'get_nearest'


func get_display_name() -> String:
	return 'Get Nearest'


func get_icon() -> String:
	return 'radar'


func get_target_classes() -> Array[StringName]:
	return [&'Node2D', &'Node3D']


func get_default_phase() -> StringName:
	return &'update'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Group',
			type = 'StringName',
			id = &'group',
			default_value = 'enemies'
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Nearest', type = 'Object', id = &'nearest'}
	]


func get_output_nearest() -> String:
	return 'best_{{VCNODE_ID}}'


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


# scans the group once, keeping the smallest distance; the owner is skipped so it
# never picks itself. the result lands in {{out:nearest}} when a var is bound
func _body() -> String:
	return 'var best_{{VCNODE_ID}} = null\n' \
		+ 'var best_dist_{{VCNODE_ID}} = INF\n' \
		+ 'for node_{{VCNODE_ID}} in _ref.get_tree().get_nodes_in_group({{group}}):\n' \
		+ '\tif node_{{VCNODE_ID}} == _ref:\n' \
		+ '\t\tcontinue\n' \
		+ '\tvar d_{{VCNODE_ID}} = _ref.global_position.distance_to(node_{{VCNODE_ID}}.global_position)\n' \
		+ '\tif d_{{VCNODE_ID}} < best_dist_{{VCNODE_ID}}:\n' \
		+ '\t\tbest_dist_{{VCNODE_ID}} = d_{{VCNODE_ID}}\n' \
		+ '\t\tbest_{{VCNODE_ID}} = node_{{VCNODE_ID}}\n' \
		+ '{{out:nearest}}'
