@tool
class_name HenActionAlternate extends HenScriptMacroBase


func get_id() -> StringName:
	return &'alternate'


func get_description() -> String:
	return 'Takes turns between its two branches, First then Second then First again, one per run. On enter it is what makes a footstep state play the left sound and then the right one. The side it stopped on survives leaving and coming back to this state.'


func get_display_name() -> String:
	return 'Alternate'


func get_icon() -> String:
	return 'arrow-right-left'


# one flag per action, so two alternates in the same state never share it
func get_script_base() -> String:
	return 'var flip_{{VCNODE_ID}}: bool = false'


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
		{name = 'First', id = &'first', doc = 'Where to go on the first run, then on the third, the fifth and so on.'},
		{name = 'Second', id = &'second', doc = 'Where to go on the second run, then on the fourth, the sixth and so on.'}
	]


func get_flow_enter() -> String:
	return _body()


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


func _body() -> String:
	return 'flip_{{VCNODE_ID}} = not flip_{{VCNODE_ID}}\n' \
		+ 'if flip_{{VCNODE_ID}}:\n' \
		+ '\t{{first}}\n' \
		+ 'else:\n' \
		+ '\t{{second}}'
