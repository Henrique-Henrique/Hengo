@tool
class_name HenActionWait extends HenScriptMacroBase


# counts Seconds while the state runs and takes the Finished branch when the time
# is up. the counter is zeroed on entry, so leaving and coming back starts over.


func get_id() -> StringName:
	return &'wait'


func get_description() -> String:
	return 'Waits a number of seconds while staying in this state, then takes the Finished branch on every frame from there on. With Seconds = 3 a game over screen sits still and then moves on. For N Seconds is the one that also gives a branch for the waiting frames.'


func get_display_name() -> String:
	return 'Wait'


func get_icon() -> String:
	return 'hourglass'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Seconds',
			type = 'float',
			id = &'seconds',
				doc = 'How long to wait, in seconds.',
			default_value = 1.0
		}
	]


# one counter per action, so two waits in the same state never share it
func get_script_base() -> String:
	return 'var wait_{{VCNODE_ID}}: float = 0.0'


func get_flow_reset() -> String:
	return 'wait_{{VCNODE_ID}} = 0.0'


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'}
	]


func get_flow_outputs() -> Array[Dictionary]:
	return [
		{name = 'Finished', id = &'finished', doc = 'Where to go when the time is up.'}
	]


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


func _body() -> String:
	return 'wait_{{VCNODE_ID}} += delta\nif wait_{{VCNODE_ID}} >= {{seconds}}:\n\t{{finished}}'
