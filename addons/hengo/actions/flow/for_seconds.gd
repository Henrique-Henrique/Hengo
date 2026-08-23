@tool
class_name HenActionForSeconds extends HenScriptMacroBase


# takes During while the elapsed time is below Seconds and After That from then
# on. the timer is zeroed on entry, so leaving and coming back starts it over.


func get_id() -> StringName:
	return &'for_seconds'


func get_description() -> String:
	return 'Does something for the first seconds only and then stops. With Seconds = 2, the first two seconds take During and every frame after that takes After That, which is how a dash or an invincibility window ends itself. The timer restarts each time the state is entered. Actions nested inside it run while the time is not up.'


func get_display_name() -> String:
	return 'For N Seconds'


func get_icon() -> String:
	return 'hourglass'


func get_has_body() -> bool:
	return true


# nothing nested and no branch wired means an if/else of two passes
func get_validation_error() -> String:
	return gate_validation_error()


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Seconds',
			type = 'float',
			id = &'seconds',
			doc = 'How long the During branch lasts, in seconds.',
			default_value = 1.0
		}
	]


# one timer per action, so two windows in the same state never share it
func get_script_base() -> String:
	return 'var window_{{VCNODE_ID}}: float = 0.0'


func get_flow_reset() -> String:
	return 'window_{{VCNODE_ID}} = 0.0'


func get_default_phase() -> StringName:
	return &'update'


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'}
	]


func get_flow_outputs() -> Array[Dictionary]:
	return [
		{name = 'During', id = &'during', optional = true, doc = 'Where to go while the time is not up yet.'},
		{name = 'After That', id = &'after', optional = true, doc = 'Where to go on every frame once the time is up.'}
	]


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


func _body() -> String:
	return 'window_{{VCNODE_ID}} += delta\n' \
		+ 'if window_{{VCNODE_ID}} < {{seconds}}:\n' \
		+ fire_body(&'during') + '\n' \
		+ 'else:\n' \
		+ '\t{{after}}'
