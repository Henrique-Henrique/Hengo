@tool
class_name HenActionValuePopup extends MarginContainer

signal confirmed(chip: Variant, text: String)
signal cancelled

var chip: Variant


func _ready() -> void:
	_field().gui_input.connect(_on_field_input)


func edit(_chip: Variant, _text: String) -> void:
	chip = _chip
	_field().text = _text


# deferred by the caller, after the popup settled where it belongs: focus taken
# on the frame the container jumps is dropped
func focus_field() -> void:
	var field: LineEdit = _field()
	field.grab_focus()
	field.select_all()


func _field() -> LineEdit:
	return get_node('Row/Input')


func _on_field_input(_event: InputEvent) -> void:
	var key := _event as InputEventKey

	if not key or not key.pressed:
		return

	match key.keycode:
		KEY_ENTER, KEY_KP_ENTER:
			_field().accept_event()
			confirmed.emit(chip, _field().text)
		KEY_ESCAPE:
			_field().accept_event()
			cancelled.emit()
