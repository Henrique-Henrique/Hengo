@tool
class_name HenActionTimeInState extends HenScriptMacroBase


func get_id() -> StringName:
	return &'time_in_state'


func get_description() -> String:
	return 'Stores how many seconds this state has been running, counting from zero again every time the state is entered. Feed it to a progress bar or to anything that grows the longer the state lasts.'


func get_display_name() -> String:
	return 'Time In State'


func get_icon() -> String:
	return 'clock'


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Seconds', type = 'float', id = &'result', doc = 'Where to store the seconds spent in this state so far.'}
	]


func get_output_result() -> String:
	return 'time_in_{{VCNODE_ID}}'


# one counter per action, so two of them in the same state never share it
func get_script_base() -> String:
	return 'var time_in_{{VCNODE_ID}}: float = 0.0'


func get_flow_reset() -> String:
	return 'time_in_{{VCNODE_ID}} = 0.0'


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
	return 'time_in_{{VCNODE_ID}} += delta\n{{out:result}}'
