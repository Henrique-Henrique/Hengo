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
	
	match type:
		'String', 'NodePath', 'StringName':
			code_value = '""'
		'int':
			code_value = '0'
		'float':
			code_value = '0.'
		'Vector2':
			code_value = 'Vector2(0, 0)'
		'bool':
			code_value = 'false'
		'Variant':
			code_value = 'null'
		_:
			if HenEnums.VARIANT_TYPES.has(type):
				code_value = type + '()'
			elif ClassDB.can_instantiate(type):
				code_value = type + '.new()'

	match type:
		'String', 'NodePath', 'StringName':
			value = ''
		_:
			value = code_value