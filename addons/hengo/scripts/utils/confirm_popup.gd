@tool
class_name HenConfirmPopup extends VBoxContainer

var _title: String = 'Confirm'
var _message: String = ''
var _confirm_text: String = 'Confirm'
var _cancel_text: String = 'Cancel'
var _on_confirm: Callable
var _on_cancel: Callable


static func show_confirm(
	message: String,
	on_confirm: Callable,
	title: String = 'Confirm',
	confirm_text: String = 'Confirm',
	cancel_text: String = 'Cancel',
	on_cancel: Callable = Callable()
) -> void:
	var popup: HenConfirmPopup = HenConfirmPopup.new()
	popup.setup(title, message, on_confirm, confirm_text, cancel_text, on_cancel)
	(Engine.get_singleton(&'GeneralPopup') as HenGeneralPopup).show_content(popup, title, Vector2.INF, 0.5)


func setup(
	title: String,
	message: String,
	on_confirm: Callable,
	confirm_text: String = 'Confirm',
	cancel_text: String = 'Cancel',
	on_cancel: Callable = Callable()
) -> void:
	_title = title
	_message = message
	_on_confirm = on_confirm
	_confirm_text = confirm_text
	_cancel_text = cancel_text
	_on_cancel = on_cancel
	_build_ui()


func _build_ui() -> void:
	for child in get_children():
		child.queue_free()

	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override('separation', 14)

	var label := Label.new()
	label.text = _message
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(label)

	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override('separation', 12)
	add_child(hbox)

	var confirm_bt := Button.new()
	confirm_bt.text = _confirm_text
	confirm_bt.modulate = Color('#c16460')
	confirm_bt.pressed.connect(_on_confirm_pressed)
	hbox.add_child(confirm_bt)

	var cancel_bt := Button.new()
	cancel_bt.text = _cancel_text
	cancel_bt.pressed.connect(_on_cancel_pressed)
	hbox.add_child(cancel_bt)


func _on_confirm_pressed() -> void:
	var popup: HenGeneralPopup = Engine.get_singleton(&'GeneralPopup')
	popup.hide_popup()

	if _on_confirm.is_valid():
		_on_confirm.call()


func _on_cancel_pressed() -> void:
	var popup: HenGeneralPopup = Engine.get_singleton(&'GeneralPopup')
	popup.hide_popup()

	if _on_cancel.is_valid():
		_on_cancel.call()
