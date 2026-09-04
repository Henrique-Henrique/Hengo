@tool
class_name HenActionHoldCharge extends HenScriptMacroBase


func get_id() -> StringName:
	return &'hold_charge'


func get_description() -> String:
	return 'Fills a value from 0 to 1 while the condition stays true, and drops it back to 0 the moment it breaks. With Seconds = 2, holding the button for one second stores 0.5, which is the width a charge bar draws. Held For answers whether the time is complete; this one answers how far along it is.'


func get_display_name() -> String:
	return 'Hold Charge'


func get_icon() -> String:
	return 'battery-charging'


func get_default_phase() -> StringName:
	return &'update'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Condition',
			type = 'bool',
			id = &'condition',
			doc = 'The test that has to stay true, such as a Compare action placed right here.',
			default_value = true
		},
		{
			name = 'Seconds',
			type = 'float',
			id = &'seconds',
			doc = 'How long holding takes to reach a full charge, in seconds.',
			default_value = 1.0
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Charge', type = 'float', id = &'result', doc = 'Where to store how full the charge is, from 0 to 1.'}
	]


func get_output_result() -> String:
	return 'charge_{{VCNODE_ID}}'


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'}
	]


func get_flow_outputs() -> Array[Dictionary]:
	return [
		{name = 'Full', id = &'full', optional = true, doc = 'Where to go once the charge reached 1. It keeps firing while the condition stays true.'},
		{name = 'Charging', id = &'charging', optional = true, doc = 'Where to go while the charge is still filling or empty.'}
	]


# the charge survives frames, and one counter per action keeps two charges in the
# same state apart
func get_script_base() -> String:
	return 'var charge_{{VCNODE_ID}}: float = 0.0'


func get_flow_reset() -> String:
	return 'charge_{{VCNODE_ID}} = 0.0'


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


func _body() -> String:
	var code: String = 'if {{condition}}:\n' \
		+ '\tcharge_{{VCNODE_ID}} = minf(charge_{{VCNODE_ID}} + delta / maxf({{seconds}}, 0.001), 1.0)\n' \
		+ 'else:\n' \
		+ '\tcharge_{{VCNODE_ID}} = 0.0\n' \
		+ '{{out:result}}'

	if not is_flow_connected(&'full') and not is_flow_connected(&'charging'):
		return code

	return code + '\nif charge_{{VCNODE_ID}} >= 1.0:\n' \
		+ '\t{{full}}\n' \
		+ 'else:\n' \
		+ '\t{{charging}}'
