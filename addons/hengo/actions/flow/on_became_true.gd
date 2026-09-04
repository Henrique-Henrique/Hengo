@tool
class_name HenActionOnBecameTrue extends HenScriptMacroBase


func get_id() -> StringName:
	return &'on_became_true'


func get_description() -> String:
	return 'Fires only on the frame the condition turns true, and stays quiet while it keeps being true. Holding a button takes Became True on the frame it goes down and Other Frames while it stays down. A condition already true on entry counts as turning true. Either branch can run actions of its own, so a small bit of behaviour needs no state of its own.'


func get_display_name() -> String:
	return 'Just Became True'


func get_icon() -> String:
	return 'toggle-right'


# the branch the steps of an older save belong to
func get_body_branch() -> StringName:
	return &'became_true'


# nothing nested and no branch wired means an if/else of two passes
func get_validation_error() -> String:
	return gate_validation_error()


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Condition',
			type = 'bool',
			id = &'condition',
			doc = 'The test to watch, such as a comparison kept in a variable or a Compare action placed right here.',
			default_value = false
		}
	]


# one memory per action, so two of them in the same state never share it
func get_script_base() -> String:
	return 'var was_true_{{VCNODE_ID}}: bool = false'


func get_flow_reset() -> String:
	return 'was_true_{{VCNODE_ID}} = false'


func get_default_phase() -> StringName:
	return &'update'


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'}
	]


func get_flow_outputs() -> Array[Dictionary]:
	return [
		{name = 'Became True', id = &'became_true', optional = true, doc = 'Where to go on the one frame the condition turns true.'},
		{name = 'Other Frames', id = &'not_yet', optional = true, doc = 'Where to go on every other frame, the ones where it stays true included.'}
	]


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


# a ternary and not a cast, since the slot may hold a value that is only truthy
func _body() -> String:
	return 'var now_{{VCNODE_ID}}: bool = true if {{condition}} else false\n' \
		+ 'var fired_{{VCNODE_ID}}: bool = now_{{VCNODE_ID}} and not was_true_{{VCNODE_ID}}\n' \
		+ 'was_true_{{VCNODE_ID}} = now_{{VCNODE_ID}}\n' \
		+ 'if fired_{{VCNODE_ID}}:\n' \
		+ '\t{{became_true}}\n' \
		+ 'else:\n' \
		+ '\t{{not_yet}}'
