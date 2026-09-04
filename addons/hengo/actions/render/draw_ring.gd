@tool
class_name HenActionDrawRing extends HenScriptMacroBase


func get_id() -> StringName:
	return &'draw_ring'


func get_description() -> String:
	return 'Draws a circle around this node while the state runs, and clears it when the state ends. With Radius = 220 it shows how far a detection range actually reaches.'


func get_display_name() -> String:
	return 'Draw Ring'


func get_icon() -> String:
	return 'radar'


func get_target_classes() -> Array[StringName]:
	return [&'Node2D']


func get_default_phase() -> StringName:
	return &'update'


func get_inputs() -> Array[Dictionary]:
	return [
		node_ref_input('The node at the center. Leave it empty to circle this node.'),
		{
			name = 'Radius',
			type = 'float',
			id = &'radius',
			doc = 'How far the circle reaches, in pixels.',
			default_value = 100.0
		},
		{
			name = 'Color',
			type = 'Color',
			id = &'color',
			doc = 'The color of the circle.',
			default_value = Color(1, 1, 1, 0.25)
		},
		{
			name = 'Width',
			type = 'float',
			id = &'width',
			doc = 'How thick the circle line is, in pixels.',
			default_value = 2.0
		}
	]


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'}
	]


func get_script_base() -> String:
	return 'var ring_{{VCNODE_ID}}: Line2D = null'


func get_flow_teardown() -> String:
	return 'if is_instance_valid(ring_{{VCNODE_ID}}):\n' \
		+ '\tring_{{VCNODE_ID}}.queue_free()\n' \
		+ 'ring_{{VCNODE_ID}} = null'


func get_flow_enter() -> String:
	return _body()


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


# 33 points instead of 32: the last one repeats the first and closes the circle
func _body() -> String:
	return 'if not is_instance_valid(ring_{{VCNODE_ID}}):\n' \
		+ '\tring_{{VCNODE_ID}} = Line2D.new()\n' \
		+ '\tring_{{VCNODE_ID}}.show_behind_parent = true\n' \
		+ '\t{{ref}}.add_child.call_deferred(ring_{{VCNODE_ID}})\n' \
		+ 'ring_{{VCNODE_ID}}.default_color = {{color}}\n' \
		+ 'ring_{{VCNODE_ID}}.width = {{width}}\n' \
		+ 'var points_{{VCNODE_ID}}: PackedVector2Array = PackedVector2Array()\n' \
		+ 'for step_{{VCNODE_ID}}: int in 33:\n' \
		+ '\tpoints_{{VCNODE_ID}}.append(Vector2.RIGHT.rotated(TAU * step_{{VCNODE_ID}} / 32.0) * {{radius}})\n' \
		+ 'ring_{{VCNODE_ID}}.points = points_{{VCNODE_ID}}'
