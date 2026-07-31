@tool
class_name HenActionCooldown extends HenScriptMacroBase


# gates a branch so it fires at most once every Seconds, no matter how often the
# state runs. the timer is zeroed on entry, so the first run always goes through.


func get_id() -> StringName:
	return &'cooldown'


func get_description() -> String:
	return 'Lets its branch fire at most once every so many seconds, ignoring the runs in between. Use it to stop an action from spamming while a condition stays true.'


func get_display_name() -> String:
	return 'Cooldown'


func get_icon() -> String:
	return 'timer'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Seconds',
			type = 'float',
			id = &'seconds',
			doc = 'How long the branch stays blocked after it fires, in seconds.',
			default_value = 1.0
		}
	]


# one timer per action, so two cooldowns in the same state never share it
func get_script_base() -> String:
	return 'var cooldown_{{VCNODE_ID}}: float = 0.0'


func get_flow_reset() -> String:
	return 'cooldown_{{VCNODE_ID}} = 0.0'


func get_default_phase() -> StringName:
	return &'update'


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'}
	]


func get_flow_outputs() -> Array[Dictionary]:
	return [
		{name = 'Ready', id = &'ready', doc = 'Where to go when the wait is up. It starts the wait again.'},
		{name = 'Cooling', id = &'cooling', doc = 'Where to go while still waiting.'}
	]


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


func _body() -> String:
	return 'cooldown_{{VCNODE_ID}} = maxf(cooldown_{{VCNODE_ID}} - delta, 0.0)\n' \
		+ 'if cooldown_{{VCNODE_ID}} <= 0.0:\n' \
		+ '\tcooldown_{{VCNODE_ID}} = {{seconds}}\n' \
		+ '\t{{ready}}\n' \
		+ 'else:\n' \
		+ '\t{{cooling}}'
