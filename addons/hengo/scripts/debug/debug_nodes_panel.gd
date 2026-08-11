@tool
class_name HenDebugNodesPanel extends PanelContainer

const RE_REQUEST_DELAY: float = 0.4
const SEARCH_DEBOUNCE: float = 0.25

@onready var _search: LineEdit = get_node('%Search')
@onready var _refresh_bt: Button = get_node('%RefreshBt')
@onready var _hint: Label = get_node('%Hint')
@onready var _list: HenVirtualList = get_node('%VirtualList')

# script_id -> Array of node dicts {name, path, id}
var _nodes_by_script: Dictionary = {}
var _script_order: Array = []
# script_id -> chosen instance_id (drives that script's state machine + flow when active)
var _selected_by_script: Dictionary = {}

var _query: String = ''
var _search_pending: bool = false


func _ready() -> void:
	if HenUtils.disable_scene_with_owner(self):
		return

	ThemeUtils.apply_font_size(_search, 13)
	ThemeUtils.apply_font_size(_refresh_bt, 13)
	ThemeUtils.apply_font_size(_hint, 12)

	_refresh_bt.pressed.connect(_on_refresh)
	_search.text_changed.connect(_on_search_changed)

	var signal_bus: HenSignalBus = Engine.get_singleton(&'SignalBus')
	if signal_bus:
		signal_bus.debug_nodes_listed.connect(_on_nodes_listed)
		signal_bus.debug_session_started.connect(_on_session_started)
		signal_bus.debug_session_stopped.connect(_on_session_stopped)
		signal_bus.debug_instance_selected.connect(_on_instance_selected)

	_rebuild()


func _on_session_started() -> void:
	_reset_state()
	# session.started fires before the scene loads, so re-request once it settles
	var tree: SceneTree = get_tree()
	if tree:
		tree.create_timer(RE_REQUEST_DELAY).timeout.connect(_on_refresh, CONNECT_ONE_SHOT)
	_rebuild()


func _on_session_stopped() -> void:
	_reset_state()
	_rebuild()


func _reset_state() -> void:
	_nodes_by_script.clear()
	_script_order.clear()
	_selected_by_script.clear()
	_query = ''
	if _search:
		_search.text = ''


func _on_refresh() -> void:
	var plugin = _plugin()
	if plugin:
		plugin.send_list_nodes()


func _on_search_changed(_text: String) -> void:
	_query = _text
	if _search_pending:
		return
	_search_pending = true
	var tree: SceneTree = get_tree()
	if not tree:
		return
	tree.create_timer(SEARCH_DEBOUNCE).timeout.connect(func() -> void:
		_search_pending = false
		_rebuild()
	, CONNECT_ONE_SHOT)


func _on_nodes_listed(script_id: String, nodes: Array) -> void:
	if not _nodes_by_script.has(script_id):
		_script_order.append(script_id)
	_nodes_by_script[script_id] = nodes

	# default to the first instance so every script's state machine lights up
	if not _selected_by_script.has(script_id) and not nodes.is_empty():
		_select(script_id, int(nodes[0].get('id', -1)), false)

	_rebuild()


func _on_instance_selected(script_id: String, instance_id: int) -> void:
	_select(script_id, instance_id, true)
	_rebuild()


# selects an instance for a script; switch_active also makes it the flow focus
func _select(script_id: String, instance_id: int, switch_active: bool) -> void:
	_selected_by_script[script_id] = instance_id

	var global: HenGlobal = Engine.get_singleton(&'Global')
	var plugin = global.HENGO_DEBUGGER_PLUGIN if global else null
	if plugin:
		plugin.set_state_target(script_id, instance_id)

	if switch_active:
		var sd: HenSaveData = _find_save_data(script_id)
		if sd:
			(Engine.get_singleton(&'Loader') as HenLoader).set_active_script(sd)
		if plugin:
			plugin.set_target(instance_id)
	elif plugin and global and global.SAVE_DATA and String(global.SAVE_DATA.identity.id) == script_id:
		plugin.set_target(instance_id)


func _rebuild() -> void:
	if not _list:
		return

	var arr: Array = _build_rows()

	if arr.is_empty():
		_show_hint()
		return

	_hide_hint()
	_list.set_data(arr)
	await get_tree().process_frame
	if is_instance_valid(_list):
		_list.update(true)


# flattens the per-script nodes into header + node rows, applying the search filter
func _build_rows() -> Array:
	var arr: Array = []
	var q: String = _query.strip_edges().to_lower()

	for script_id: String in _script_order:
		var nodes: Array = _nodes_by_script.get(script_id, [])
		var matched: Array = []
		for n: Dictionary in nodes:
			if q.is_empty() or HenSearch.score_only(q, String(n.get('name', '')).to_lower()) > 0:
				matched.append(n)

		if matched.is_empty():
			continue

		arr.append({type = 'header', name = _script_name(script_id), script_id = script_id, icon_type = _script_type(script_id), custom_height = 28.0})

		var selected: int = int(_selected_by_script.get(script_id, -1))
		for n: Dictionary in matched:
			var nid: int = int(n.get('id', -1))
			arr.append({
				type = 'node',
				script_id = script_id,
				name = n.get('name', '?'),
				path = n.get('path', ''),
				id = nid,
				active = nid == selected,
				custom_height = 30.0,
			})

	return arr


func _script_name(script_id: String) -> String:
	var sd: HenSaveData = _find_save_data(script_id)
	if sd and sd.identity:
		return sd.identity.name
	return script_id


func _script_type(script_id: String) -> StringName:
	var sd: HenSaveData = _find_save_data(script_id)
	if sd and sd.identity:
		return sd.identity.type
	return &''


func _find_save_data(script_id: String) -> HenSaveData:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	if not global:
		return null
	for sd: HenSaveData in global.OPEN_SCRIPTS:
		if sd and sd.identity and String(sd.identity.id) == script_id:
			return sd
	return null


func _plugin():
	var global: HenGlobal = Engine.get_singleton(&'Global')
	return global.HENGO_DEBUGGER_PLUGIN if global else null


func _show_hint() -> void:
	if _hint:
		_hint.text = _empty_hint_text()
		_hint.visible = true
	if _list:
		_list.visible = false


func _hide_hint() -> void:
	if _hint:
		_hint.visible = false
	if _list:
		_list.visible = true


func _empty_hint_text() -> String:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	if global and global.SETTINGS and not global.SETTINGS.debug_compilation:
		return 'Debug compilation is off — enable it in settings and recompile to list live instances.'
	if not _query.strip_edges().is_empty():
		return 'No nodes match the search.'
	return 'No live instances. Press Play and use Refresh after the scene loads.'
