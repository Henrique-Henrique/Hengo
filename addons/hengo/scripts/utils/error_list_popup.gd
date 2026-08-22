@tool
class_name HenErrorListPopup extends VBoxContainer

var errors: Array = []

func _ready() -> void:
	var label: Label = Label.new()
	label.text = 'Error List'
	ThemeUtils.apply_font_size(label, 24)
	add_child(label)
	
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 300)
	add_child(scroll)
	
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)
	
	if errors.is_empty():
		var no_error: Label = Label.new()
		no_error.text = 'No errors found.'
		vbox.add_child(no_error)
		return

	for error in errors:
		var item: HBoxContainer = HBoxContainer.new()
		vbox.add_child(item)
		
		var err_label: Label = Label.new()
		err_label.text = error.description
		err_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		item.add_child(err_label)
		
		var btn: Button = Button.new()
		btn.text = 'Go to'
		item.add_child(btn)

# navigates to the error location, switching projects if necessary