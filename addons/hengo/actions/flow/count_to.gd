@tool
class_name HenActionCountTo extends HenScriptMacroBase


func get_id() -> StringName:
	return &'count_to'


func get_description() -> String:
	return 'Counts every time it runs and takes Reached on the run number Times, then counts from zero again. With Times = 3 on enter, the first two hits take Counting and the third one kills the enemy. The count survives leaving and coming back to this state. Either branch can run actions of its own, so a small bit of behaviour needs no state of its own.'


func get_display_name() -> String:
	return 'Count To'


func get_icon() -> String:
	return 'target'


# the branch the steps of an older save belong to
func get_body_branch() -> StringName:
	return &'reached'


# nothing nested and no branch wired means an if/else of two passes
func get_validation_error() -> String:
	return gate_validation_error()


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Times',
			type = 'int',
			id = &'times',
			doc = 'How many times it has to run before Reached fires.',
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
		{name = 'Reached', id = &'reached', optional = true, doc = 'Where to go on the run that hits Times. The count goes back to zero right after.'},
		{name = 'Counting', id = &'counting', optional = true, doc = 'Where to go while the count is still below Times.'}
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
