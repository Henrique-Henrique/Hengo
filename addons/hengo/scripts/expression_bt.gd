@tool
class_name HenExpressionBt extends Button

signal on_expression_save

func _ready() -> void:
	pressed.connect(_on_press)

func _on_press() -> void:
	var expression_editor: HenExpressionEditor = preload('res://addons/hengo/scenes/utils/expression_editor.tscn').instantiate()
	expression_editor.bt_ref = self
	expression_editor.on_save.connect(_on_save)

	if text != 'Expression':
		expression_editor.default_config = {
			exp = text
		}
	
	(Engine.get_singleton(&'Global') as HenGlobal).GENERAL_POPUP.show_content(expression_editor, 'Expression Editor')


func _on_save(_code_value: String, _word_list: Array) -> void:
	on_expression_save.emit(_code_value, _word_list)


func set_default(_text: String) -> void:
	text = _text