@tool
class_name HenActionEveryNTimes extends HenScriptMacroBase


func get_id() -> StringName:
	return &'every_n_times'


func get_description() -> String:
	return 'Takes the Nth branch once every so many runs, and the Between branch on the runs in the middle. The cycle resets each time the state is entered.'


func get_display_name() -> String:
	return 'Every N Times'


func get_icon() -> String:
	return 'repeat-1'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Times',
			type = 'int',
			id = &'times',
			doc = 'How many runs make one cycle. The last run of each cycle takes the Nth branch.',
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
		{name = 'Nth', id = &'nth', doc = 'Where to go on the last run of each cycle, once every Times runs.'},
		{name = 'Between', id = &'between', doc = 'Where to go on the other runs of the cycle.'}
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
