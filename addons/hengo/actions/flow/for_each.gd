@tool
class_name HenActionForEach extends HenScriptMacroBase


# runs its nested actions once for every element of Collection, all in the same
# frame. bind Item to a variable so the nested actions can read the current one.


func get_id() -> StringName:
	return &'for_each'


func get_display_name() -> String:
	return 'For Each'


func get_icon() -> String:
	return 'repeat'


func get_has_body() -> bool:
	return true


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Collection',
			type = 'Variant',
			id = &'collection',
			bind_only = true,
			default_value = null
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Item', type = 'Variant', id = &'item'}
	]


func get_output_item() -> String:
	return '__item_{{VCNODE_ID}}'


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'}
	]


func get_flow_enter() -> String:
	return _body()


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


func _body() -> String:
	return 'for __item_{{VCNODE_ID}} in {{collection}}:\n\t{{out:item}}\n\t{{loop_body}}'
