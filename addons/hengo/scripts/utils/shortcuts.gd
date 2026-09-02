@tool
class_name HenShortcuts
extends RefCounted

# every shortcut the plugin answers to, as data. the flow handler dispatches from
# this list and the help popup renders it, so a binding added here shows up in
# both or in neither

const FLOW: StringName = &'flow'

const GROUP_NAMES: Dictionary = {
	flow = 'Flow view'
}

# method is the name called on the flow viewer; the other groups are handled
# where they live and are listed here for the reader
const LIST: Array[Dictionary] = [
	{
		group = FLOW,
		combo = ['W'],
		title = 'Move step up',
		description = 'Swaps the selected action with the one before it in the same chain.',
		method = '_move_up'
	},
	{
		group = FLOW,
		combo = ['S'],
		title = 'Move step down',
		description = 'Swaps the selected action with the one after it in the same chain.',
		method = '_move_down'
	},
	{
		group = FLOW,
		combo = ['Delete'],
		title = 'Delete action',
		description = 'Removes every selected action, wherever it lives: the state list, a loop body or an input.',
		method = '_delete_selected'
	},
	{
		group = FLOW,
		combo = ['Ctrl', 'Z'],
		title = 'Undo',
		description = 'Steps back through the edits made in the flow view.',
		method = '_undo'
	},
	{
		group = FLOW,
		combo = ['Ctrl', 'Shift', 'Z'],
		title = 'Redo',
		description = 'Replays an edit that was undone.',
		method = '_redo'
	},
	{
		group = FLOW,
		combo = ['Ctrl', 'Y'],
		title = 'Redo',
		description = 'Replays an edit that was undone.',
		method = '_redo'
	},
	{
		group = FLOW,
		combo = ['Ctrl', 'D'],
		title = 'Duplicate action',
		description = 'Drops a copy of every selected action right below it, values and all.',
		method = '_duplicate_selected'
	},
	{
		group = FLOW,
		combo = ['Ctrl', 'C'],
		title = 'Copy actions',
		description = 'Copies every selected step, values and branches included.',
		method = '_copy_selected'
	},
	{
		group = FLOW,
		combo = ['Ctrl', 'V'],
		title = 'Paste actions',
		description = 'Drops the copied steps under the selected one, in the chain it runs in.',
		method = '_paste_actions'
	},
	{
		group = FLOW,
		combo = ['Ctrl', 'A'],
		title = 'Select the chain',
		description = 'Extends the selection to every step of the chain the selected one runs in.',
		method = '_select_chain_shortcut'
	},
	{
		group = FLOW,
		combo = ['Ctrl', 'Click'],
		title = 'Add to selection',
		description = 'Adds a step to the selection, or takes it out when it is already in.'
	},
	{
		group = FLOW,
		combo = ['Shift', 'Click'],
		title = 'Select a range',
		description = 'Selects every step between the last picked one and this one, inside the same chain.'
	},
	{
		group = FLOW,
		combo = ['Esc'],
		title = 'Clear selection',
		description = 'Drops the selection without touching the graph.',
		method = '_clear_selection_shortcut'
	},
	{
		group = FLOW,
		combo = ['Double click'],
		title = 'Full screen',
		description = 'Two clicks on empty canvas open the panel full screen, and two more put it back.'
	},
	{
		group = FLOW,
		combo = ['Right click'],
		title = 'Action menu',
		description = 'Opens the same menu the three dots on the card header do.'
	},
]


# only an entry with a method is a key the flow view answers to: the mouse rows
# are there to be read
static func matches(_entry: Dictionary, _key: InputEventKey) -> bool:
	if not _entry.has('method'):
		return false

	var code: int = 0
	var ctrl: bool = false
	var shift: bool = false
	var alt: bool = false

	for name: String in _entry.combo:
		match name:
			'Ctrl': ctrl = true
			'Shift': shift = true
			'Alt': alt = true
			'Esc': code = KEY_ESCAPE
			'Delete': code = KEY_DELETE
			_: code = OS.find_keycode_from_string(name)

	return code != 0 and _key.keycode == code 		and _key.ctrl_pressed == ctrl and _key.shift_pressed == shift and _key.alt_pressed == alt


static func of_group(_group: StringName) -> Array[Dictionary]:
	var out: Array[Dictionary] = []

	for entry: Dictionary in LIST:
		if entry.group == _group:
			out.append(entry)

	return out


# the groups in the order they are declared, never a hardcoded list: a group
# added to an entry has to reach the popup on its own
static func groups() -> Array[StringName]:
	var out: Array[StringName] = []

	for entry: Dictionary in LIST:
		if not out.has(entry.group):
			out.append(entry.group)

	return out


static func group_name(_group: StringName) -> String:
	return str(GROUP_NAMES.get(str(_group), str(_group).capitalize()))
