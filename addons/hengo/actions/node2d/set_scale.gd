@tool
class_name HenActionSetScale extends HenScriptMacroBase


# sets the owner's scale.


func get_id() -> StringName:
	return &'set_scale'


func get_display_name() -> String:
	return 'Set Scale'


func get_icon() -> String:
	return 'maximize'


func get_target_classes() -> Array[StringName]:
	return [&'Node2D']


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Scale',
			type = 'Vector2',
			id = &'scale',
			default_value = Vector2.ONE
		}
	]


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'},
		{name = 'Exit', id = &'exit'}
	]


func get_flow_enter() -> String:
	return _body()


func get_flow_update() -> String:
	return _body()


func get_flow_exit() -> String:
	return _body()


func _body() -> String:
	return '_ref.scale = {{scale}}'
