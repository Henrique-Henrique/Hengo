@tool
class_name HenActionEvery extends HenScriptMacroBase


# runs the inner actions once every Seconds while the state runs. the counter is
# zeroed on entry, so leaving and coming back starts the interval over.


func get_id() -> StringName:
	return &'every'


func get_description() -> String:
	return 'Runs the actions inside it once every so many seconds while this state runs. With Seconds = 2, an enemy spawns every two seconds. The timer restarts each time the state is entered. Every N Seconds is the same clock with branches instead of nested actions.'


func get_display_name() -> String:
	return 'Every'


func get_icon() -> String:
	return 'timer'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Seconds',
			type = 'float',
			id = &'seconds',
			doc = 'How often to run the inner actions, in seconds.',
			default_value = 1.0
		}
	]


func get_has_body() -> bool:
	return true


# one counter per action, so two every blocks in the same state never share it
func get_script_base() -> String:
	return 'var every_{{VCNODE_ID}}: float = 0.0'


func get_flow_reset() -> String:
	return 'every_{{VCNODE_ID}} = 0.0'


func get_default_phase() -> StringName:
	return &'update'


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'}
	]


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


func _body() -> String:
	return 'every_{{VCNODE_ID}} += delta\nif every_{{VCNODE_ID}} >= {{seconds}}:\n\tevery_{{VCNODE_ID}} = 0.0\n\t{{loop_body}}'
