@tool
class_name HenActionEverySeconds extends HenScriptMacroBase


# takes Time Up on the frame the timer reaches Seconds and zeroes it, taking
# Waiting on the frames in between. the timer is zeroed on entry as well.


func get_id() -> StringName:
	return &'every_seconds'


func get_description() -> String:
	return 'Waits so many seconds, takes Time Up for one frame and starts counting again, over and over. With Seconds = 3, an enemy shoots every three seconds and the frames in between take Waiting. Cooldown is the one that fires right away and blocks afterwards. Either branch can run actions of its own, so a small bit of behaviour needs no state of its own.'


func get_display_name() -> String:
	return 'Every N Seconds'


func get_icon() -> String:
	return 'timer-reset'


# the branch the steps of an older save belong to
func get_body_branch() -> StringName:
	return &'time_up'


# nothing nested and no branch wired means an if/else of two passes
func get_validation_error() -> String:
	return gate_validation_error()


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Seconds',
			type = 'float',
			id = &'seconds',
			doc = 'How long each round of the timer lasts, in seconds.',
			default_value = 1.0
		}
	]


# one timer per action, so two intervals in the same state never share it
func get_script_base() -> String:
	return 'var interval_{{VCNODE_ID}}: float = 0.0'


func get_flow_reset() -> String:
	return 'interval_{{VCNODE_ID}} = 0.0'


func get_default_phase() -> StringName:
	return &'update'


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'}
	]


func get_flow_outputs() -> Array[Dictionary]:
	return [
		{name = 'Time Up', id = &'time_up', optional = true, doc = 'Where to go on the frame the timer reaches Seconds. The timer goes back to zero right after.'},
		{name = 'Waiting', id = &'waiting', optional = true, doc = 'Where to go on the frames while the timer is still running.'}
	]


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


func _body() -> String:
	return 'interval_{{VCNODE_ID}} += delta\n' \
		+ 'if interval_{{VCNODE_ID}} >= {{seconds}}:\n' \
		+ '\tinterval_{{VCNODE_ID}} = 0.0\n' \
		+ '\t{{time_up}}\n' \
		+ 'else:\n' \
		+ '\t{{waiting}}'
