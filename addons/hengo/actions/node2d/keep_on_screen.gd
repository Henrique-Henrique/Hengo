@tool
class_name HenActionKeepOnScreen extends HenScriptMacroBase


func get_id() -> StringName:
	return &'keep_on_screen'


func get_description() -> String:
	return 'Holds the node inside the screen, stopping it at the edge instead of letting it leave. Assumes a fixed screen with no scrolling camera.'


func get_display_name() -> String:
	return 'Keep On Screen'


func get_icon() -> String:
	return 'crop'


func get_target_classes() -> Array[StringName]:
	return [&'Node2D']


func get_default_phase() -> StringName:
	return &'physics'


func get_inputs() -> Array[Dictionary]:
	return [
		node_ref_input('The node to keep on screen. Leave it empty to keep this node.'),
		{
			name = 'Margin',
			type = 'float',
			id = &'margin',
			doc = 'How far inside each edge the node stops, in pixels.',
			default_value = 0.0
		}
	]


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'}
	]


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


# global_position hands back a copy, so a component is written back whole
func _body() -> String:
	return 'var rect_{{VCNODE_ID}} = _ref.get_viewport_rect().grow(-{{margin}})\n' \
		+ 'var pos_{{VCNODE_ID}} = {{ref}}.global_position\n' \
		+ 'pos_{{VCNODE_ID}}.x = clampf(pos_{{VCNODE_ID}}.x, rect_{{VCNODE_ID}}.position.x, rect_{{VCNODE_ID}}.end.x)\n' \
		+ 'pos_{{VCNODE_ID}}.y = clampf(pos_{{VCNODE_ID}}.y, rect_{{VCNODE_ID}}.position.y, rect_{{VCNODE_ID}}.end.y)\n' \
		+ '{{ref}}.global_position = pos_{{VCNODE_ID}}'
