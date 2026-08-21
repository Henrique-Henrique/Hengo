@tool
class_name HenActionValueChanged extends HenScriptMacroBase


func get_id() -> StringName:
	return &'value_changed'


func get_description() -> String:
	return 'Fires its branch on the frame a value stops being what it was, and reports the value it held before. The first run after the state is entered only records the value, so it never fires on entry.'


func get_display_name() -> String:
	return 'When It Changes'


func get_icon() -> String:
	return 'arrow-right-left'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Value',
			type = 'Variant',
			id = &'value',
			doc = 'The value to watch, such as the current weapon or the phase name.',
			default_value = null
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Previous', type = 'Variant', id = &'previous', doc = 'The value held until this change.'}
	]


func get_output_previous() -> String:
	return 'was_{{VCNODE_ID}}'


# one memory per action, so two of them in the same state never share it
func get_script_base() -> String:
	return 'var prev_{{VCNODE_ID}} = null\n' \
		+ 'var seen_{{VCNODE_ID}}: bool = false'


func get_flow_reset() -> String:
	return 'prev_{{VCNODE_ID}} = null\n' \
		+ 'seen_{{VCNODE_ID}} = false'


func get_default_phase() -> StringName:
	return &'update'


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'}
	]


func get_flow_outputs() -> Array[Dictionary]:
	return [
		{name = 'Changed', id = &'changed', doc = 'Where to go on the one frame the value is different.'},
		{name = 'Same', id = &'same', doc = 'Where to go while the value stays the same.'}
	]


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


# the memory is updated before the branch, which may transition and never come back
func _body() -> String:
	return 'var now_{{VCNODE_ID}} = {{value}}\n' \
		+ 'var was_{{VCNODE_ID}} = prev_{{VCNODE_ID}}\n' \
		+ 'var changed_{{VCNODE_ID}}: bool = seen_{{VCNODE_ID}} and now_{{VCNODE_ID}} != was_{{VCNODE_ID}}\n' \
		+ 'prev_{{VCNODE_ID}} = now_{{VCNODE_ID}}\n' \
		+ 'seen_{{VCNODE_ID}} = true\n' \
		+ 'if changed_{{VCNODE_ID}}:\n' \
		+ '\t{{out:previous}}\n' \
		+ '\t{{changed}}\n' \
		+ 'else:\n' \
		+ '\t{{same}}'
