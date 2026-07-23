@tool
class_name HenActionIsValid extends HenScriptMacroBase


# branches on whether Object still points at a live instance. bind it to a
# variable holding a node to catch a freed reference before using it.


func get_id() -> StringName:
	return &'is_valid'


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
			bind_only = true,
			default_value = null
		}
	]


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'}
	]


func get_flow_outputs() -> Array[Dictionary]:
	return [
		{name = 'True', id = &'true'},
		{name = 'False', id = &'false'}
	]


func get_flow_enter() -> String:
	return _body()


func get_flow_update() -> String:
	return _body()


func _body() -> String:
	return 'if is_instance_valid({{object}}):\n\t{{true}}\nelse:\n\t{{false}}'
