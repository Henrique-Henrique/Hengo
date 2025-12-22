@tool
class_name HenTypeInout extends RefCounted

var id: int
var type: StringName
var category: StringName
var code_value: String
var name: String
var is_ref: bool
var sub_type: StringName
var value: Variant
var data: Variant
var is_prop: bool
var is_static: bool


func reset_input_value() -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	category = &'default_value'
	is_prop = false

	if global.SAVE_DATA and global.SAVE_DATA.identity.type == type:
		code_value = '_ref.'
		is_ref = true
		return
	
	code_value = HenVirtualCNodeCode.get_default_value_code(type)

	match type:
		'String', 'NodePath', 'StringName':
			value = ''
		_:
			value = code_value