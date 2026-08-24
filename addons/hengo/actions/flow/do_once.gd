@tool
class_name HenActionDoOnce extends HenScriptMacroBase


# runs First only the very first time it is reached, then First is skipped and
# Rest runs instead. the guard is cleared on entry, so re-entering the state
# lets First fire again.


func get_id() -> StringName:
	return &'do_once'


func get_description() -> String:
	return 'Does something on the first frame it runs and never again, so a hit sound plays once instead of every frame. Every frame after that takes After That. It resets each time the state is entered. Either branch can run actions of its own, so a small bit of behaviour needs no state of its own.'


func get_display_name() -> String:
	return 'Do Once'


func get_icon() -> String:
	return 'flag'


# the branch the steps of an older save belong to
func get_body_branch() -> StringName:
	return &'first'


# nothing nested and no branch wired means an if/else of two passes
func get_validation_error() -> String:
	return gate_validation_error()


# one guard per action, so two do-once blocks in the same state never share it
func get_script_base() -> String:
	return 'var did_{{VCNODE_ID}}: bool = false'


func get_flow_reset() -> String:
	return 'did_{{VCNODE_ID}} = false'


func get_default_phase() -> StringName:
	return &'update'


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'}
	]


func get_flow_outputs() -> Array[Dictionary]:
	return [
		{name = 'First Time', id = &'first', optional = true, doc = 'Where to go on the first frame only.'},
		{name = 'After That', id = &'rest', optional = true, doc = 'Where to go on every frame after the first.'}
	]


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


func _body() -> String:
	return 'if not did_{{VCNODE_ID}}:\n' \
		+ '\tdid_{{VCNODE_ID}} = true\n' \
		+ '\t{{first}}\n' \
		+ 'else:\n' \
		+ '\t{{rest}}'
