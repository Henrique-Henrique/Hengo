@tool
class_name HenExpressionBt extends Button

var v_cnode: HenVirtualCNode

func _ready() -> void:
	pressed.connect(_on_press)

func _on_press() -> void:
	var expression_editor: HenExpressionEditor = preload('res://addons/hengo/scenes/utils/expression_editor.tscn').instantiate()
	expression_editor.v_cnode = v_cnode
	expression_editor.bt_ref = self


	if text != 'Expression':
		expression_editor.default_config = {
			exp = text
		}
	(Engine.get_singleton(&'Global') as HenGlobal).GENERAL_POPUP.show_content(expression_editor, 'Expression Editor')


func set_default(_text: String) -> void:
	text = _text