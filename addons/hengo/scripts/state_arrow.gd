@tool
extends TextureRect

var connections: Array = []

func show_arrow(_line) -> void:
    if not connections.has(_line):
        connections.append(_line)
    

    visible = connections.size() > 0


func hide_arrow(_line) -> void:
    connections.erase(_line)

    visible = connections.size() > 0