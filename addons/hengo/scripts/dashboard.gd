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
			var _path: String = _dir.get_current_dir() + '/' + file_name
			_list.append({
				name = file_name.get_basename(),
				path = _path,
				type = HenEnums.SCRIPT_LIST_DATA[_path].type if HenEnums.SCRIPT_LIST_DATA.has(_path) else 'Variant'
			})
		
		file_name = _dir.get_next()

	_dir.list_dir_end()

	return _list


func hide_dashboard() -> void:
	visible = false

	HenGlobal.CAM.can_scroll = true