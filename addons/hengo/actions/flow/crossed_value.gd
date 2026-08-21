@tool
class_name HenActionCrossedValue extends HenScriptMacroBase


func get_id() -> StringName:
	return &'crossed_value'


func get_description() -> String:
	return 'Fires its branch once on the frame a value passes a limit in the chosen direction, and stays quiet until the value comes back and passes it again. A value already past the limit when the state is entered counts as a crossing, so it fires once per entry.'


func get_display_name() -> String:
	return 'Crossed'


func get_icon() -> String:
	return 'gauge'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Value',
			type = 'Variant',
			id = &'value',
			doc = 'The number to watch, such as health or a combo counter.',
			default_value = null
		},
		{
			name = 'Limit',
			type = 'Variant',
			id = &'limit',
			doc = 'The mark the value has to pass.',
			type_from = &'value',
			default_value = 0
		},
		{
			name = 'Direction',
			type = 'String',
			id = &'direction',
			doc = 'Which side of the limit counts as crossed.',
			options = ['below', 'above'],
			default_value = 'below'
		}
	]


# one memory per action, so two of them in the same state never share it
func get_script_base() -> String:
	return 'var was_past_{{VCNODE_ID}}: bool = false'


func get_flow_reset() -> String:
	return 'was_past_{{VCNODE_ID}} = false'


func get_default_phase() -> StringName:
	return &'update'


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'}
	]


func get_flow_outputs() -> Array[Dictionary]:
	return [
		{name = 'Crossed', id = &'crossed', doc = 'Where to go on the one frame the value passes the limit.'},
		{name = 'Not Yet', id = &'not_yet', doc = 'Where to go on every other frame, the ones where it stays past the limit included.'}
	]


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


# the slots are read into untyped locals first, so a comparison never lands on a
# literal null and fails to parse
func _body() -> String:
	return 'var now_{{VCNODE_ID}} = {{value}}\n' \
		+ 'var limit_{{VCNODE_ID}} = {{limit}}\n' \
		+ _side() \
		+ 'var fired_{{VCNODE_ID}}: bool = past_{{VCNODE_ID}} and not was_past_{{VCNODE_ID}}\n' \
		+ 'was_past_{{VCNODE_ID}} = past_{{VCNODE_ID}}\n' \
		+ 'if fired_{{VCNODE_ID}}:\n' \
		+ '\t{{crossed}}\n' \
		+ 'else:\n' \
		+ '\t{{not_yet}}'


func _side() -> String:
	if is_bound(&'direction'):
		return 'var past_{{VCNODE_ID}}: bool = now_{{VCNODE_ID}} < limit_{{VCNODE_ID}}\n' \
			+ 'if str({{direction}}) == "above":\n' \
			+ '\tpast_{{VCNODE_ID}} = now_{{VCNODE_ID}} > limit_{{VCNODE_ID}}\n'

	if str(value_of(&'direction', 'below')) == 'above':
		return 'var past_{{VCNODE_ID}}: bool = now_{{VCNODE_ID}} > limit_{{VCNODE_ID}}\n'

	return 'var past_{{VCNODE_ID}}: bool = now_{{VCNODE_ID}} < limit_{{VCNODE_ID}}\n'
