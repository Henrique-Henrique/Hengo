@tool
extends LineEdit

signal value_changed

func _ready() -> void:
	text_changed.connect(_on_change)

func _on_change(_text: String) -> void:
	emit_signal('value_changed', _text)

# public
#
func set_default(_text: String) -> void:
	text = _text

func get_value() -> String:
	return text

func get_generated_code() -> String:
	return '\"' + text + '\"'