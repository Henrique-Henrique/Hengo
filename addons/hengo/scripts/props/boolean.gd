@tool
extends CheckButton


signal value_changed


func _ready() -> void:
	pressed.connect(_on_press)


func _on_press() -> void:
	value_changed.emit(button_pressed)

# public
#
func set_default(_value) -> void:
	button_pressed = str_to_var(_value) if _value is String else _value

func get_value() -> bool:
	return button_pressed

func get_generated_code() -> String:
	return str(button_pressed)