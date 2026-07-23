@tool
class_name HenActionSetPosition extends HenScriptMacroBase


# moves the owner to Position, in parent space.


func get_id() -> StringName:
	return &'set_position'


func get_display_name() -> String:
	return 'Set Position'


func get_icon() -> String:
	return 'locate-fixed'


func get_target_classes() -> Array[StringName]:
	return [&'Node2D']


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Position',
			type = 'Vector2',
			id = &'position',
			default_value = Vector2.ZERO
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
	return '_ref.position = {{position}}'
