@tool
class_name HenProjectSearch extends VBoxContainer

const SCENE_PATH: String = 'res://addons/hengo/scenes/project_search.tscn'
const TAB_COLLECTION: int = 0
const TAB_PROJECT: int = 1
const DEBOUNCE_S: float = 0.08
const SPINNER_DELAY_MS: int = 300
const SPIN_SPEED: float = 4.0
const PAGE_STEP: int = 8
const POPUP_SIZE: Vector2 = Vector2(760, 520)
const READ_BUDGET_USEC: int = 8000

@onready var _tabs: TabBar = %Tabs
@onready var _spinner: TextureRect = %Spinner
@onready var _status: Label = %Status
@onready var _search: LineEdit = %Search
@onready var _list: HenVirtualList = %List
@onready var _empty: Label = %Empty
@onready var _footer: HBoxContainer = %Footer

var selected_index: int = -1
var _results: Array[Dictionary] = []
var _macros: Dictionary = {}
var _open_records: Array[Dictionary] = []
var _collection_records: Array[Dictionary] = []
var _project_records: Array[Dictionary] = []
var _project_ready: bool = false
var _project_loading: bool = false
var _query_token: int = 0
var _search_token: int = 0
var _busy_since: int = -1
# Array of records, or { script_id, collection } still to be read from disk
var _read_items: Array = []
var _read_index: int = 0


static func open() -> HenProjectSearch:
	var view: HenProjectSearch = (load(SCENE_PATH) as PackedScene).instantiate()

	(Engine.get_singleton(&'GeneralPopup') as HenGeneralPopup).show_content(view, {
		layout = HenGeneralPopup.Layout.COMPACT,
		min_size = POPUP_SIZE
	})

	return view


func _ready() -> void:
	if HenUtils.disable_scene_with_owner(self):
		return

	set_process(false)

	var global: HenGlobal = Engine.get_singleton(&'Global') if Engine.has_singleton(&'Global') else null
	var has_collection: bool = global != null and global.ACTIVE_COLLECTION != null

	_macros = HenSearchIndex.macro_snapshot()
	_open_records = HenSearchIndex.open_records(_macros)
	_collection_records = _open_records + HenSearchIndex.collection_records(str(global.ACTIVE_COLLECTION.id) if has_collection else '')

	_tabs.set_tab_disabled(TAB_COLLECTION, not has_collection)
	_tabs.current_tab = TAB_COLLECTION if has_collection else TAB_PROJECT

	ThemeUtils.apply_font_size(_search, 15)
	ThemeUtils.apply_font_size(_tabs, 12)
	ThemeUtils.apply_font_size(_status, 11)
	ThemeUtils.apply_font_size(_empty, 13)

	for label: Node in _footer.find_children('*', 'Label', true, false):
		ThemeUtils.apply_font_size(label as Label, 11 if label.name == &'Text' else 10)

	_tabs.tab_changed.connect(_on_tab_changed)
	_search.text_changed.connect(_on_text_changed)
	_search.gui_input.connect(_on_search_input)
	_search.grab_focus.call_deferred()

	_sync_placeholder()
	_refresh()


func _process(_delta: float) -> void:
	if _project_loading:
		_read_step()

	_spinner.visible = _busy_since >= 0 and Time.get_ticks_msec() - _busy_since >= SPINNER_DELAY_MS
	_spinner.pivot_offset = _spinner.size / 2.0
	_spinner.rotation += _delta * SPIN_SPEED


func hover_index(_index: int) -> void:
	if _index == selected_index:
		return

	selected_index = _index
	_sync_selection(false)


func pick_index(_index: int) -> void:
	if _index < 0 or _index >= _results.size():
		return

	HenSearchNavigator.go.call_deferred(_results[_index])


func _on_tab_changed(_tab: int) -> void:
	_sync_placeholder()
	_refresh()


func _on_text_changed(_text: String) -> void:
	_query_token += 1

	var token: int = _query_token

	await get_tree().create_timer(DEBOUNCE_S).timeout

	if token != _query_token or not is_inside_tree():
		return

	_refresh()


func _on_search_input(_event: InputEvent) -> void:
	if not _event is InputEventKey or not (_event as InputEventKey).pressed:
		return

	var key: InputEventKey = _event

	match key.keycode:
		KEY_DOWN:
			_move(1)
		KEY_UP:
			_move(-1)
		KEY_PAGEDOWN:
			_move(PAGE_STEP)
		KEY_PAGEUP:
			_move(-PAGE_STEP)
		KEY_ENTER, KEY_KP_ENTER:
			pick_index(selected_index)
		KEY_TAB:
			_switch_tab()
		KEY_ESCAPE:
			_close()
		KEY_K:
			if not key.ctrl_pressed:
				return

			_close()
		_:
			return

	_search.accept_event()


