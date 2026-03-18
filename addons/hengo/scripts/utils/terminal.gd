@tool
class_name HenTerminal extends RichTextLabel

var global: HenGlobal

func _ready() -> void:
	if HenUtils.disable_scene_with_owner(self):
		return

	global = Engine.get_singleton(&'Global')
	text = global.terminal_content
	bbcode_enabled = true

func finish(_script_list: PackedStringArray) -> void:
	await RenderingServer.frame_pre_draw

	global.terminal_content += text + '\n\n# --------------------------------------------- #'

func clear_text() -> void:
	text = ''
