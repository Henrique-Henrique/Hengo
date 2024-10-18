@tool
extends SpinBox

func _ready() -> void:
	var line_edit: LineEdit = get_line_edit()

	line_edit.expand_to_text_length = true
	step = 0.00000001


# public
#
func set_default(_num: String) -> void:
	value = float(_num)

# func get_value(): native

func get_generated_code() -> String:
	return str(value)