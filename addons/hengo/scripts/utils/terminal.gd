@tool
class_name HenTerminal extends RichTextLabel

var global: HenGlobal


func _init(_use_old: bool = true) -> void:
	global = Engine.get_singleton(&'Global')

	if _use_old:
		text = global.terminal_content


func _ready() -> void:
	if HenUtils.disable_scene_with_owner(self):
		return

	bbcode_enabled = true

func finish(_script_list: PackedStringArray) -> void:
	await RenderingServer.frame_pre_draw

	if global.terminal_content.length() > 10000:
		global.terminal_content = global.terminal_content.substr(0, 10000)

	global.terminal_content += text + '\n\n# --------------------------------------------- #'

func clear_text() -> void:
	text = ''
