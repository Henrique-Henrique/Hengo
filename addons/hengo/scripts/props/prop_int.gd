@tool
extends SpinBox


func _ready() -> void:
	var line_edit: LineEdit = get_line_edit()

	line_edit.expand_to_text_length = true

# public
#
func set_font_size(_size: int) -> void:
	var line_edit: LineEdit = get_line_edit()
	line_edit.add_theme_font_size_override('font_size', _size)

# public
#
func set_default(_num: String) -> void:
	value = int(_num)

# func get_value(): native

func get_generated_code() -> String:
	return str(value)