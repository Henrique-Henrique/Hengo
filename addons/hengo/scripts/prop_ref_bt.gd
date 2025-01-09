@tool
class_name HenPropRef extends TextureButton

var input_ref

func _ready() -> void:
	pressed.connect(_on_press)


func _on_press() -> void:
	print(
		HenGlobal.PROPS_CONTAINER.get_all_values()
	)