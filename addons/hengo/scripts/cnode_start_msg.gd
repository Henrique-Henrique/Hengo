@tool
extends RichTextLabel

func _ready() -> void:
	meta_clicked.connect(_on_meta)


func _on_meta(_content) -> void:
	OS.shell_open(str(_content))