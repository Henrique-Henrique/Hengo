@tool
extends TextureRect


func _ready() -> void:
    (get_node('Discord') as Button).pressed.connect(_on_press.bind('https://'))


func _on_press(_url: String) -> void:
    OS.shell_open(_url)