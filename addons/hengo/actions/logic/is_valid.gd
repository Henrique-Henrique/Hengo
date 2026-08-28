@tool
class_name HenActionIsValid extends HenScriptMacroBase


# branches on whether Object still points at a live instance. bind it to a
# variable holding a node to catch a freed reference before using it.


func get_id() -> StringName:
	return &'is_valid'


func get_description() -> String:
	return 'Answers whether an object is still alive, which is false once it was freed. It can branch on the answer or hand it to a field that takes a yes or no.'


func get_display_name() -> String:
	return 'Is Valid'


func get_icon() -> String:
	return 'circle-check'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Object',
			type = 'Variant',
			id = &'object',
				doc = 'The variable holding the object to check.',
			bind_only = true,
			default_value = null
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Yes', type = 'bool', id = &'result', doc = 'Where to store whether the object is still alive.'}
	]


func get_output_result() -> String:
	return 'is_instance_valid({{object}})'


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'}
	]


func get_flow_outputs() -> Array[Dictionary]:
	return [
		{name = 'True', id = &'true', optional = true, doc = 'Where to go when the object is still valid.'},
		{name = 'False', id = &'false', optional = true, doc = 'Where to go when the object has been freed.'}
	]


func get_flow_enter() -> String:
	return _body()


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


# with no branch wired it is only the answer, which is what lets it be read
# from inside another action's field
func _body() -> String:
	if not any_flow_connected():
		return '{{out:result}}'

	return '{{out:result}}\n' \
		+ 'if is_instance_valid({{object}}):\n' \
		+ '\t{{true}}\n' \
		+ 'else:\n' \
		+ '\t{{false}}'
