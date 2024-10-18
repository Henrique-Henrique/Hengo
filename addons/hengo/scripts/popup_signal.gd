@tool
extends VBoxContainer

const _Enums = preload ('res://addons/hengo/references/enums.gd')
const _Global = preload ('res://addons/hengo/scripts/global.gd')

var obj_bt
var signal_bt
var create_bt

# private
#
func _ready() -> void:
	obj_bt = get_node('%Obj')
	signal_bt = get_node('%Signal')
	create_bt = get_node('%Create')

	obj_bt.options = _Enums.DROPDOWN_OBJECT_TYPES

	obj_bt.value_changed.connect(_on_obj_value)
	signal_bt.value_changed.connect(_on_signal_change)
	create_bt.pressed.connect(_on_create)

func _on_create() -> void:
	_Global.SIGNAL_SECTION.add_prop({
		signal_data={
			object_name=obj_bt.text,
			signal_name=signal_bt.text
		}
	})
	_Global.GENERAL_POPUP.get_parent().hide()

func _on_obj_value(_value) -> void:
	var list: Array = ClassDB.class_get_signal_list(_value).map(
		func(x: Dictionary) -> Dictionary:
			return {
				name=x.name
			}
	)

	signal_bt.options = list
	signal_bt.text = 'Select'

	signal_bt.disabled = false
	create_bt.disabled = true

func _on_signal_change(_value) -> void:
	create_bt.disabled = false