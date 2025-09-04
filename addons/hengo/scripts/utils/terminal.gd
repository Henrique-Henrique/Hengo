@tool
extends RichTextLabel


func _ready() -> void:
	HenGlobal.SIGNAL_BUS.set_terminal_text.connect(add_custom_text)
	HenGlobal.SIGNAL_BUS.scripts_generation_finished.connect(finish)


func finish(_script_list: PackedStringArray) -> void:
	var time: SceneTreeTimer = get_tree().create_timer(10)
	time.timeout.connect(clear_text)

func clear_text() -> void:
	text = ''

func add_custom_text(_message: String) -> void:
	text += '\n' + _message