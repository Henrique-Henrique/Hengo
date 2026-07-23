@tool
class_name HenActionSetVisible extends HenScriptMacroBase


# shows or hides the owner. a hidden node keeps running, it just is not drawn.


func get_id() -> StringName:
	return &'set_visible'


func get_display_name() -> String:
	return 'Set Visible'


func get_icon() -> String:
	return 'eye'


func get_default_phase() -> StringName:
	return &'enter'


func get_target_classes() -> Array[StringName]:
	return [&'Node2D', &'Node3D', &'Control']


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Visible',
			type = 'bool',
			id = &'visible',
			default_value = true
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
	return '_ref.visible = {{visible}}'
