@tool
class_name HenActionScreenPosition extends HenScriptMacroBase


func get_id() -> StringName:
	return &'screen_position'


func get_description() -> String:
	return 'Reads where a node shows up on the screen, in pixels. It is what a health bar, a name tag or an arrow marker needs to sit on top of something in the world.'


func get_display_name() -> String:
	return 'Get Screen Position'


func get_icon() -> String:
	return 'monitor-dot'


func get_default_phase() -> StringName:
	return &'update'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Node',
			type = 'Node',
			id = &'node',
			doc = 'The node to project onto the screen. Leave it empty to project this node.',
			bind_only = true,
			optional = true,
			default_value = null
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Result', type = 'Vector2', id = &'result', doc = 'Where to store the screen point, in pixels. A 3D node only reports a point while a camera is active.'}
	]


# the class the script extends decides which projection is emitted: a 3d point
# goes through the active camera, a 2d one through the canvas transform
func get_output_result() -> String:
	if targets(&'Node3D'):
		return '(_ref.get_viewport().get_camera_3d().unproject_position({{node}}.global_position) if _ref.get_viewport().get_camera_3d() != null else Vector2.ZERO)'

	return '(_ref.get_viewport().get_canvas_transform() * {{node}}.global_position)'


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'},
		{name = 'Exit', id = &'exit'}
	]


func get_flow_enter() -> String:
	return _body()


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


func get_flow_exit() -> String:
	return _body()


func _body() -> String:
	return '{{out:result}}'
