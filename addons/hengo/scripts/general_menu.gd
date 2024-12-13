@tool
extends PopupMenu

var data: Dictionary = {}

func _ready() -> void:
	id_pressed.connect(_on_select)


func _on_select(id: int) -> void:
	data[id].call.call()


func show_menu(_config: Dictionary) -> void:
	clear()
	data = {}

	var idx: int = 0
	for item in _config.list:
		add_item(item.name)
		data[idx] = item

		idx += 1
	
	position = get_viewport().get_window().position + Vector2i(get_mouse_position())
	popup()