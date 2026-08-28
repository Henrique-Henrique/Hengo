@tool
class_name HenDashboard extends PanelContainer

const ITEM_SCENE = preload('res://addons/hengo/scenes/utils/dashboard_item.tscn')
const RENAME_POPUP_SCENE = preload('res://addons/hengo/scenes/utils/rename_script_popup.tscn')
const TAB_INDEX: int = 0
const DOCS_URL: String = 'https://hengoscript.com/docs/'

@onready var new_script_bt: Button = %NewScript
@onready var docs_bt: Button = %DocumentationBt
@onready var search_edit: LineEdit = %Search
@onready var script_list_node: VBoxContainer = %ScriptList

var timer: SceneTreeTimer
var script_list: Array[Dictionary]


func _ready() -> void:
	var signal_bus: HenSignalBus = Engine.get_singleton(&'SignalBus')
	signal_bus.request_list_update.connect(_on_list_update)

	search_edit.text_changed.connect(_on_search_change)
	new_script_bt.pressed.connect(_on_create_script)
	docs_bt.pressed.connect(func(): OS.shell_open(DOCS_URL))

	_apply_semantic_colors()

	# refresh whenever the dashboard tab becomes the active one
	var tabs: TabContainer = _get_sidebar_tabs()
	if tabs:
		tabs.tab_changed.connect(_on_sidebar_tab_changed)


func _apply_semantic_colors() -> void:
	var c: Dictionary = HenUtils.UI_COLORS

	HenUtils.tint_button(new_script_bt, c.create)
	HenUtils.tint_button(docs_bt, c.code)


func _get_sidebar_tabs() -> TabContainer:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	if not global or not global.HENGO_ROOT:
		return null
	return global.HENGO_ROOT.get_node_or_null('%SidebarTabContainer') as TabContainer


func _on_sidebar_tab_changed(idx: int) -> void:
	if idx == TAB_INDEX:
		refresh()


func _on_create_script() -> void:
	var c: HenCreateCollection = (load('res://addons/hengo/scenes/utils/create_collection.tscn') as PackedScene).instantiate()
	var anchor: Control = new_script_bt
	(Engine.get_singleton(&'GeneralPopup') as HenGeneralPopup).show_content(c, {
		layout = HenGeneralPopup.Layout.ANCHORED,
		anchor_to = anchor,
		side = SIDE_RIGHT,
		min_size = Vector2(360, 0)
	})


func _on_open_script(meta: Dictionary) -> void:
	if not meta is Dictionary:
		return

	var loader: HenLoader = Engine.get_singleton(&'Loader')

	if loader.load_collection(str(meta.id)):
		hide_dashboard()
	else:
		(Engine.get_singleton(&'ToastContainer') as HenToast).notify.call_deferred("Failed to load collection: " + meta.base_name, HenToast.MessageType.ERROR)


func _on_rename_script(meta: Dictionary, source: Control) -> void:
	var collection_path: String = HenEnums.HENGO_COLLECTION_PATH.path_join(meta.dir_name).path_join(HenEnums.COLLECTION_FILE)

	if not FileAccess.file_exists(collection_path):
		(Engine.get_singleton(&'ToastContainer') as HenToast).notify.call_deferred("Failed to find collection: " + meta.base_name, HenToast.MessageType.ERROR)
		return

	var collection: HenSaveCollection = ResourceLoader.load(collection_path, '', ResourceLoader.CACHE_MODE_REPLACE)
	if not collection:
		(Engine.get_singleton(&'ToastContainer') as HenToast).notify.call_deferred("Failed to load collection: " + meta.base_name, HenToast.MessageType.ERROR)
		return

	var popup: HenCreateCollection = (load('res://addons/hengo/scenes/utils/create_collection.tscn') as PackedScene).instantiate()
	popup.setup_rename(collection)
	(Engine.get_singleton(&'GeneralPopup') as HenGeneralPopup).show_content(popup, {
		layout = HenGeneralPopup.Layout.ANCHORED,
		anchor_to = source,
		side = SIDE_RIGHT,
		min_size = Vector2(340, 0)
	})


