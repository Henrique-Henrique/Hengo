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

	if _open:
		var loader: HenLoader = Engine.get_singleton(&'Loader')
		loader.load(str(script.id))
	else:
		var signal_bus: HenSignalBus = Engine.get_singleton(&'SignalBus')
		signal_bus.request_list_update.emit()

	(Engine.get_singleton(&'Global') as HenGlobal).GENERAL_POPUP.hide_popup()


func get_save_content(_identity: HenSaveDataIdentity) -> HenSaveData:
	var save_data: HenSaveData = HenSaveData.new()
	var _class: StringName = extend_bt.text if ClassDB.class_exists(extend_bt.text) else 'Node'

	save_data.identity = _identity
	save_data.counter = 1

	var base_route: HenRouteData = save_data.create_route(save_data.identity.id, 'Base', HenRouter.ROUTE_TYPE.BASE)

	HenVirtualCNode.instantiate_virtual_cnode(
		{
			can_delete = false,
			id = 1,
			name = 'Stat State',
			position = 'Vector2(0, 0)',
			size = 'Vector2(99, 63)',
			sub_type = HenVirtualCNode.SubType.STATE_START,
			type = HenVirtualCNode.Type.STATE_START,
			route = base_route
		}
	)
	
	return save_data


func create_script(_name: String, _class: StringName) -> Dictionary:
	var id: int = ResourceUID.create_id()
	var id_path: StringName = HenEnums.HENGO_SAVE_PATH.path_join(str(id))

	if not DirAccess.dir_exists_absolute(id_path):
		DirAccess.make_dir_absolute(id_path)

	var identity: HenSaveDataIdentity = HenSaveDataIdentity.create(str(id), _class, _name)
	var res: HenSaveData = get_save_content(identity)

	identity.take_over_path(id_path.path_join('identity.tres'))
	res.take_over_path(id_path.path_join('save.tres'))

	var result_identity: int = ResourceSaver.save(identity)
	var result: int = ResourceSaver.save(res)

	if result == OK and result_identity == OK:
		print('Success saving')
	else:
		print('Error saving script: ', result)
	
	return {
		result = result,
		id = id
	}