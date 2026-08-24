@tool
class_name HenActionDoNTimes extends HenScriptMacroBase


func get_id() -> StringName:
	return &'do_n_times'


func get_description() -> String:
	return 'Does something on the first frames only and then stops. With Times = 3, the first three frames take First Times and every frame after that takes After That. The count restarts each time the state is entered. Either branch can run actions of its own, so a small bit of behaviour needs no state of its own.'


func get_display_name() -> String:
	return 'Do N Times'


func get_icon() -> String:
	return 'flag-triangle-right'


# the branch the steps of an older save belong to
func get_body_branch() -> StringName:
	return &'within'


# nothing nested and no branch wired means an if/else of two passes
func get_validation_error() -> String:
	return gate_validation_error()


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Times',
			type = 'int',
			id = &'times',
			doc = 'How many frames go through the First Times branch.',
			default_value = 3
		}
	]


# one counter per action, so two do-n-times blocks in the same state never share it
func get_script_base() -> String:
	return 'var did_{{VCNODE_ID}}: int = 0'


func get_flow_reset() -> String:
	return 'did_{{VCNODE_ID}} = 0'


func get_default_phase() -> StringName:
	return &'update'


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'}
	]


func get_flow_outputs() -> Array[Dictionary]:
	return [
		{name = 'First Times', id = &'within', optional = true, doc = 'Where to go on the first Times frames.'},
		{name = 'After That', id = &'done', optional = true, doc = 'Where to go on every frame once those are used up.'}
	]


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


func _body() -> String:
	return 'if did_{{VCNODE_ID}} < {{times}}:\n' \
		+ '\tdid_{{VCNODE_ID}} += 1\n' \
		+ '\t{{within}}\n' \
		+ 'else:\n' \
		+ '\t{{done}}'
