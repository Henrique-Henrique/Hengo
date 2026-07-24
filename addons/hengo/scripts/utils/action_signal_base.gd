@tool
@abstract
class_name HenActionSignalBase extends HenScriptMacroBase

# shared machine of the event actions: arms a signal connection on enter, drops
# it on exit and raises a flag the phase body branches on.
# lives outside actions/ on purpose — the loader scans that folder and would
# take this abstract base for a macro.

# id of the optional slot that receives the signal argument
const ARG_SLOT: StringName = &'store_arg'


# the signal to listen to, as gdscript source (a quoted literal in a preset, the
# {{signal}} placeholder in the generic action)
@abstract func get_signal_code() -> String


# how many arguments the signal sends: it has to match, godot refuses a callable
# that expects more than the signal provides
func get_arg_count() -> int:
	return 0


func get_flow_outputs() -> Array[Dictionary]:
	return [
		{name = 'Received', id = &'received', doc = 'Where to go when the signal is received.'}
	]


# a flag is only useful while the state is running, so no enter and no exit
func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'}
	]


# no placeholder here: this text never goes through the input substitution, only
# through {{VCNODE_ID}}. anything the user configured is resolved in the body
func get_script_base() -> String:
	var lines: PackedStringArray = [
		'var emitter_{{VCNODE_ID}} = null',
		'var fired_{{VCNODE_ID}}: bool = false'
	]

	if get_arg_count() > 0:
		lines.append('var value_{{VCNODE_ID}} = null')

	lines.append('')
	lines.append('func _on_signal_{{VCNODE_ID}}(' + _callback_params() + ') -> void:')

	if get_arg_count() > 0:
		lines.append('\tvalue_{{VCNODE_ID}} = arg_{{VCNODE_ID}}')

	lines.append('\tfired_{{VCNODE_ID}} = true')

	return '\n'.join(lines)


# the emitter is resolved once and kept, so exit never re-runs a get_node() whose
# node may already be gone
func get_flow_reset() -> String:
	return 'fired_{{VCNODE_ID}} = false\n' \
		+ 'emitter_{{VCNODE_ID}} = {{emitter}}\n' \
		+ 'if is_instance_valid(emitter_{{VCNODE_ID}}) and not emitter_{{VCNODE_ID}}.is_connected(' + get_signal_code() + ', _on_signal_{{VCNODE_ID}}):\n' \
		+ '\temitter_{{VCNODE_ID}}.connect(' + get_signal_code() + ', _on_signal_{{VCNODE_ID}})'


func get_flow_teardown() -> String:
	return 'if is_instance_valid(emitter_{{VCNODE_ID}}) and emitter_{{VCNODE_ID}}.is_connected(' + get_signal_code() + ', _on_signal_{{VCNODE_ID}}):\n' \
		+ '\temitter_{{VCNODE_ID}}.disconnect(' + get_signal_code() + ', _on_signal_{{VCNODE_ID}})'


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


# the store line lives here, not in the script base: this is the path that runs
# the input substitution, so {{store_arg}} resolves to the user's variable
func _body() -> String:
	var lines: PackedStringArray = [
		'if fired_{{VCNODE_ID}}:',
		'\tfired_{{VCNODE_ID}} = false'
	]

	if get_arg_count() > 0 and is_bound(ARG_SLOT):
		lines.append('\t{{' + str(ARG_SLOT) + '}} = value_{{VCNODE_ID}}')

	lines.append('\t{{received}}')

	return '\n'.join(lines)


func _callback_params() -> String:
	return 'arg_{{VCNODE_ID}}' if get_arg_count() > 0 else ''


# the node holding the signal, shared by every event action
func _emitter_input() -> Dictionary:
	return {
		name = 'Emitter',
		type = 'Node',
		id = &'emitter',
			doc = 'The node that emits the signal, such as an Area2D or a Button.',
		bind_only = true,
		default_value = null
	}


# where the signal argument lands; leaving it empty just drops the value
func _store_input(_name: String) -> Dictionary:
	return {
		name = _name,
		type = 'Variant',
		id = ARG_SLOT,
			doc = 'Variable that receives the value the signal sends. Optional.',
		lvalue = true,
		optional = true,
		default_value = null
	}
