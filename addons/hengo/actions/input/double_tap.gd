@tool
class_name HenActionDoubleTap extends HenScriptMacroBase


# the second turn is what fires, so the first one is only remembered. the window
# is measured between the two turns and never between a turn and a release


func get_id() -> StringName:
	return &'double_tap'


func get_description() -> String:
	return 'Takes Tapped the second time the condition turns true, when the two moments land within Window seconds of each other. With Window = 0.3 and a Check Key placed in Condition, hitting shift twice quickly is what an air dash listens for. A lone press takes Waiting and is kept as the start of a possible pair.'


func get_display_name() -> String:
	return 'Double Tap'


func get_icon() -> String:
	return 'chevrons-right'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Condition',
			type = 'bool',
			id = &'condition',
			doc = 'The test whose two turns make the pair, such as a Check Key or a Check Action placed right here.',
			default_value = true
		},
		{
			name = 'Window',
			type = 'float',
			id = &'window',
			doc = 'How long the second press has to arrive, in seconds.',
			default_value = 0.3
		}
	]


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'}
	]


func get_flow_outputs() -> Array[Dictionary]:
	return [
		{name = 'Tapped', id = &'tapped', optional = true, doc = 'Where to go on the frame the second press lands.'},
		{name = 'Waiting', id = &'waiting', optional = true, doc = 'Where to go on every other frame.'}
	]


func get_validation_error() -> String:
	return gate_validation_error()


# the pair is remembered across frames, and the down flag is what turns a condition
# that stays true into a single turn
func get_script_base() -> String:
	return 'var tap_at_{{VCNODE_ID}}: float = -99.0\nvar tap_down_{{VCNODE_ID}}: bool = false'


func get_flow_reset() -> String:
	return 'tap_at_{{VCNODE_ID}} = -99.0\ntap_down_{{VCNODE_ID}} = false'


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


func _body() -> String:
	return 'var down_{{VCNODE_ID}}: bool = {{condition}}\n' \
		+ 'var pressed_{{VCNODE_ID}}: bool = down_{{VCNODE_ID}} and not tap_down_{{VCNODE_ID}}\n' \
		+ 'var paired_{{VCNODE_ID}}: bool = false\n' \
		+ 'tap_down_{{VCNODE_ID}} = down_{{VCNODE_ID}}\n' \
		+ 'if pressed_{{VCNODE_ID}}:\n' \
		+ '\tvar now_{{VCNODE_ID}}: float = Time.get_ticks_msec() / 1000.0\n' \
		+ '\tpaired_{{VCNODE_ID}} = now_{{VCNODE_ID}} - tap_at_{{VCNODE_ID}} <= {{window}}\n' \
		+ '\ttap_at_{{VCNODE_ID}} = -99.0 if paired_{{VCNODE_ID}} else now_{{VCNODE_ID}}\n' \
		+ 'if paired_{{VCNODE_ID}}:\n' \
		+ '\t{{tapped}}\n' \
		+ 'else:\n' \
		+ '\t{{waiting}}'
