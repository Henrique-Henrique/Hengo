@tool
class_name HenActionDestroyAfter extends HenScriptMacroBase


func get_id() -> StringName:
	return &'destroy_after'


func get_description() -> String:
	return 'Removes this node from the scene once the given time has passed. It is how a bullet or a hit effect cleans itself up.'


func get_display_name() -> String:
	return 'Destroy After Seconds'


func get_icon() -> String:
	return 'timer'


func get_default_phase() -> StringName:
	return &'enter'


func get_inputs() -> Array[Dictionary]:
	return [
		node_ref_input('The node to destroy. Leave it empty to destroy this node.'),
		{
			name = 'Seconds',
			type = 'float',
			id = &'seconds',
			doc = 'How long the node stays alive before it is removed.',
			default_value = 2.0
		}
	]


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'}
	]


func get_flow_enter() -> String:
	return _body()


func _body() -> String:
	return '_ref.get_tree().create_timer({{seconds}}).timeout.connect({{ref}}.queue_free)'
