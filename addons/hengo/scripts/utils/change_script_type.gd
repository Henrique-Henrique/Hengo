@tool
class_name HenChangeScriptType extends VBoxContainer

const MAX_LISTED: int = 10
const OK_COLOR: Color = Color(0.13, 0.77, 0.37, 1)
const FAIL_COLOR: Color = Color(0.94, 0.27, 0.27, 1)

@onready var current_label: Label = %Current
@onready var extend_bt: HenDropdown = %ExtendBt
@onready var report_label: Label = %Report
@onready var apply_bt: Button = %ApplyBt

var _save_data: HenSaveData
var _target: StringName


func setup(_data: HenSaveData) -> void:
	_save_data = _data


func _ready() -> void:
	current_label.text = '%s extends %s' % [_save_data.identity.name, _save_data.identity.type]
	extend_bt.value_changed.connect(_on_class_selected)
	apply_bt.pressed.connect(_on_apply)
	apply_bt.disabled = true
	report_label.hide()


func _on_class_selected(_class: String) -> void:
	_target = StringName(_class)
	apply_bt.disabled = true
	report_label.show()

	if not HenScriptBaseType.is_valid_base(_target):
		_show_report(_class + ' is not a node, so a script cannot extend it.', FAIL_COLOR)
		return

	if _target == _save_data.identity.type:
		_show_report('The script already extends ' + _class + '.', OK_COLOR)
		return

	var broken: Array[Dictionary] = HenScriptBaseType.preview(_save_data, _target)

	apply_bt.disabled = false
	apply_bt.text = 'Change' if broken.is_empty() else 'Change Anyway'

	if broken.is_empty():
		_show_report('Every action still works on ' + _class + '.', OK_COLOR)
		return

	var lines: PackedStringArray = ['%d action(s) stop working on %s:' % [broken.size(), _class]]

	for err: Dictionary in broken.slice(0, MAX_LISTED):
		lines.append('- ' + str(err.description))

	if broken.size() > MAX_LISTED:
		lines.append('and %d more' % (broken.size() - MAX_LISTED))

	lines.append('They stay in the graph marked as errors, and changing back fixes them.')
	_show_report('\n'.join(lines), FAIL_COLOR)


func _show_report(_text: String, _color: Color) -> void:
	report_label.text = _text
	report_label.add_theme_color_override('font_color', _color)


func _on_apply() -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var signal_bus: HenSignalBus = Engine.get_singleton(&'SignalBus')

	HenScriptBaseType.apply(_save_data, _target)

	if global.SAVE_DATA == _save_data:
		(Engine.get_singleton(&'Loader') as HenLoader).show_class_name()

	if global.HENGO_ROOT:
		global.HENGO_ROOT.refresh_script_state()
		global.HENGO_ROOT.schedule_check_errors()

	signal_bus.request_list_update.emit()
	signal_bus.request_structural_update.emit()

	(Engine.get_singleton(&'ToastContainer') as HenToast).notify.call_deferred(
		_save_data.identity.name + ' now extends ' + str(_target) + '. Compile to update the script file.',
		HenToast.MessageType.SUCCESS
	)
	(Engine.get_singleton(&'GeneralPopup') as HenGeneralPopup).hide_popup()
