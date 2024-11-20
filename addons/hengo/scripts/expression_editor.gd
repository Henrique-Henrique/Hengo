@tool
extends PanelContainer

# imports
const _CNode = preload('res://addons/hengo/scripts/cnode.gd')
const _Global = preload('res://addons/hengo/scripts/global.gd')

@onready var label: Label = get_node('%Label')
@onready var code_edit: CodeEdit = get_node('%CodeEdit')
@onready var save_bt: Button = get_node('%Save')

var ref: _CNode
var bt_ref
var word_list: Array

var default_config: Dictionary


func _ready() -> void:
	code_edit.text_changed.connect(_on_change)
	save_bt.pressed.connect(_on_save)
	
	# set default
	if not default_config.is_empty():
		code_edit.text = default_config.exp
		_on_change()


func _on_change() -> void:
	var expre: Expression = Expression.new()
	var keys: Array[String] = []

	var reg: RegEx = RegEx.new()
	reg.compile("[a-zA-Z][a-zA-Z0-9_]*")
	var result = reg.search_all(code_edit.text)

	if result:
		for r: RegExMatch in result:
			keys.append(r.get_string())

	var error = expre.parse(code_edit.text, keys)

	save_bt.disabled = true

	if error != OK:
		label.text = expre.get_error_text()
		label.modulate = Color.ORANGE_RED
	else:
		var res = expre.execute(keys.map(func(_x): return 1), null, false)

		if not expre.has_execute_failed():
			var k := keys.duplicate()
			k.pop_back()

			label.text = 'Expression Valid'
			label.modulate = Color.SEA_GREEN

			var completion = unique_array(k)
			word_list = unique_array(keys)

			save_bt.disabled = false
		else:
			label.text = expre.get_error_text()
	
	code_edit.request_code_completion(true)


func _on_save() -> void:
	var in_container = ref.get_node('%InputContainer')
	var prevent_list: Array = []

	for input in in_container.get_children():
		var input_name: String = input.get_in_out_name()

		if not word_list.has(input_name):
			input.remove()
		else:
			prevent_list.append(input_name)

	for word in word_list:
		if not word in prevent_list:
			ref.add_input({
				name = word,
				type = 'Variant'
			})
	
	bt_ref.set_exp(code_edit.text)
	_Global.GENERAL_POPUP.get_parent().hide()


func unique_array(arr: Array) -> Array:
	var dict := {}
	for a in arr:
		dict[a] = 1
	return dict.keys()