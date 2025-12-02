@tool
class_name HenInspector extends EditorInspector

# initializes the inspector within the custom popup system
static func edit_resource(_res: Resource) -> void:
	var global: HenGlobal = Engine.get_singleton('Global')
	var inspector: HenInspector = HenInspector.new()

	inspector.add_theme_stylebox_override('panel', StyleBoxEmpty.new())
	inspector.focus_mode = Control.FOCUS_ALL

	global.GENERAL_POPUP.show_content(inspector)
	inspector.edit(_res)

	global.CURRENT_INSPECTOR = inspector
	inspector.grab_focus()


func undo_redo(is_undo: bool) -> void:
	var current_res: Object = get_edited_object()
	if not current_res:
		return

	var undo_manager: EditorUndoRedoManager = EditorInterface.get_editor_undo_redo()
	var history_id: int = undo_manager.get_object_history_id(current_res)
	var undo_object: UndoRedo = undo_manager.get_history_undo_redo(history_id)

	if not undo_object:
		return

	if is_undo:
		undo_object.undo()
	else:
		undo_object.redo()