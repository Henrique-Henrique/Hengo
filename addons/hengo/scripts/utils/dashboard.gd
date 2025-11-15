@tool
class_name HenDashboard extends PanelContainer

const ICON = preload('res://addons/hengo/assets/new_icons/file-code.svg')

@onready var close_bt: Button = %CloseBt
@onready var search_edit: LineEdit = %Search
@onready var script_list_node: ItemList = %ScriptList

var timer: SceneTreeTimer
var script_list: Array[Dictionary]


func _ready() -> void:
	search_edit.text_changed.connect(_on_search_change)
	script_list_node.item_activated.connect(_on_select)
	close_bt.pressed.connect(_on_close)


func _on_close() -> void:
	hide_dashboard()


func _on_select(_id: int) -> void:
	var meta = script_list_node.get_item_metadata(_id)

	if not meta is Dictionary:
		return
	
	var loader: HenLoader = Engine.get_singleton(&'Loader')
	var signal_bus: HenSignalBus = Engine.get_singleton(&'SignalBus')

	if await loader.load(meta.path):
		hide_dashboard()
	else:
		signal_bus.set_terminal_text.emit.call_deferred(HenUtils.get_error_text("Failed to load script: " + meta.path))


func _on_search_change(_text: String) -> void:
	debounce_search(0.3, search.bind(_text))


func search(_search_text: String) -> void:
	if _search_text.is_empty():
		update(script_list)
		return
	
	var result: Array[Dictionary] = []

	for script: Dictionary in script_list:
		prints(_search_text.to_lower(), (script.base_name as String).to_lower())
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
	var global: HenGlobal = Engine.get_singleton(&'Global')

	close_bt.disabled = not global.script_config

	script_list.clear()

	for file_name: StringName in DirAccess.get_files_at('res://hengo/save/'):
		if not file_name.get_extension() == 'hengo':
			continue
		
		var time: int = FileAccess.get_modified_time('res://hengo/save/' + file_name)
		var name_id: StringName = file_name.get_basename()
		var id: int = int(name_id)

		if ResourceUID.has_id(id):
			var path: StringName = ResourceUID.get_id_path(id)
			var base_name: String = path.get_file().get_basename()

			script_list.append(
				{
					path = path,
					base_name = base_name,
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
