@tool
class_name HenActionRotate3D extends HenScriptMacroBase


# spins the owner around an axis. on update and physics the speed is degrees per
# second, on enter/exit it is a one-shot turn.


func get_id() -> StringName:
	return &'rotate_3d'


func get_display_name() -> String:
	return 'Rotate'


func get_icon() -> String:
	return 'rotate-3d'


func get_target_classes() -> Array[StringName]:
	return [&'Node3D']


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Axis',
			type = 'Vector3',
			id = &'axis',
			default_value = Vector3(0, 1, 0)
		},
		{
			name = 'Speed',
			type = 'float',
			id = &'speed',
			default_value = 90.0
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
	return '_ref.rotate({{axis}}.normalized(), deg_to_rad({{speed}}))'


func get_flow_update() -> String:
	return '_ref.rotate({{axis}}.normalized(), deg_to_rad({{speed}}) * delta)'


func get_flow_physics() -> String:
	return '_ref.rotate({{axis}}.normalized(), deg_to_rad({{speed}}) * delta)'


func get_flow_exit() -> String:
	return '_ref.rotate({{axis}}.normalized(), deg_to_rad({{speed}}))'
