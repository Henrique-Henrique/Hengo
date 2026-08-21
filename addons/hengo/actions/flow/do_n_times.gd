@tool
class_name HenActionDoNTimes extends HenScriptMacroBase


func get_id() -> StringName:
	return &'do_n_times'


func get_description() -> String:
	return 'Runs its Within branch on the first runs, up to Times of them, and runs Done on every run after that. The count resets each time the state is entered.'


func get_display_name() -> String:
	return 'Do N Times'


func get_icon() -> String:
	return 'flag-triangle-right'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Times',
			type = 'int',
			id = &'times',
			doc = 'How many runs go through the Within branch.',
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
		{name = 'Within', id = &'within', doc = 'Where to go while the run count is still below Times.'},
		{name = 'Done', id = &'done', doc = 'Where to go on every run after the first Times runs.'}
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
