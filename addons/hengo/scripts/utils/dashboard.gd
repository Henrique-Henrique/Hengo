@tool
class_name HenDashboard extends PanelContainer

const ICON = preload('res://addons/hengo/assets/new_icons/file-code.svg')

@onready var close_bt: Button = %CloseBt
@onready var new_script_bt: Button = %NewScript
@onready var search_edit: LineEdit = %Search
@onready var script_list_node: ItemList = %ScriptList

var timer: SceneTreeTimer
var script_list: Array[Dictionary]


func _ready() -> void:
	var signal_bus: HenSignalBus = Engine.get_singleton(&'SignalBus')
	signal_bus.request_list_update.connect(show_dashboard)

	search_edit.text_changed.connect(_on_search_change)
	script_list_node.item_activated.connect(_on_select)
	close_bt.pressed.connect(_on_close)
	new_script_bt.pressed.connect(_on_create_script)


func _on_create_script() -> void:
	var c: HenCreateScript = (load('res://addons/hengo/scenes/utils/create_script.tscn') as PackedScene).instantiate()
	(Engine.get_singleton(&'Global') as HenGlobal).GENERAL_POPUP.show_content(c, 'Expression Editor')


func _on_close() -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')

	if global.script_config:
		hide_dashboard()
		return
	
	global.HENGO_EDITOR_PLUGIN.hide_plugin()


func _on_select(_id: int) -> void:
	var meta = script_list_node.get_item_metadata(_id)

	if not meta is Dictionary:
		return
	
	var loader: HenLoader = Engine.get_singleton(&'Loader')

	if await loader.load(str(meta.id)):
		hide_dashboard()
	else:
		(Engine.get_singleton(&'ToastContainer') as HenToast).notify.call_deferred("Failed to load script: " + meta.base_name, HenToast.MessageType.ERROR)


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
	script_list.clear()

	for dir_name: StringName in DirAccess.get_directories_at(HenEnums.HENGO_SAVE_PATH):
		var identity_path: StringName = HenEnums.HENGO_SAVE_PATH.path_join(dir_name).path_join('identity.tres')

		if not FileAccess.file_exists(identity_path):
			continue
		
		var time: int = FileAccess.get_modified_time(identity_path)
		var identity: HenSaveDataIdentity = ResourceLoader.load(identity_path)

		script_list.append(
			{
				id = identity.id,
				base_name = identity.name,
				time = time
			}
		)
	
	script_list.sort_custom(func(a, b): return a.time > b.time)

	update(script_list)

	visible = true


func hide_dashboard() -> void:
	script_list.clear()
	visible = false


func toggle_dashboard() -> void:
	if visible:
		hide_dashboard()
		return
	
	show_dashboard()


func update(_data: Array[Dictionary]) -> void:
	script_list_node.clear()

	for script: Dictionary in _data:
		var item_id: int = script_list_node.add_item(script.base_name)
		script_list_node.set_item_icon(item_id, ICON)
		script_list_node.set_item_metadata(item_id, script)
