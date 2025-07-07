@tool
class_name HenExpressionEditor extends PanelContainer


@onready var label: Label = get_node('%Label')
@onready var code_edit: CodeEdit = get_node('%CodeEdit')
@onready var save_bt: Button = get_node('%Save')

var v_cnode: HenVirtualCNode
var bt_ref: HenExpressionBt
var word_list: Array
var completion_list: Array

var default_config: Dictionary


const NATIVE_KEYWORDS: Array[StringName] = ['and', 'or', 'not', 'in', 'is']


func _ready() -> void:
	code_edit.text_changed.connect(_on_change)
	save_bt.pressed.connect(_on_save)
	
	code_edit.code_completion_requested.connect(_completion_request)

	# set default
	if not default_config.is_empty():
		code_edit.text = default_config.exp
		_on_change()


func _completion_request() -> void:
	for key in completion_list:
		code_edit.add_code_completion_option(CodeEdit.KIND_VARIABLE, key, key)

	for native_name in HenEnums.MATH_UTILITY_NAME_LIST:
		code_edit.add_code_completion_option(CodeEdit.KIND_FUNCTION, native_name, native_name + '(')
	
	code_edit.update_code_completion_options(true)


func _on_change() -> void:
	var expre: Expression = Expression.new()
	var keys: Array[String] = []

	var reg: RegEx = RegEx.new()
	reg.compile("\\b[a-zA-Z][a-zA-Z0-9_]*\\b(?!\\s*\\()")
	var result = reg.search_all(code_edit.text)

	if result:
		for r: RegExMatch in result:
			var key: String = r.get_string()

			if not NATIVE_KEYWORDS.has(key):
				keys.append(r.get_string())

	var error = expre.parse(code_edit.text, keys)

	save_bt.disabled = true

	if error != OK:
		label.text = expre.get_error_text()
		label.modulate = Color.ORANGE_RED
	else:
		expre.execute(keys.map(func(_x): return 1), null, false)

		if not expre.has_execute_failed():
			var k := keys.duplicate()
			k.pop_back()

			label.text = 'Expression Valid'
			label.modulate = Color.SEA_GREEN

			completion_list = unique_array(k)
			word_list = unique_array(keys)

			save_bt.disabled = false
		else:
			label.text = expre.get_error_text()
	
	code_edit.request_code_completion(true)


func _on_save() -> void:
	# cleaning inputs
	v_cnode.inputs[0].value = code_edit.text

	for input: HenVCInOutData in v_cnode.inputs.slice(1):
		v_cnode._on_in_out_deleted(true, input)

	for word in word_list:
		v_cnode._on_in_out_added(true, {
			name = word,
			type = 'Variant'
		})
		
	HenGlobal.GENERAL_POPUP.get_parent().hide()
	v_cnode.update()


func unique_array(arr: Array) -> Array:
	var dict := {}
	for a in arr:
		dict[a] = 1
	return dict.keys()