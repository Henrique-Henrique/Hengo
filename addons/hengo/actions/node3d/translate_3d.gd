@tool
class_name HenActionTranslate3D extends HenScriptMacroBase


# shifts the owner by Offset. on update and physics the offset is per second, on
# enter/exit it is applied once.


func get_id() -> StringName:
	return &'translate_3d'


func get_display_name() -> String:
	return 'Translate'


func get_icon() -> String:
	return 'move-3d'


func get_target_classes() -> Array[StringName]:
	return [&'Node3D']


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Offset',
			type = 'Vector3',
			id = &'offset',
			default_value = Vector3(1, 0, 0)
		}
	]


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'},
		{name = 'Exit', id = &'exit'}
	]


func get_flow_enter() -> String:
	return '_ref.position += {{offset}}'


func get_flow_update() -> String:
	return '_ref.position += {{offset}} * delta'


func get_flow_physics() -> String:
	return '_ref.position += {{offset}} * delta'


func get_flow_exit() -> String:
	return '_ref.position += {{offset}}'
