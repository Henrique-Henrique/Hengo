@tool
class_name HenActionEveryNTimes extends HenScriptMacroBase


func get_id() -> StringName:
	return &'every_n_times'


func get_description() -> String:
	return 'Does something once every so many frames instead of every frame. With Times = 5, the first four frames take Other Times and the fifth takes Nth Time, then it starts over. The count restarts each time the state is entered. Either branch can run actions of its own, so a small bit of behaviour needs no state of its own.'


func get_display_name() -> String:
	return 'Every N Times'


func get_icon() -> String:
	return 'repeat-1'


# the branch the steps of an older save belong to
func get_body_branch() -> StringName:
	return &'nth'


# nothing nested and no branch wired means an if/else of two passes
func get_validation_error() -> String:
	return gate_validation_error()


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Times',
			type = 'int',
			id = &'times',
			doc = 'How many frames one cycle lasts. 5 means the fifth frame is the one that fires.',
			default_value = 5
		}
	]


# one counter per action, so two cycles in the same state never share it
func get_script_base() -> String:
	return 'var cycle_{{VCNODE_ID}}: int = 0'


func get_flow_reset() -> String:
	return 'cycle_{{VCNODE_ID}} = 0'


func get_default_phase() -> StringName:
	return &'update'


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'}
	]


func get_flow_outputs() -> Array[Dictionary]:
	return [
		{name = 'Nth Time', id = &'nth', optional = true, doc = 'Where to go on every Times-th frame, so once per cycle.'},
		{name = 'Other Times', id = &'between', optional = true, doc = 'Where to go on the frames in between.'}
	]


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


func _body() -> String:
	return 'cycle_{{VCNODE_ID}} += 1\n' \
		+ 'if cycle_{{VCNODE_ID}} >= {{times}}:\n' \
		+ '\tcycle_{{VCNODE_ID}} = 0\n' \
		+ '\t{{nth}}\n' \
		+ 'else:\n' \
		+ '\t{{between}}'
