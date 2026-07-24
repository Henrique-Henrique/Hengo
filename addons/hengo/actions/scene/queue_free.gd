@tool
class_name HenActionQueueFree extends HenScriptMacroBase


# removes the owner from the scene at the end of the frame. anything after it in
# the list still runs, but the node is gone on the next one.


func get_id() -> StringName:
	return &'queue_free'


func get_description() -> String:
	return 'Removes this node from the scene at the end of the frame. Later actions still run, but the node is gone on the next frame.'


func get_display_name() -> String:
	return 'Destroy Self'


func get_icon() -> String:
	return 'trash-2'


func get_default_phase() -> StringName:
	return &'enter'


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'}
	]


func get_flow_enter() -> String:
	return _body()


func get_flow_update() -> String:
	return _body()


func _body() -> String:
	return '_ref.queue_free()'
