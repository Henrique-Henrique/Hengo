@tool
@abstract
class_name HenActionTweenBase extends HenScriptMacroBase

# shared machine of the animated actions: keeps the tween it created so its own
# finished signal drives the Finished branch, and kills it when the state ends so
# an animation left behind never transitions on its way out.
# lives outside actions/ on purpose — the loader scans that folder and would take
# this abstract base for a macro.
#
# on enter it stays the one line it always was, with nothing declared. on a
# per-frame phase the tween is kept in a slot and only started again once the last
# one finished, so the effect repeats while the state runs instead of stacking a
# new animation every frame


const FINISH_SLOT: StringName = &'finished'


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'}
	]


func get_default_phase() -> StringName:
	return &'enter'


func get_flow_outputs() -> Array[Dictionary]:
	return [
		{
			name = 'Finished',
			id = FINISH_SLOT,
			optional = true,
			doc = 'Where to go when the animation ends. Leaving the state first cancels it, so it never fires late.'
		}
	]


# the slot is what the branch reads on finish and what a per-frame phase checks
# before starting again. an enter body that reports nothing declares nothing
func get_script_base() -> String:
	return 'var tween_{{VCNODE_ID}}: Tween = null' if keeps_tween() else ''


func get_flow_teardown() -> String:
	if not keeps_tween():
		return ''

	return 'if tween_{{VCNODE_ID}} and tween_{{VCNODE_ID}}.is_valid():\n' \
		+ '\ttween_{{VCNODE_ID}}.kill()'


func reports_finish() -> bool:
	return is_flow_connected(FINISH_SLOT)


func per_frame() -> bool:
	return action_phase == &'update' or action_phase == &'physics'


func keeps_tween() -> bool:
	return reports_finish() or per_frame()


# the one-tween case: _chain is what is called on the tween itself, such as
# tween_property(...). with nothing to keep it stays the plain one-liner
func start_tween(_chain: String) -> String:
	if not keeps_tween():
		return '_ref.create_tween().' + _chain

	return 'tween_{{VCNODE_ID}} = _ref.create_tween()\n' \
		+ 'tween_{{VCNODE_ID}}.' + _chain \
		+ ('\n' + finish_hook('tween_{{VCNODE_ID}}') if reports_finish() else '')


# the many-tweens case: an action that already built its own tween hands the name
# over. the guard covers a path that built none
func finish_hook(_local: String) -> String:
	if not keeps_tween():
		return ''

	var own: bool = _local == 'tween_{{VCNODE_ID}}'
	var lines: String = 'if ' + _local + ':\n'

	if not own:
		lines += '\ttween_{{VCNODE_ID}} = ' + _local + '\n'

	if not reports_finish():
		# nothing to report: the slot only has to survive the frame that filled it
		return '' if own else lines.trim_suffix('\n')

	return lines \
		+ '\ttween_{{VCNODE_ID}}.finished.connect(func() -> void:\n' \
		+ '\t\t{{finished}}\n' \
		+ '\t\t)'


# a per-frame phase must not stack a new animation every frame, so the body only
# runs again once the last one finished
func guard_per_frame(_body: String) -> String:
	if not per_frame():
		return _body

	var out: String = 'if tween_{{VCNODE_ID}} == null or not tween_{{VCNODE_ID}}.is_running():\n'

	for line: String in _body.split('\n'):
		out += '\t' + line + '\n'

	return out.strip_edges(false, true)
