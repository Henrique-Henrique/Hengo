@tool
class_name HenActionCountTo extends HenScriptMacroBase


func get_id() -> StringName:
	return &'count_to'


func get_description() -> String:
	return 'Counts every run and takes the Reached branch on the run number Times, then starts counting again from zero. The count survives leaving and coming back to this state, so it fits things like the third hit killing an enemy.'


func get_display_name() -> String:
	return 'Count To'


func get_icon() -> String:
	return 'target'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Times',
			type = 'int',
			id = &'times',
			doc = 'How many runs it takes to reach the target.',
			default_value = 3
		}
	]


# one counter per action, so two counters in the same state never share it
func get_script_base() -> String:
	return 'var count_{{VCNODE_ID}}: int = 0'


func get_default_phase() -> StringName:
	return &'update'


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'}
	]


func get_flow_outputs() -> Array[Dictionary]:
	return [
		{name = 'Reached', id = &'reached', doc = 'Where to go on the run that hits Times. The count goes back to zero right after.'},
		{name = 'Counting', id = &'counting', doc = 'Where to go while the count is still below Times.'}
	]


func get_flow_enter() -> String:
	return _body()


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


func _body() -> String:
	return 'count_{{VCNODE_ID}} += 1\n' \
		+ 'if count_{{VCNODE_ID}} >= {{times}}:\n' \
		+ '\tcount_{{VCNODE_ID}} = 0\n' \
		+ '\t{{reached}}\n' \
		+ 'else:\n' \
		+ '\t{{counting}}'
