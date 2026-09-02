@tool
class_name HenActionDrawLineTo extends HenScriptMacroBase


func get_id() -> StringName:
	return &'draw_line_to'


func get_description() -> String:
	return 'Draws a line from this node to a point while the state runs, and clears it when the state ends. Pointing To at the node being chased shows what it is going after.'


func get_display_name() -> String:
	return 'Draw Line To'


func get_icon() -> String:
	return 'spline'


func get_target_classes() -> Array[StringName]:
	return [&'Node2D']


func get_default_phase() -> StringName:
	return &'update'


func get_inputs() -> Array[Dictionary]:
	return [
		node_ref_input('The node the line starts at. Leave it empty to start at this node.'),
		{
			name = 'To',
			type = 'Vector2',
			id = &'to',
			doc = 'The point in world space the line ends at.',
			default_value = Vector2.ZERO
		},
		{
			name = 'Color',
			type = 'Color',
			id = &'color',
			doc = 'The color of the line.',
			default_value = Color(1, 1, 1, 0.5)
		},
		{
			name = 'Width',
			type = 'float',
			id = &'width',
			doc = 'How thick the line is, in pixels.',
			default_value = 3.0
		}
	]


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'}
	]


func get_script_base() -> String:
	return 'var line_{{VCNODE_ID}}: Line2D = null'


func get_flow_teardown() -> String:
	return 'if is_instance_valid(line_{{VCNODE_ID}}):\n' \
		+ '\tline_{{VCNODE_ID}}.queue_free()\n' \
		+ 'line_{{VCNODE_ID}} = null'


func get_flow_enter() -> String:
	return _body()


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


# to_local keeps the line pointing at the world position however the node is turned
func _body() -> String:
	return 'if not is_instance_valid(line_{{VCNODE_ID}}):\n' \
		+ '\tline_{{VCNODE_ID}} = Line2D.new()\n' \
		+ '\tline_{{VCNODE_ID}}.show_behind_parent = true\n' \
		+ '\t{{ref}}.add_child.call_deferred(line_{{VCNODE_ID}})\n' \
		+ 'line_{{VCNODE_ID}}.default_color = {{color}}\n' \
		+ 'line_{{VCNODE_ID}}.width = {{width}}\n' \
		+ 'line_{{VCNODE_ID}}.points = PackedVector2Array([Vector2.ZERO, {{ref}}.to_local({{to}})])'
