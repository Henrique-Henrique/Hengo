@tool
class_name HenRenameScriptPopup extends VBoxContainer

@onready var category_input: LineEdit = %Category
@onready var name_input: LineEdit = %ScriptName
@onready var warning_label: Label = %Warning
@onready var confirm_bt: Button = %ConfirmBt

var _identity: HenSaveDataIdentity


func setup(identity: HenSaveDataIdentity) -> void:
	_identity = identity


func _ready() -> void:
	warning_label.hide()
	confirm_bt.pressed.connect(_on_confirm)
	_prefill_fields()


# fills inputs from the stored script_path if available
func _prefill_fields() -> void:
	if not _identity or _identity.script_path.is_empty():
		return

	var rel_path: String = _identity.script_path
	var base: String = HenEnums.HENGO_SCRIPTS_PATH
	if rel_path.begins_with(base):
		rel_path = rel_path.substr(base.length())

	var slash_idx: int = rel_path.rfind('/')
	if slash_idx >= 0:
		category_input.text = rel_path.substr(0, slash_idx + 1)
		name_input.text = rel_path.substr(slash_idx + 1).get_basename()
	else:
		name_input.text = rel_path.get_basename()


func _on_confirm() -> void:
	warning_label.hide()

	var category: String = category_input.text.strip_edges()
	var script_name: String = name_input.text.strip_edges()

	if script_name.is_empty():
		warning_label.text = 'Script name cannot be empty.'
		warning_label.show()
		return

	# validate category: segments of [a-zA-Z0-9_] separated by /, no leading slash
	if not category.is_empty():
		if not _validate_category(category):
			warning_label.text = 'Invalid category. Use format: objects/car/ (letters, numbers, _ and / only)'
			warning_label.show()
			return
		if not category.ends_with('/'):
			category += '/'

	var clean_name: String = script_name.to_snake_case().get_basename()
	var target_path: String = HenEnums.HENGO_SCRIPTS_PATH + category + clean_name + '.gd'
	var target_uid_path: String = target_path + '.uid'

	var current_path: String = _identity.script_path
	if current_path.is_empty():
		current_path = HenEnums.HENGO_SCRIPTS_PATH + str(_identity.id) + '.gd'
	var current_uid_path: String = current_path + '.uid'

	# read uid before moving so we can match open scenes later
	var script_uid: String = ''
	if FileAccess.file_exists(current_uid_path):
		var uid_file: FileAccess = FileAccess.open(current_uid_path, FileAccess.READ)
		if uid_file:
			script_uid = uid_file.get_as_text().strip_edges()
			uid_file.close()

	var target_dir: String = target_path.get_base_dir()
	if not DirAccess.dir_exists_absolute(target_dir):
		var err: int = DirAccess.make_dir_recursive_absolute(target_dir)
		if err != OK:
			warning_label.text = 'Failed to create directory: ' + target_dir
			warning_label.show()
			return

	if FileAccess.file_exists(current_path) and current_path != target_path:
		var move_err: int = DirAccess.rename_absolute(current_path, target_path)
		if move_err != OK:
			warning_label.text = 'Failed to move script: error ' + str(move_err)
			warning_label.show()
			return

	if FileAccess.file_exists(current_uid_path) and current_uid_path != target_uid_path:
		DirAccess.rename_absolute(current_uid_path, target_uid_path)

	_identity.script_path = target_path
	var identity_path: String = HenEnums.HENGO_SAVE_PATH.path_join(str(_identity.id)).path_join('identity' + HenEnums.SAVE_EXTENSION)
	ResourceSaver.save(_identity, identity_path)

	if Engine.is_editor_hint():
		var fs: EditorFileSystem = EditorInterface.get_resource_filesystem()
		fs.update_file(current_path)
		fs.update_file(target_path)
		# after scan finishes, reload only scenes that referenced the moved script
		fs.filesystem_changed.connect(
			_reload_affected_scenes.bind(current_path, script_uid),
			CONNECT_ONE_SHOT
		)
		fs.scan()

	var toast: HenToast = Engine.get_singleton(&'ToastContainer')
	if toast:
		toast.notify.call_deferred('Script renamed to: ' + clean_name + '.gd', HenToast.MessageType.SUCCESS)

	(Engine.get_singleton(&'GeneralPopup') as HenGeneralPopup).hide_popup()


func _validate_category(cat: String) -> bool:
	var test: String = cat
	if test.ends_with('/'):
		test = test.substr(0, test.length() - 1)
	if test.begins_with('/'):
		return false
	var segments: PackedStringArray = test.split('/')
	for seg: String in segments:
		if seg.is_empty():
			return false
		for ch: String in seg.split(''):
			var c: int = ch.unicode_at(0)
			var is_alpha: bool = (c >= 65 and c <= 90) or (c >= 97 and c <= 122)
			var is_digit: bool = c >= 48 and c <= 57
			var is_under: bool = c == 95
			if not (is_alpha or is_digit or is_under):
				return false
	return true


# reloads open scenes that still reference the old script path or uid
func _reload_affected_scenes(old_path: String, uid: String) -> void:
	for scene_path: String in EditorInterface.get_open_scenes():
		var f: FileAccess = FileAccess.open(scene_path, FileAccess.READ)
		if not f:
			continue
		var content: String = f.get_as_text()
		f.close()
		var references_old: bool = old_path in content or (not uid.is_empty() and uid in content)
		if references_old:
			EditorInterface.reload_scene_from_path(scene_path)
