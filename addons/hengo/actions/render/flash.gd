@tool
class_name HenActionFlash extends HenScriptMacroBase


# briefly tints a bound node toward Color and back, the hit feedback a character
# gets when damaged. runs once, so best on enter.


func get_id() -> StringName:
	return &'flash'


func get_description() -> String:
	return 'Briefly tints a node toward a color and back, the flash a character shows when it takes damage. Runs once when the state starts.'


func get_display_name() -> String:
	return 'Flash'


func get_icon() -> String:
	return 'sparkles'


func get_default_phase() -> StringName:
	return &'enter'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Target',
			type = 'Node',
			id = &'target',
			doc = 'The node to flash.',
			bind_only = true,
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


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'}
	]


func get_flow_enter() -> String:
	return _body()


# SpriteBase3D and Label3D also inherit GeometryInstance3D
func _body() -> String:
	return 'var node_{{VCNODE_ID}} = {{target}}\n' \
		+ 'if node_{{VCNODE_ID}} is CanvasItem or node_{{VCNODE_ID}} is SpriteBase3D or node_{{VCNODE_ID}} is Label3D:\n' \
		+ '\tvar orig_{{VCNODE_ID}} = node_{{VCNODE_ID}}.modulate\n' \
		+ '\tvar flash_{{VCNODE_ID}} = _ref.create_tween()\n' \
		+ '\tflash_{{VCNODE_ID}}.tween_property(node_{{VCNODE_ID}}, "modulate", {{color}}, {{duration}} * 0.5)\n' \
		+ '\tflash_{{VCNODE_ID}}.tween_property(node_{{VCNODE_ID}}, "modulate", orig_{{VCNODE_ID}}, {{duration}} * 0.5)\n' \
		+ 'elif node_{{VCNODE_ID}} is GeometryInstance3D:\n' \
		+ '\tif (node_{{VCNODE_ID}} as GeometryInstance3D).material_override == null:\n' \
		+ '\t\t(node_{{VCNODE_ID}} as GeometryInstance3D).material_override = StandardMaterial3D.new()\n' \
		+ '\tvar material_{{VCNODE_ID}} := (node_{{VCNODE_ID}} as GeometryInstance3D).material_override as StandardMaterial3D\n' \
		+ '\tif material_{{VCNODE_ID}}:\n' \
		+ '\t\tvar orig_{{VCNODE_ID}} = material_{{VCNODE_ID}}.albedo_color\n' \
		+ '\t\tvar flash_{{VCNODE_ID}} = _ref.create_tween()\n' \
		+ '\t\tflash_{{VCNODE_ID}}.tween_property(material_{{VCNODE_ID}}, "albedo_color", {{color}}, {{duration}} * 0.5)\n' \
		+ '\t\tflash_{{VCNODE_ID}}.tween_property(material_{{VCNODE_ID}}, "albedo_color", orig_{{VCNODE_ID}}, {{duration}} * 0.5)'
