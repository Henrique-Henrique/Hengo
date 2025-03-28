@tool
class_name HenDashboard extends PanelContainer


@onready var DashBoardItemScene = preload('res://addons/hengo/scenes/dashboard_item.tscn')

var can_close: bool = false

func _ready() -> void:
	%Search.text_changed.connect(_on_search)
	%Create.pressed.connect(_on_create_press)
	gui_input.connect(_on_gui)

	show_dashboard()


func _on_gui(_event: InputEvent) -> void:
	if _event is InputEventMouseButton:
		if _event.pressed and (_event.button_index == MOUSE_BUTTON_LEFT or _event.button_index == MOUSE_BUTTON_RIGHT):
			if can_close:
				hide_dashboard()


func _on_search(_text: String) -> void:
	if _text.is_empty():
		for item in %List.get_children():
			item.visible = true
		return
		
	for item in %List.get_children():
		if (item.item_name as String).to_lower().contains(_text.to_lower()):
			item.visible = true
		else:
			item.visible = false


func _on_create_press() -> void:
	var script_dialog: ScriptCreateDialog = ScriptCreateDialog.new()
	script_dialog.script_created.connect(_on_script_created.bind(script_dialog))
	script_dialog.config('Node', 'res://hengo/', false, false)

	add_child(script_dialog)

	script_dialog.popup_centered()


func _on_script_created(_script: Script, _dialog: ScriptCreateDialog) -> void:
	_dialog.queue_free()
	hide_dashboard()


func show_dashboard(_can_close: bool = false) -> void:
	visible = true
	can_close = _can_close

	# cleaning old list
	for item in %List.get_children():
		item.queue_free()

	var script_data: Array = get_script_list(DirAccess.open('res://hengo'))

	for script in script_data:
		var item = DashBoardItemScene.instantiate()

		item.set_item_data({
			name = script[0],
			path = script[1],
			type = script[2]
		})
		%List.add_child(item)


func get_script_list(_dir: DirAccess, _list: Array[Array] = []) -> Array[Array]: # [name, path, type]
	# parsing scripts
	_dir.list_dir_begin()

	var file_name: String = _dir.get_next()

	# TODO cache script that don't changed
	while file_name != '':
		if file_name.get_extension() != 'gd':
			file_name = _dir.get_next()
			continue

		if _dir.current_is_dir():
			get_script_list(DirAccess.open('res://hengo/' + file_name), _list)
		else:
			var script: GDScript = ResourceLoader.load(_dir.get_current_dir() + '/' + file_name, '', ResourceLoader.CACHE_MODE_IGNORE)

			if script.source_code.begins_with('#[hengo] '):
				var data: HenSaver.ScriptData = HenLoader.parse_hengo_json(script.source_code)

				_list.append([file_name.get_basename(), _dir.get_current_dir() + '/' + file_name, data.type])
			else:
				_list.append([file_name.get_basename(), _dir.get_current_dir() + '/' + file_name, ''])
		
		file_name = _dir.get_next()

	_dir.list_dir_end()

	return _list


func hide_dashboard() -> void:
	visible = false

	HenGlobal.CNODE_CAM.can_scroll = true
	HenGlobal.STATE_CAM.can_scroll = true