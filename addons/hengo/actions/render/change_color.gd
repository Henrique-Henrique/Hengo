@tool
class_name HenActionChangeColor extends HenScriptMacroBase


# tints the owner, dispatching on the class the script extends: lights, sprites
# and shape nodes each get their own color property, the rest falls back to modulate.


func get_id() -> StringName:
	return &'change_color'


func get_description() -> String:
	return 'Sets the color of the node, choosing the right property for its type such as a light, sprite or shape. Falls back to tinting through modulate for other nodes.'


func get_display_name() -> String:
	return 'Change Color'


func get_icon() -> String:
	return 'palette'


# CanvasItem covers 2d nodes and Control; Node3D covers 3d. anything without a
# dedicated color prop falls back to modulate
func get_target_classes() -> Array[StringName]:
	return [&'CanvasItem', &'Node3D']


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Color',
			type = 'Color',
			id = &'color',
				doc = 'The color to apply.',
			default_value = Color(1, 1, 1, 1)
		}
	]


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'},
		{name = 'Exit', id = &'exit'}
	]


func get_flow_enter() -> String:
	return _get_body()


func get_flow_update() -> String:
	return _get_body()


func get_flow_exit() -> String:
	return _get_body()


# each node exposes color differently, so dispatch specific bases before the
# generic node2d/node3d fallbacks
func _get_body() -> String:
	# 3d: lights and sprites own a color prop, geometry needs a material override
	if targets(&'Light3D'):
		return '(_ref as Light3D).light_color = {{color}}'
	if targets(&'SpriteBase3D'):
		return '(_ref as SpriteBase3D).modulate = {{color}}'
	if targets(&'Label3D'):
		return '(_ref as Label3D).modulate = {{color}}'
	if targets(&'Node3D'):
		return 'if _ref is GeometryInstance3D and (_ref as GeometryInstance3D).material_override == null:\n\t(_ref as GeometryInstance3D).material_override = StandardMaterial3D.new()\nvar material_{{VCNODE_ID}}: Material = (_ref as GeometryInstance3D).material_override if _ref is GeometryInstance3D else null\nif material_{{VCNODE_ID}} is StandardMaterial3D:\n\t(material_{{VCNODE_ID}} as StandardMaterial3D).albedo_color = {{color}}'

	# 2d: lights, canvas modulate and shapes own a color prop, the rest tints
	if targets(&'Light2D'):
		return '(_ref as Light2D).color = {{color}}'
	if targets(&'CanvasModulate'):
		return '(_ref as CanvasModulate).color = {{color}}'
	if targets(&'Polygon2D'):
		return '(_ref as Polygon2D).color = {{color}}'
	if targets(&'Line2D'):
		return '(_ref as Line2D).default_color = {{color}}'

	return '_ref.modulate = {{color}}'
