@tool
class_name HenActionForEach extends HenScriptMacroBase


# runs its nested actions once for every element of Collection, all in the same
# frame. bind Item to a variable so the nested actions can read the current one.


func get_id() -> StringName:
	return &'for_each'


func get_description() -> String:
	return 'Runs the actions inside it once for every item of a list, all in the same frame. A list of ten enemies runs the inside ten times, with Item holding one enemy each pass. A timer nested inside it ticks once per item, not once per frame.'


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
			doc = 'The array or collection to walk through.',
			bind_only = true,
			default_value = null
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Item', type = 'Variant', id = &'item', branch = &'body', doc = 'The current element, for the nested actions to read.'},
		{name = 'Index', type = 'int', id = &'index', branch = &'body', doc = 'The position of the current element, starting at 0.'}
	]


func get_output_item() -> String:
	return '__item_{{VCNODE_ID}}'


func get_output_index() -> String:
	return '__i_{{VCNODE_ID}}'


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


# counts by hand: range() would index a dictionary by position
func _body() -> String:
	return 'var __i_{{VCNODE_ID}} = -1\nfor __item_{{VCNODE_ID}} in {{collection}}:\n\t__i_{{VCNODE_ID}} += 1\n\t{{out:index}}\n\t{{out:item}}\n\t{{loop_body}}'
