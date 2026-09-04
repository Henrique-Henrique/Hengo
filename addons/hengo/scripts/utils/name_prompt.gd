@tool
class_name HenNamePrompt extends VBoxContainer

# name + type prompt: calls back with (name, type)

var _on_confirm: Callable
var _type: String = 'Variant'

var title_label: Label
var name_input: LineEdit
var type_bt: Button
var confirm_bt: Button


# called after show_content (node already in the tree). with _show_type off it is
# a plain text prompt, and the callback still receives the untouched type
func setup(_title: String, _initial_name: String, _initial_type: String, _cb: Callable, _show_type: bool = true) -> void:
	_on_confirm = _cb
	_bind_refs()

	title_label.text = _title
	name_input.text = _initial_name
	name_input.placeholder_text = 'variable name' if _show_type else 'Sprite2D/AudioStreamPlayer'
	confirm_bt.text = 'Create' if _show_type else 'Confirm'
	_type = _initial_type if not _initial_type.is_empty() else 'Variant'
	type_bt.text = _type
	# the whole row goes, label included
	type_bt.get_parent().visible = _show_type

	name_input.grab_focus()
	name_input.select_all()


func _ready() -> void:
	_bind_refs()
	confirm_bt.pressed.connect(_confirm)
	type_bt.pressed.connect(_on_type_pressed)
	name_input.text_submitted.connect(func(_t: String) -> void: _confirm())


func _bind_refs() -> void:
	if name_input:
		return

	title_label = get_node('%Title')
	name_input = get_node('%NameInput')
	type_bt = get_node('%TypeBt')
	confirm_bt = get_node('%ConfirmBt')


# searchable list of every Godot type (same source as the 'all_godot_classes' dropdown)
func _on_type_pressed() -> void:
	var menu: HenDropDownMenu = load('res://addons/hengo/scenes/drop_down_menu.tscn').instantiate()

	# show first (tree entry wires the refs/click), then mount
	(Engine.get_singleton(&'GeneralPopup') as HenGeneralPopup).show_content(menu, {
		layout = HenGeneralPopup.Layout.ANCHORED,
		pos = type_bt.global_position,
		min_size = Vector2(220, 280)
	})

	menu.mount(_type_options(), _on_type_selected, 'item_type')


func _type_options() -> Array:
	var enums: HenEnums = Engine.get_singleton(&'Enums')
	if enums and not enums.DROPDOWN_ALL_CLASSES.is_empty():
		return enums.DROPDOWN_ALL_CLASSES

	var arr: Array = []
	for t: String in (HenEnums.VARIANT_TYPES + ClassDB.get_class_list()):
		arr.append({name = t})
	return arr


func _on_type_selected(item: Dictionary) -> void:
	_type = str(item.get('name', 'Variant'))
	type_bt.text = _type


func _confirm() -> void:
	var value: String = name_input.text

	(Engine.get_singleton(&'GeneralPopup') as HenGeneralPopup).hide_popup()

	if _on_confirm.is_valid():
		_on_confirm.call(value, _type)
