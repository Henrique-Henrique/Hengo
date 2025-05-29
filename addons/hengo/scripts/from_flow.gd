@tool
class_name HenFromFlow extends PanelContainer

var id: int

func _ready() -> void:
	mouse_entered.connect(_on_hover)


func _on_hover() -> void:
	if not HenGlobal.can_make_flow_connection: return

	HenGlobal.flow_connection_to_data = {
		to_cnode = owner,
		to_id = id
	}