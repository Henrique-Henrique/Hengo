@tool
class_name HenDashboard extends VBoxContainer

var root: TreeItem
@onready var tree: Tree = %Tree


func _ready() -> void:
	tree.item_mouse_selected.connect(_on_item_selected)
	root = tree.create_item()

	add_list(
		get_script_list(DirAccess.open('res://hengo'))
	)

	tree.custom_minimum_size.x = 350
	tree.custom_minimum_size.y = HenGlobal.CAM.get_viewport_rect().size.y * .6


func add_list(_list: Array, _root: TreeItem = root) -> void:
	for item_data: Dictionary in _list:
		var item: TreeItem = _root.create_child()
		item.set_text(0, item_data.name)

		if item_data.has('type'):
			item.set_icon(0, HenAssets.get_icon_texture(item_data.type))

		if item_data.has('folder'):
			item.set_selectable(0, false)
			item.set_icon(0, preload('res://addons/hengo/assets/icons/menu/folder.svg'))
			add_list(item_data.folder, item)
		else:
			item.set_metadata(0, item_data.path)


func _on_item_selected(_mouse_position: Vector2, _mouse_button_index: int) -> void:
	match _mouse_button_index:
		1:
			HenLoader.load(tree.get_selected().get_metadata(0))

	# %Search.text_changed.connect(_on_search)
	# %Create.pressed.connect(_on_create_press)
	# gui_input.connect(_on_gui)

	# show_dashboard()


# func _on_gui(_event: InputEvent) -> void:
# 	if _event is InputEventMouseButton:
# 		if _event.pressed and (_event.button_index == MOUSE_BUTTON_LEFT or _event.button_index == MOUSE_BUTTON_RIGHT):
# 			if can_close:
# 				hide_dashboard()


# func _on_search(_text: String) -> void:
# 	if _text.is_empty():
# 		for item in %List.get_children():
# 			item.visible = true
# 		return
		
# 	for item in %List.get_children():
# 		if (item.item_name as String).to_lower().contains(_text.to_lower()):
# 			item.visible = true
# 		else:
# 			item.visible = false


# func _on_create_press() -> void:
# 	var script_dialog: ScriptCreateDialog = ScriptCreateDialog.new()
# 	script_dialog.script_created.connect(_on_script_created.bind(script_dialog))
# 	script_dialog.config('Node', 'res://hengo/', false, false)

# 	add_child(script_dialog)

# 	script_dialog.popup_centered()


# func _on_script_created(_script: Script, _dialog: ScriptCreateDialog) -> void:
# 	_dialog.queue_free()
# 	hide_dashboard()


# func show_dashboard(_can_close: bool = false) -> void:
# 	visible = true
# 	can_close = _can_close

# 	# cleaning old list
# 	for item in %List.get_children():
# 		item.queue_free()

# 	var script_data: Array = get_script_list(DirAccess.open('res://hengo'))

# 	for script in script_data:
# 		var item = DashBoardItemScene.instantiate()

# 		item.set_item_data({
# 			name = script[0],
# 			path = script[1],
# 			type = script[2]
# 		})
# 		%List.add_child(item)


# parsing scripts
func get_script_list(_dir: DirAccess, _list: Array = []) -> Array:
	_dir.list_dir_begin()

	var file_name: String = _dir.get_next()

	# TODO cache script that don't changed
	while file_name != '':
		if file_name.get_extension() != 'gd' and not _dir.current_is_dir():
			file_name = _dir.get_next()
			continue

		if _dir.current_is_dir():
			_list.append({
				name = file_name.get_basename(),
				folder = get_script_list(DirAccess.open(_dir.get_current_dir() + '/' + file_name))
			})
		else:
			var script: GDScript = ResourceLoader.load(_dir.get_current_dir() + '/' + file_name, '', ResourceLoader.CACHE_MODE_IGNORE)

			if script.source_code.begins_with('#[hengo] '):
				var data: HenSaver.ScriptData = HenLoader.parse_hengo_json(script.source_code)

				_list.append({
					name = file_name.get_basename(),
					path = _dir.get_current_dir() + '/' + file_name,
					type = data.type,
				})
			else:
				_list.append({
					name = file_name.get_basename(),
					path = _dir.get_current_dir() + '/' + file_name,
					type = 'Variant'
				})
		
		file_name = _dir.get_next()

	_dir.list_dir_end()

	return _list


func hide_dashboard() -> void:
	visible = false

	HenGlobal.CAM.can_scroll = true