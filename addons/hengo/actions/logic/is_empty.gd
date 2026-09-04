@tool
class_name HenActionIsEmpty extends HenScriptMacroBase


func get_id() -> StringName:
	return &'is_empty'


func get_description() -> String:
	return 'Checks whether a value holds nothing and branches on the answer. Text, lists and dictionaries are empty when they have no items, a value that is missing counts as empty, and a number always counts as something.'


func get_display_name() -> String:
	return 'Is Empty'


func get_icon() -> String:
	return 'package-open'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Value',
			type = 'Variant',
			id = &'value',
			doc = 'The text, list or dictionary to check.',
			default_value = null
		}
	]


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'}
	]


func get_flow_outputs() -> Array[Dictionary]:
	return [
		{name = 'Empty', id = &'empty', doc = 'Where to go when the value has nothing in it.'},
		{name = 'Has Something', id = &'has_something', doc = 'Where to go when it holds something.'}
	]


func get_flow_enter() -> String:
	return _body()


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


# the packed array types sit at the tail of the Variant type enum, so one bound
# covers every one of them
func _body() -> String:
	return 'var value_{{VCNODE_ID}} = {{value}}\n' \
		+ 'var kind_{{VCNODE_ID}}: int = typeof(value_{{VCNODE_ID}})\n' \
		+ 'var empty_{{VCNODE_ID}}: bool = value_{{VCNODE_ID}} == null or ((kind_{{VCNODE_ID}} in [TYPE_STRING, TYPE_STRING_NAME, TYPE_ARRAY, TYPE_DICTIONARY] or kind_{{VCNODE_ID}} >= TYPE_PACKED_BYTE_ARRAY) and value_{{VCNODE_ID}}.is_empty())\n' \
		+ 'if empty_{{VCNODE_ID}}:\n' \
		+ '\t{{empty}}\n' \
		+ 'else:\n' \
		+ '\t{{has_something}}'