func _move(_step: int) -> void:
	if _results.is_empty():
		return

	selected_index = clampi(selected_index + _step, 0, _results.size() - 1)
	_sync_selection(true)


func _sync_selection(_scroll: bool) -> void:
	if _scroll:
		_list.ensure_visible(selected_index)

	var rows: Dictionary = _list.get_active_items()

	for idx: int in rows:
		var row: HenProjectSearchRow = rows[idx] as HenProjectSearchRow

		if is_instance_valid(row):
			row.set_selected(idx == selected_index)


func _switch_tab() -> void:
	var next: int = (_tabs.current_tab + 1) % _tabs.tab_count

	if not _tabs.is_tab_disabled(next):
		_tabs.current_tab = next


func _close() -> void:
	(Engine.get_singleton(&'GeneralPopup') as HenGeneralPopup).hide_popup()


func _sync_placeholder() -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global') if Engine.has_singleton(&'Global') else null

	if _tabs.current_tab == TAB_COLLECTION and global and global.ACTIVE_COLLECTION:
		_search.placeholder_text = 'Search in ' + global.ACTIVE_COLLECTION.name
	else:
		_search.placeholder_text = 'Search the whole project'


func _refresh() -> void:
	if _tabs.current_tab == TAB_PROJECT and not _project_ready:
		_load_project()
		return

	_search_token += 1
	_set_busy(true)

	var records: Array[Dictionary] = _project_records if _tabs.current_tab == TAB_PROJECT else _collection_records

	_start_job(HenSearchIndex.search.bind(records, _search.text), &'_on_search_done', _search_token)


func _load_project() -> void:
	if _project_loading:
		return

	var global: HenGlobal = Engine.get_singleton(&'Global') if Engine.has_singleton(&'Global') else null
	var active_id: String = str(global.ACTIVE_COLLECTION.id) if global and global.ACTIVE_COLLECTION else ''

	_read_items = HenSearchIndex.project_plan(active_id, _open_records)
	_read_index = 0
	_project_loading = true
	_set_busy(true)
	_status.text = 'Reading the project'


func _read_step() -> void:
	var start: int = Time.get_ticks_usec()

	while _read_index < _read_items.size() and Time.get_ticks_usec() - start < READ_BUDGET_USEC:
		var item: Variant = _read_items[_read_index]

		if item is Dictionary:
			_read_items[_read_index] = HenSearchIndex.read_script(item.script_id, item.collection, _macros)

		_read_index += 1

	if _read_index < _read_items.size():
		return

	_project_records.clear()

	for records: Array in _read_items:
		_project_records.append_array(records)

	_read_items.clear()
	_project_loading = false
	_project_ready = true
	_refresh()


func _on_search_done(_token: int, _found: Variant) -> void:
	if _token != _search_token:
		return

	_results.assign(_found)
	selected_index = 0 if not _results.is_empty() else -1

	var items: Array = []

	for idx: int in _results.size():
		items.append({record = _results[idx], index = idx, view = self})

	_list.set_data(items)

	if not _project_loading:
		_set_busy(false)

	var query: String = _search.text.strip_edges()

	_empty.visible = _results.is_empty()
	_list.visible = not _results.is_empty()
	_empty.text = ('Nothing matches "' + query + '"') if not query.is_empty() else 'No scripts here yet'

	if query.is_empty():
		_status.text = ''
	elif _results.size() >= HenSearchIndex.MAX_RESULTS:
		_status.text = str(HenSearchIndex.MAX_RESULTS) + '+ results'
	else:
		_status.text = str(_results.size()) + (' result' if _results.size() == 1 else ' results')


func _set_busy(_busy: bool) -> void:
	if _busy:
		if _busy_since < 0:
			_busy_since = Time.get_ticks_msec()

		set_process(true)
		return

	_busy_since = -1
	_spinner.visible = false
	set_process(false)


func _start_job(_work: Callable, _deliver: StringName, _token: int) -> void:
	var job: Dictionary = {work = _work, result = null, target = weakref(self), deliver = _deliver, token = _token}

	(Engine.get_singleton(&'ThreadHelper') as HenThreadHelper).add_task(HenProjectSearch._run_job.bind(job), HenProjectSearch._finish_job.bind(job))


static func _run_job(_job: Dictionary) -> void:
	_job.result = (_job.work as Callable).call()


static func _finish_job(_job: Dictionary) -> void:
	var target: Object = (_job.target as WeakRef).get_ref()

	if target:
		target.call(_job.deliver, _job.token, _job.result)
