@tool
class_name HenActionFlash extends HenActionTweenBase


# briefly tints a bound node toward Color and back, the hit feedback a character
# gets when damaged. runs once, so best on enter.


func get_id() -> StringName:
	return &'flash'


func get_description() -> String:
	return 'Briefly tints a node toward a color and back, the flash a character shows when it takes damage. Wire Finished and the flow moves on by itself when it ends, with no timer of your own. On enter it plays once; on update or physics it starts again as soon as the last one ended, so it keeps repeating while the state runs. Leaving the state before it ends puts the color back, so the node never stays on the flash color.'


func get_display_name() -> String:
	return 'Flash'


func get_icon() -> String:
	return 'sparkles'


func finishes_on_cancel() -> bool:
	return true


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Target',
			type = 'Node',
			id = &'target',
			doc = 'The node to flash. A 2D script tints it, a 3D one paints its material. Leave it empty to flash this node.',
			bind_only = true,
			optional = true,
			default_value = null
		},
		{
			name = 'Color',
			type = 'Color',
			id = &'color',
			doc = 'The color to flash toward.',
			default_value = Color(1, 0, 0, 1)
		},
		{
			name = 'Duration',
			type = 'float',
			id = &'duration',
			doc = 'How long the whole flash takes, in seconds.',
			default_value = 0.2
		}
	]




func get_flow_enter() -> String:
	return _body()


func get_flow_update() -> String:
	return guard_per_frame(_body())


func get_flow_physics() -> String:
	return guard_per_frame(_body())


# the class the script extends picks the side: a 3d one paints the material of
# the mesh, everything else tints through modulate. SpriteBase3D and Label3D are
# 3d nodes that still modulate, so they come before the mesh case
func _body() -> String:
	if targets(&'Node3D') and not (targets(&'SpriteBase3D') or targets(&'Label3D')):
		return 'var node_{{VCNODE_ID}} = {{target}}\n' \
			+ 'var flash_{{VCNODE_ID}}: Tween = null\n' \
			+ 'if node_{{VCNODE_ID}} is GeometryInstance3D:\n' \
			+ '\tif (node_{{VCNODE_ID}} as GeometryInstance3D).material_override == null:\n' \
			+ '\t\t(node_{{VCNODE_ID}} as GeometryInstance3D).material_override = StandardMaterial3D.new()\n' \
			+ '\tvar material_{{VCNODE_ID}} := (node_{{VCNODE_ID}} as GeometryInstance3D).material_override as StandardMaterial3D\n' \
			+ '\tif material_{{VCNODE_ID}}:\n' \
			+ '\t\tvar orig_{{VCNODE_ID}} = material_{{VCNODE_ID}}.albedo_color\n' \
			+ '\t\tflash_{{VCNODE_ID}} = _ref.create_tween()\n' \
			+ '\t\tflash_{{VCNODE_ID}}.tween_property(material_{{VCNODE_ID}}, "albedo_color", {{color}}, {{duration}} * 0.5)\n' \
			+ '\t\tflash_{{VCNODE_ID}}.tween_property(material_{{VCNODE_ID}}, "albedo_color", orig_{{VCNODE_ID}}, {{duration}} * 0.5)\n' \
			+ finish_hook('flash_{{VCNODE_ID}}')

	return 'var node_{{VCNODE_ID}} = {{target}}\n' \
		+ 'var orig_{{VCNODE_ID}} = node_{{VCNODE_ID}}.modulate\n' \
		+ 'var flash_{{VCNODE_ID}} = _ref.create_tween()\n' \
		+ 'flash_{{VCNODE_ID}}.tween_property(node_{{VCNODE_ID}}, "modulate", {{color}}, {{duration}} * 0.5)\n' \
		+ 'flash_{{VCNODE_ID}}.tween_property(node_{{VCNODE_ID}}, "modulate", orig_{{VCNODE_ID}}, {{duration}} * 0.5)\n' \
		+ finish_hook('flash_{{VCNODE_ID}}')
