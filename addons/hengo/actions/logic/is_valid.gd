@tool
class_name HenActionIsValid extends HenScriptMacroBase


# branches on whether Object still points at a live instance. bind it to a
# variable holding a node to catch a freed reference before using it.


func get_id() -> StringName:
	return &'is_valid'


func get_description() -> String:
	return 'Checks whether an object still points at a live instance and branches on the result. Helps catch a freed node before using it.'


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


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'}
	]


func get_flow_outputs() -> Array[Dictionary]:
	return [
		{name = 'True', id = &'true', doc = 'Where to go when the object is still valid.'},
		{name = 'False', id = &'false', doc = 'Where to go when the object has been freed.'}
	]


func get_flow_enter() -> String:
	return _body()


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


func _body() -> String:
	return 'if is_instance_valid({{object}}):\n\t{{true}}\nelse:\n\t{{false}}'
