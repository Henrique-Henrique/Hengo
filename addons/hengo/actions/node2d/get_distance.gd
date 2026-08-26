@tool
class_name HenActionGetDistance extends HenScriptMacroBase


# writes the global-space distance from the owner to Target into Store.


func get_id() -> StringName:
	return &'get_distance'


func get_description() -> String:
	return 'Measures the distance from the node to a target and stores it, in pixels.'


func get_display_name() -> String:
	return 'Get Distance'


func get_icon() -> String:
	return 'ruler'


func get_target_classes() -> Array[StringName]:
	return [&'Node2D']


func get_inputs() -> Array[Dictionary]:
	return [
		node_ref_input('The node the distance is measured from. Leave it empty to measure from this node.'),
		{
			name = 'Target',
			type = 'Node2D',
			id = &'target',
			doc = 'The node to measure the distance to, such as another Node2D.',
			bind_only = true,
			default_value = null
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Distance', type = 'float', id = &'distance', doc = 'Where to store the resulting distance, in pixels.'}
	]


func get_output_distance() -> String:
	return '{{ref}}.global_position.distance_to({{target}}.global_position)'


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
	return '{{out:distance}}'
