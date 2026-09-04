@tool
class_name HenActionTweenColor extends HenActionTweenBase


func get_id() -> StringName:
	return &'tween_color'


func get_description() -> String:
	return 'Smoothly blends the color of a node toward a target color over time. Wire Finished and the flow moves on by itself when it ends, with no timer of your own. On enter it plays once; on update or physics it starts again as soon as the last one ended, so it keeps repeating while the state runs.'


func get_display_name() -> String:
	return 'Tween Color'


func get_icon() -> String:
	return 'palette'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Target',
			type = 'Node',
			id = &'target',
			doc = 'The node to fade to a color. Leave it empty to fade this node.',
			bind_only = true,
			optional = true,
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




func get_flow_enter() -> String:
	return _body()


func get_flow_update() -> String:
	return guard_per_frame(_body())


func get_flow_physics() -> String:
	return guard_per_frame(_body())


# SpriteBase3D and Label3D also inherit GeometryInstance3D
func _body() -> String:
	if targets(&'Node3D') and not (targets(&'SpriteBase3D') or targets(&'Label3D')):
		return 'var node_{{VCNODE_ID}} = {{target}}\n' \
			+ 'var mat_{{VCNODE_ID}} := (node_{{VCNODE_ID}} as GeometryInstance3D).material_override as StandardMaterial3D\n' \
			+ 'var fade_{{VCNODE_ID}} = _ref.create_tween()\n' \
			+ 'if mat_{{VCNODE_ID}}:\n' \
			+ '\tfade_{{VCNODE_ID}}.tween_property(mat_{{VCNODE_ID}}, "albedo_color", {{to}}, {{duration}})\n' \
			+ finish_hook('fade_{{VCNODE_ID}}')

	return 'var node_{{VCNODE_ID}} = {{target}}\n' \
		+ 'var fade_{{VCNODE_ID}} = _ref.create_tween()\n' \
		+ 'fade_{{VCNODE_ID}}.tween_property(node_{{VCNODE_ID}}, "modulate", {{to}}, {{duration}})\n' \
		+ finish_hook('fade_{{VCNODE_ID}}')
