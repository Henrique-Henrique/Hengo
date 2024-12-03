@tool
extends TextureButton

# imports
const _Global = preload('res://addons/hengo/scripts/global.gd')

var input_ref

func _ready() -> void:
	pressed.connect(_on_press)


func _on_press() -> void:
	print(
		_Global.PROPS_CONTAINER.get_all_values()
	)