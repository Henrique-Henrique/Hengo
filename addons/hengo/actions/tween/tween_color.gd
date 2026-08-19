@tool
class_name HenActionTweenColor extends HenScriptMacroBase


func get_id() -> StringName:
	return &'tween_color'


func get_description() -> String:
	return 'Smoothly blends the color of a node toward a target color over time. Runs once when the state starts.'


func get_display_name() -> String:
	return 'Tween Color'


func get_icon() -> String:
	return 'palette'


func get_default_phase() -> StringName:
	return &'enter'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Target',
			type = 'Node',
			id = &'target',
			doc = 'The node to tint, such as a sprite, a Control or a 3d mesh.',
			bind_only = true,
			default_value = null
		},
		{
			name = 'To',
			type = 'Color',
			id = &'to',
			doc = 'The color the node ends at.',
			default_value = Color(1, 1, 1, 1)
		},
		{
			name = 'Duration',
			type = 'float',
			id = &'duration',
			doc = 'How long the blend takes, in seconds.',
			default_value = 0.3
		}
	]


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'}
	]


func get_flow_enter() -> String:
	return _body()


# SpriteBase3D and Label3D also inherit GeometryInstance3D
func _body() -> String:
	return 'var node_{{VCNODE_ID}} = {{target}}\n' \
		+ 'var mat_{{VCNODE_ID}}: Material = (node_{{VCNODE_ID}} as GeometryInstance3D).material_override if node_{{VCNODE_ID}} is GeometryInstance3D else null\n' \
		+ 'if mat_{{VCNODE_ID}} is StandardMaterial3D and not (node_{{VCNODE_ID}} is SpriteBase3D or node_{{VCNODE_ID}} is Label3D):\n' \
		+ '\t_ref.create_tween().tween_property(mat_{{VCNODE_ID}}, "albedo_color", {{to}}, {{duration}})\n' \
		+ 'else:\n' \
		+ '\t_ref.create_tween().tween_property(node_{{VCNODE_ID}}, "modulate", {{to}}, {{duration}})'
