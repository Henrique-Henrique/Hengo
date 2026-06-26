@tool
class_name HenCreateCollection extends VBoxContainer

@onready var name_input: LineEdit = %CollectionName
@onready var create_bt: Button = %CreateBt

var _editing: HenSaveCollection = null


func _ready() -> void:
	create_bt.pressed.connect(_on_create)
	name_input.text_submitted.connect(func(_t: String): _on_create())

	if _editing:
		name_input.text = _editing.name
		create_bt.text = 'Rename'
	name_input.grab_focus.call_deferred()


# enables rename mode for an existing collection
func setup_rename(_collection: HenSaveCollection) -> void:
	_editing = _collection


func _on_create() -> void:
	var text: String = name_input.text.strip_edges()

	if text.is_empty():
		return

	var popup: HenGeneralPopup = Engine.get_singleton(&'GeneralPopup')

	if _editing:
		_editing.name = text
		ResourceSaver.save(_editing)
		popup.hide_popup()
		(Engine.get_singleton(&'SignalBus') as HenSignalBus).request_list_update.emit()
		return

	var collection: HenSaveCollection = HenCollectionManager.create_collection(text)
	popup.hide_popup()
	(Engine.get_singleton(&'Loader') as HenLoader).load_collection(collection.id)