func _on_delete_request(meta: Dictionary) -> void:
	HenConfirmPopup.show_confirm(
		"Are you sure you want to delete the collection '%s' and all its scripts?" % meta.base_name,
		_on_delete_confirmed.bind(meta),
		'Delete Collection',
		'Delete',
		'Cancel'
	)


func _on_delete_confirmed(meta: Dictionary) -> void:
	HenCollectionManager.delete_collection(StringName(meta.dir_name))
	show_dashboard()


func _on_search_change(_text: String) -> void:
	debounce_search(0.3, search.bind(_text))


func search(_search_text: String) -> void:
	if _search_text.is_empty():
		update(script_list)
		return
	
	var result: Array[Dictionary] = []

	for script: Dictionary in script_list:
		var score: int = HenSearch.score_only(_search_text.to_lower(), (script.base_name as String).to_lower())
		if score > 0: result.append(script)

	update(result)

func debounce_search(delay: float, callback: Callable) -> void:
	if timer:
		timer.timeout.disconnect(callback)
		timer = null

	timer = get_tree().create_timer(delay)
	timer.timeout.connect(callback)


# refreshes the list only when the dashboard is already visible; never pops it open
func _on_list_update() -> void:
	var tabs: TabContainer = _get_sidebar_tabs()
	if tabs and tabs.current_tab == TAB_INDEX:
		refresh()


func show_dashboard() -> void:
	var tabs: TabContainer = _get_sidebar_tabs()
	if not tabs:
		return
	if tabs.current_tab == TAB_INDEX:
		refresh()
	else:
		tabs.current_tab = TAB_INDEX


func refresh() -> void:
	if script_list_node.get_child_count() > 0:
		script_list_node.get_child(0).queue_free()
		var label = Label.new()
		label.text = "Loading..."
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		script_list_node.add_child(label)
	
	var thread_helper: HenThreadHelper = Engine.get_singleton(&'ThreadHelper')
	thread_helper.add_task(_load_scripts_thread)


func _load_scripts_thread() -> void:
	var new_script_list: Array[Dictionary] = []

	if not DirAccess.dir_exists_absolute(HenEnums.HENGO_COLLECTION_PATH):
		_on_scripts_loaded.call_deferred(new_script_list)
		return

	for dir_name: StringName in DirAccess.get_directories_at(HenEnums.HENGO_COLLECTION_PATH):
		var collection_path: StringName = HenEnums.HENGO_COLLECTION_PATH.path_join(dir_name).path_join(HenEnums.COLLECTION_FILE)

		if not FileAccess.file_exists(collection_path):
			continue

		var collection: HenSaveCollection = ResourceLoader.load(collection_path)
		if not collection:
			continue

		new_script_list.append(
			{
				id = collection.id,
				base_name = collection.name,
				time = FileAccess.get_modified_time(collection_path),
				dir_name = dir_name,
				script_count = collection.script_ids.size()
			}
		)

	new_script_list.sort_custom(func(a, b): return a.time > b.time)
	_on_scripts_loaded.call_deferred(new_script_list)


func _on_scripts_loaded(_data: Array[Dictionary]) -> void:
	script_list = _data
	update(script_list)


func hide_dashboard() -> void:
	# switch to props if currently on dashboard tab
	var tabs: TabContainer = _get_sidebar_tabs()
	if tabs and tabs.current_tab == TAB_INDEX:
		tabs.current_tab = 1
	script_list.clear()


func toggle_dashboard() -> void:
	var tabs: TabContainer = _get_sidebar_tabs()
	if not tabs:
		return
	if tabs.current_tab == TAB_INDEX:
		hide_dashboard()
	else:
		show_dashboard()


func update(_data: Array[Dictionary]) -> void:
	for child in script_list_node.get_children():
		child.queue_free()

	for script: Dictionary in _data:
		var item = ITEM_SCENE.instantiate()
		script_list_node.add_child(item)
		item.setup(script)
		item.open_request.connect(_on_open_script)
		item.rename_request.connect(_on_rename_script)
		item.delete_request.connect(_on_delete_request)
