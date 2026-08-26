@tool
@abstract
class_name HenActionTweenBase extends HenScriptMacroBase

# shared machine of the animated actions: keeps the tween it created so its own
# finished signal drives the Finished branch, and kills it when the state ends so
# an animation left behind never transitions on its way out.
# lives outside actions/ on purpose — the loader scans that folder and would take
# this abstract base for a macro.
#
# without the kept slot a second run stacks a new animation over the live one and
# reads the resting value off a property already mid animation. on a per-frame
# phase the body also waits for the last one to finish, so the effect repeats
# while the state runs instead of starting one every frame.
# inside a loop body one animation is started per iteration, so the slot is a list
# there and the teardown walks it


const FINISH_SLOT: StringName = &'finished'
# longer than any animation, so one step lands on the last value of the tween
const CANCEL_STEP: float = 9999.0


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
			# the branch runs from the tween signal, where a return would only leave the lambda
			from_signal = true,
			doc = 'Where to go when the animation ends. Leaving the state first cancels it, so it never fires late.'
		}
	]


# the per-frame guard asks whether the last animation ended, and inside a loop that
# question has no answer: the body runs once per item on every single frame
func get_validation_error() -> String:
	if in_loop() and per_frame():
		return 'an animation inside a loop has to run on enter, not every frame'

	return ''


func get_script_base() -> String:
	if in_loop():
		return 'var tweens_{{VCNODE_ID}}: Array[Tween] = []'

	return 'var tween_{{VCNODE_ID}}: Tween = null'


func get_flow_teardown() -> String:
	if not in_loop():
		return cancel_lines('tween_{{VCNODE_ID}}', '')

	return 'for t_{{VCNODE_ID}}: Tween in tweens_{{VCNODE_ID}}:\n' \
		+ cancel_lines('t_{{VCNODE_ID}}', '\t') + '\n' \
		+ 'tweens_{{VCNODE_ID}}.clear()'


func reports_finish() -> bool:
	return is_flow_connected(FINISH_SLOT)


func per_frame() -> bool:
	return action_phase == &'update' or action_phase == &'physics'


func in_loop() -> bool:
	return loop_depth > 0


# true when the last value of the tween is the only sane place to stop
func finishes_on_cancel() -> bool:
	return false


# running the animation out fires finished, so the handlers go before the step
func cancel_lines(_name: String, _indent: String) -> String:
	var out: String = _indent + 'if ' + _name + ' and ' + _name + '.is_valid():\n'

	if finishes_on_cancel():
		out += _indent + '\tfor con_{{VCNODE_ID}}: Dictionary in ' + _name + '.finished.get_connections():\n' \
			+ _indent + '\t\t' + _name + '.finished.disconnect(con_{{VCNODE_ID}}.callable)\n' \
			+ _indent + '\t' + _name + '.custom_step(' + str(CANCEL_STEP) + ')\n'

	return out + _indent + '\t' + _name + '.kill()'


# where a created tween is put so the teardown can reach it
func keep_line(_local: String) -> String:
	if in_loop():
		return 'tweens_{{VCNODE_ID}}.append(' + _local + ')'

	return 'tween_{{VCNODE_ID}} = ' + _local


# an animation that ended is no longer held: the branch below may leave the state,
# and the teardown cannot step a tween from inside that tween's own step
func release_line(_local: String) -> String:
	if in_loop():
		return 'tweens_{{VCNODE_ID}}.erase(' + _local + ')'

	return 'tween_{{VCNODE_ID}} = null'


func connect_line(_local: String) -> String:
	return _local + '.finished.connect(func() -> void:\n' \
		+ '\t' + release_line(_local) + '\n' \
		+ '\t{{finished}}\n' \
		+ '\t)'


# the one-tween case: _chain is what is called on the tween itself, such as
# tween_property(...)
func start_tween(_chain: String) -> String:
	var local: String = 't_{{VCNODE_ID}}' if in_loop() else 'tween_{{VCNODE_ID}}'
	var out: String = ('var ' if in_loop() else '') + local + ' = _ref.create_tween()\n' \
		+ local + '.' + _chain

	if in_loop():
		out += '\n' + keep_line(local)

	if reports_finish():
		out += '\n' + connect_line(local)

	return out


# the many-tweens case: an action that already built its own tween hands the name
# over. the guard covers a path that built none
func finish_hook(_local: String) -> String:
	var lines: String = 'if ' + _local + ':\n' \
		+ '\t' + keep_line(_local)

	if reports_finish():
		lines += '\n\t' + connect_line(_local).replace('\n', '\n\t')

	return lines


# a per-frame phase must not stack a new animation every frame, so the body only
# runs again once the last one finished
func guard_per_frame(_body: String) -> String:
	if not per_frame():
		return _body

	var out: String = 'if tween_{{VCNODE_ID}} == null or not tween_{{VCNODE_ID}}.is_running():\n'

	for line: String in _body.split('\n'):
		out += '\t' + line + '\n'

	return out.strip_edges(false, true)
