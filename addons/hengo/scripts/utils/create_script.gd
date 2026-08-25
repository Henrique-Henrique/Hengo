@tool
class_name HenCreateScript extends VBoxContainer

@onready var script_name_input: LineEdit = %ScriptName
@onready var create_bt: Button = %CreateBt
@onready var create_and_open_bt: Button = %CreateOpen
@onready var extend_bt: HenDropdown = %ExtendBt


func _ready() -> void:
	create_bt.pressed.connect(_on_create)
	create_and_open_bt.pressed.connect(_on_create.bind(true))


func _on_create(_open: bool = false) -> void:
	var text: String = script_name_input.text

	if text.is_empty():
		return

	var script_name: String = text.to_snake_case().get_basename()
	var _class: StringName = extend_bt.text if ClassDB.class_exists(extend_bt.text) else 'Node'
	var script: Dictionary = create_script(script_name, _class)

	if script.result != OK:
		return

	var global: HenGlobal = Engine.get_singleton(&'Global')
	global.OPEN_SCRIPTS.append(script.data)

	if _open:
		(Engine.get_singleton(&'Loader') as HenLoader).set_active_script(script.data)
	else:
		(Engine.get_singleton(&'SignalBus') as HenSignalBus).request_list_update.emit()

	(Engine.get_singleton(&'GeneralPopup') as HenGeneralPopup).hide_popup()


func create_script(_name: String, _class: StringName) -> Dictionary:
	var collection: HenSaveCollection = HenCollectionManager.ensure_active_collection()

	var id: int = ResourceUID.create_id()
	var collection_dir: String = HenEnums.HENGO_COLLECTION_PATH.path_join(collection.id)
	var id_path: String = collection_dir.path_join(str(id))

	if not DirAccess.dir_exists_absolute(id_path):
		DirAccess.make_dir_recursive_absolute(id_path)

	var identity: HenSaveDataIdentity = HenSaveDataIdentity.create(str(id), _class, _name)
	identity.script_path = HenEnums.HENGO_SCRIPTS_PATH + _name + '.gd'
	var res: HenSaveData = get_save_content(identity)

	identity.take_over_path(id_path.path_join(HenEnums.IDENTITY_FILE))
	res.take_over_path(id_path.path_join(HenEnums.SAVE_FILE))

	var result_identity: int = ResourceSaver.save(identity)

	# the base state is its own file that save.res points at, and the folder only
	# resolves by id once identity.res is on disk
	HenUtils.save_side_bar_item(res.get_base_state(), identity.id, HenSideBar.SideBarItem.STATES)

	var result: int = ResourceSaver.save(res)

	if result != OK or result_identity != OK:
		print('Error saving script: ', result)
		return { result = result, id = id, data = res }

	# register the new script in the active collection manifest
	collection.add_script(StringName(str(id)))
	collection.last_active_id = StringName(str(id))
	HenCollectionManager.save_active_collection()
	HenUtils.rebuild_script_index()

	return {
		result = result,
		id = id,
		data = res
	}

func get_save_content(_identity: HenSaveDataIdentity) -> HenSaveData:
	var save_data: HenSaveData = HenSaveData.new()
	var _class: StringName = extend_bt.text if ClassDB.class_exists(extend_bt.text) else 'Node'

	save_data.identity = _identity
	save_data.counter = 1
	save_data.ensure_base_state()

	return save_data