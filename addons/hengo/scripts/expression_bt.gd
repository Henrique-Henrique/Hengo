@tool
class_name HenExpressionBt extends Button


var ref
var raw_text: String = ''

func _ready() -> void:
	pressed.connect(_on_press)

func _on_press() -> void:
	var expression_editor = preload('res://addons/hengo/scenes/utils/expression_editor.tscn').instantiate()
	expression_editor.ref = ref
	expression_editor.bt_ref = self
	expression_editor.default_config = {
		exp = get_exp()
	}
	HenGlobal.GENERAL_POPUP.get_parent().show_content(expression_editor, 'Expression Editor')

func set_exp(_exp: String) -> void:
	raw_text = _exp
	text = _exp.replacen('\n', ' ')

func get_exp() -> String:
	return raw_text