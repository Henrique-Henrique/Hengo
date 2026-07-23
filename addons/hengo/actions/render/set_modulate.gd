@tool
class_name HenActionSetModulate extends HenScriptMacroBase


# tints the owner and everything drawn inside it. the alpha channel of the color
# is what fades the node out.


func get_id() -> StringName:
	return &'set_modulate'


func get_display_name() -> String:
	return 'Set Modulate'


func get_icon() -> String:
	return 'droplet'


func get_default_phase() -> StringName:
	return &'enter'


func get_target_classes() -> Array[StringName]:
	return [&'CanvasItem']


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Color',
			type = 'Color',
			id = &'color',
			default_value = Color(1, 1, 1, 1)
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
	return '_ref.modulate = {{color}}'
