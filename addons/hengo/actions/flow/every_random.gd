@tool
class_name HenActionEveryRandom extends HenScriptMacroBase


func get_id() -> StringName:
	return &'every_random'


func get_description() -> String:
	return 'Runs the actions inside it on a random interval, drawing a new wait between Min and Max after each run. With Min = 1 and Max = 4, an idle grunt plays somewhere between one and four seconds apart instead of on a metronome.'


func get_display_name() -> String:
	return 'Every Random'


func get_icon() -> String:
	return 'dice-5'


func get_has_body() -> bool:
	return true


func get_default_phase() -> StringName:
	return &'update'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Min',
			type = 'float',
			id = &'min',
			doc = 'The shortest wait between two runs, in seconds.',
			default_value = 0.5
		},
		{
			name = 'Max',
			type = 'float',
			id = &'max',
			doc = 'The longest wait between two runs, in seconds.',
			default_value = 2.0
		}
	]


# one counter per action, so two blocks in the same state never share it
func get_script_base() -> String:
	return 'var every_rand_{{VCNODE_ID}}: float = 0.0\n' \
		+ 'var every_rand_next_{{VCNODE_ID}}: float = 0.0'


func get_flow_reset() -> String:
	return 'every_rand_{{VCNODE_ID}} = 0.0\n' \
		+ 'every_rand_next_{{VCNODE_ID}} = 0.0'


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
	return 'if every_rand_next_{{VCNODE_ID}} <= 0.0:\n' \
		+ '\tevery_rand_next_{{VCNODE_ID}} = randf_range({{min}}, {{max}})\n' \
		+ 'every_rand_{{VCNODE_ID}} += delta\n' \
		+ 'if every_rand_{{VCNODE_ID}} >= every_rand_next_{{VCNODE_ID}}:\n' \
		+ '\tevery_rand_{{VCNODE_ID}} = 0.0\n' \
		+ '\tevery_rand_next_{{VCNODE_ID}} = randf_range({{min}}, {{max}})\n' \
		+ '\t{{loop_body}}'
