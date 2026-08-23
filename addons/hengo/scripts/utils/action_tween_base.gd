@tool
@abstract
class_name HenActionTweenBase extends HenScriptMacroBase

# shared machine of the animated actions: keeps the tween it created so its own
# finished signal drives the Finished branch, and kills it when the state ends so
# an animation left behind never transitions on its way out.
# lives outside actions/ on purpose — the loader scans that folder and would take
# this abstract base for a macro.
#
# nothing is declared while Finished is unwired: the action keeps emitting the one
# line it always did, so it stays usable inside a loop body


const FINISH_SLOT: StringName = &'finished'


func get_flow_outputs() -> Array[Dictionary]:
	return [
		{
			name = 'Finished',
			id = FINISH_SLOT,
			optional = true,
			doc = 'Where to go when the animation ends. Leaving the state first cancels it, so it never fires late.'
		}
	]


# only while the branch is wired: an unwired action declares no state and stays
# nestable, since a class-level declaration is not collected inside a loop
func get_script_base() -> String:
	return 'var tween_{{VCNODE_ID}}: Tween = null' if reports_finish() else ''


func get_flow_teardown() -> String:
	if not reports_finish():
		return ''

	return 'if tween_{{VCNODE_ID}} and tween_{{VCNODE_ID}}.is_valid():\n' \
		+ '\ttween_{{VCNODE_ID}}.kill()'


func reports_finish() -> bool:
	return is_flow_connected(FINISH_SLOT)


# the one-tween case: _chain is what is called on the tween itself, such as
# tween_property(...). without the branch it stays the plain one-liner
func start_tween(_chain: String) -> String:
	if not reports_finish():
		return '_ref.create_tween().' + _chain

	return 'tween_{{VCNODE_ID}} = _ref.create_tween()\n' \
		+ 'tween_{{VCNODE_ID}}.' + _chain + '\n' \
		+ finish_hook('tween_{{VCNODE_ID}}')


# the many-tweens case: an action that already built its own tween hands the name
# over, and the branch runs from that one. the guard covers a path that built none
func finish_hook(_local: String) -> String:
	if not reports_finish():
		return ''

	var keep: String = '' if _local == 'tween_{{VCNODE_ID}}' else 'tween_{{VCNODE_ID}} = ' + _local + '\n'

	return 'if ' + _local + ':\n' \
		+ HenActionTweenBase._indent(keep) \
		+ '\ttween_{{VCNODE_ID}}.finished.connect(func() -> void:\n' \
		+ '\t\t{{finished}}\n' \
		+ '\t\t)'


static func _indent(_lines: String) -> String:
	if _lines.is_empty():
		return ''

	return '\t' + _lines
