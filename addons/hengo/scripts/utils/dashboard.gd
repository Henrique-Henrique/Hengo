@tool
class_name HenDashboard extends PanelContainer

const ITEM_SCENE = preload('res://addons/hengo/scenes/utils/dashboard_item.tscn')

@onready var close_bt: Button = %CloseBt
@onready var new_script_bt: Button = %NewScript
@onready var search_edit: LineEdit = %Search
@onready var script_list_node: VBoxContainer = %ScriptList

var timer: SceneTreeTimer
var script_list: Array[Dictionary]


func _ready() -> void:
	var signal_bus: HenSignalBus = Engine.get_singleton(&'SignalBus')
	signal_bus.request_list_update.connect(show_dashboard)

	search_edit.text_changed.connect(_on_search_change)
	close_bt.pressed.connect(_on_close)
	new_script_bt.pressed.connect(_on_create_script)
	
	visibility_changed.connect(_on_visibility_changed)


func _on_create_script() -> void:
	var c: HenCreateScript = (load('res://addons/hengo/scenes/utils/create_script.tscn') as PackedScene).instantiate()
	(Engine.get_singleton(&'GeneralPopup') as HenGeneralPopup).show_content(c, 'Expression Editor')


func _on_close() -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')

	if global.SAVE_DATA:
		hide_dashboard()
		return
	
	global.HENGO_EDITOR_PLUGIN.hide_plugin()


func _on_open_script(meta: Dictionary) -> void:
	if not meta is Dictionary:
		return
	
	var loader: HenLoader = Engine.get_singleton(&'Loader')

	if loader.load(str(meta.id)):
		hide_dashboard()
	else:
		(Engine.get_singleton(&'ToastContainer') as HenToast).notify.call_deferred("Failed to load script: " + meta.base_name, HenToast.MessageType.ERROR)


func _on_edit_properties_script(meta: Dictionary) -> void:
	var identity_path: String = HenEnums.HENGO_SAVE_PATH.path_join(meta.dir_name).path_join('identity' + HenEnums.SAVE_EXTENSION)
	
	if not FileAccess.file_exists(identity_path):
		(Engine.get_singleton(&'ToastContainer') as HenToast).notify.call_deferred("Failed to find identity file for: " + meta.base_name, HenToast.MessageType.ERROR)
		return

	# TODO: inspector cant edit this
	var res: Resource = ResourceLoader.load(identity_path, '', ResourceLoader.CACHE_MODE_REPLACE)
	if res:
		HenInspector.edit_resource(res)


func _on_delete_request(meta: Dictionary) -> void:
	HenConfirmPopup.show_confirm(
		"Are you sure you want to delete '%s'?" % meta.base_name,
		_on_delete_confirmed.bind(meta),
		'Delete Script',
		'Delete',
		'Cancel'
	)


func _on_delete_confirmed(meta: Dictionary) -> void:
	var path = HenEnums.HENGO_SAVE_PATH.path_join(meta.dir_name)
	var global_path = ProjectSettings.globalize_path(path)
	
	OS.move_to_trash(global_path)
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


func show_dashboard() -> void:
	if not visible:
		visible = true
	else:
		refresh()

func _on_visibility_changed() -> void:
	if is_visible_in_tree():
		refresh()

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
	
	for dir_name: StringName in DirAccess.get_directories_at(HenEnums.HENGO_SAVE_PATH):
		var identity_path: StringName = HenEnums.HENGO_SAVE_PATH.path_join(dir_name).path_join('identity' + HenEnums.SAVE_EXTENSION)

		if not FileAccess.file_exists(identity_path):
			continue
		
		var save_path: StringName = HenEnums.HENGO_SAVE_PATH.path_join(dir_name).path_join('save' + HenEnums.SAVE_EXTENSION)
		
		# check both identity and save file to get the latest edit time
		var time: int = FileAccess.get_modified_time(identity_path)
		if FileAccess.file_exists(save_path):
			var save_time: int = FileAccess.get_modified_time(save_path)
			if save_time > time:
				time = save_time

		var identity: HenSaveDataIdentity = ResourceLoader.load(identity_path)

		new_script_list.append(
			{
				id = identity.id,
				base_name = identity.name,
				time = time,
				dir_name = dir_name,
				type = identity.type
			}
		)
	
	new_script_list.sort_custom(func(a, b): return a.time > b.time)
	_on_scripts_loaded.call_deferred(new_script_list)


func _on_scripts_loaded(_data: Array[Dictionary]) -> void:
	script_list = _data
	update(script_list)


func hide_dashboard() -> void:
	await RenderingServer.frame_pre_draw
	script_list.clear()
	visible = false


func toggle_dashboard() -> void:
	if visible:
		hide_dashboard()
		return
	
	show_dashboard()


func update(_data: Array[Dictionary]) -> void:
	for child in script_list_node.get_children():
		child.queue_free()

	for script: Dictionary in _data:
		var item = ITEM_SCENE.instantiate()
		script_list_node.add_child(item)
		item.setup(script)
		item.open_request.connect(_on_open_script)
		item.edit_request.connect(_on_edit_properties_script)
		item.delete_request.connect(_on_delete_request)
