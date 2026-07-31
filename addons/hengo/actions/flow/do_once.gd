@tool
class_name HenActionDoOnce extends HenScriptMacroBase


# runs First only the very first time it is reached, then First is skipped and
# Rest runs instead. the guard is cleared on entry, so re-entering the state
# lets First fire again.


func get_id() -> StringName:
	return &'do_once'


func get_description() -> String:
	return 'Runs its First branch only the first time it is reached, then runs Rest on every following run. The guard resets each time the state is entered.'


func get_display_name() -> String:
	return 'Do Once'


func get_icon() -> String:
	return 'flag'


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
		{name = 'First', id = &'first', doc = 'Where to go the first time only.'},
		{name = 'Rest', id = &'rest', doc = 'Where to go on every following run.'}
	]


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


func _body() -> String:
	return 'if not did_{{VCNODE_ID}}:\n\tdid_{{VCNODE_ID}} = true\n\t{{first}}\nelse:\n\t{{rest}}'
