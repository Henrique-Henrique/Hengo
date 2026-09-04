@tool
class_name HenActionFadeToScene extends HenScriptMacroBase


func get_id() -> StringName:
	return &'fade_to_scene'


func get_description() -> String:
	return 'Fades the screen to a solid color and then loads another scene. The overlay is freed together with the current scene.'


func get_display_name() -> String:
	return 'Fade To Scene'


func get_icon() -> String:
	return 'blend'


func get_default_phase() -> StringName:
	return &'enter'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Scene Path',
			type = 'String',
			id = &'path',
			picker = 'scene_path',
			doc = 'The path to the scene file to load when the fade ends.',
			default_value = 'res://scenes/level.tscn'
		},
		{
			name = 'Duration',
			type = 'float',
			id = &'duration',
			doc = 'How long the fade takes, in seconds.',
			default_value = 0.5
		},
		{
			name = 'Color',
			type = 'Color',
			id = &'color',
			doc = 'The color the screen fades to.',
			default_value = Color(0, 0, 0, 1)
		}
	]


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'}
	]


func get_flow_enter() -> String:
	return _body()


# deferred because running this in enter happens during _ready, where add_child is refused
func _body() -> String:
	return 'var layer_{{VCNODE_ID}} = CanvasLayer.new()\n' \
		+ 'layer_{{VCNODE_ID}}.layer = 128\n' \
		+ 'var fade_{{VCNODE_ID}} = ColorRect.new()\n' \
		+ 'fade_{{VCNODE_ID}}.color = Color({{color}}, 0.0)\n' \
		+ 'fade_{{VCNODE_ID}}.mouse_filter = Control.MOUSE_FILTER_IGNORE\n' \
		+ 'fade_{{VCNODE_ID}}.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)\n' \
		+ 'layer_{{VCNODE_ID}}.add_child(fade_{{VCNODE_ID}})\n' \
		+ '_ref.get_tree().current_scene.add_child.call_deferred(layer_{{VCNODE_ID}})\n' \
		+ 'var tween_{{VCNODE_ID}} = _ref.create_tween()\n' \
		+ 'tween_{{VCNODE_ID}}.tween_property(fade_{{VCNODE_ID}}, "color:a", 1.0, {{duration}})\n' \
		+ 'tween_{{VCNODE_ID}}.tween_callback(_ref.get_tree().change_scene_to_file.bind({{path}}))'
