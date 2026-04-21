@tool
class_name HenCompile extends HBoxContainer

const _ICON_HISTORY: Texture2D = preload('res://addons/hengo/assets/new_icons/history.svg')

@onready var compile_bt: Button = get_node('%Compile')

var _history_bt: Button
var _batch_compiler: HenSaveAll


func _ready() -> void:
	if HenUtils.disable_scene_with_owner(self ):
		return

	compile_bt.pressed.connect(_on_compile_press)

	# small history button — shows the last compile report panel
	_history_bt = Button.new()
	_history_bt.icon = _ICON_HISTORY
	_history_bt.flat = true
	_history_bt.tooltip_text = 'Last compile report'
	_history_bt.visible = not HenCompileResultPanel.last_report.is_empty()
	_history_bt.pressed.connect(_on_history_press)
	add_child(_history_bt)

	set_process(false)


# starts the batch compilation
func _on_compile_press() -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var save_data: HenSaveData = global.SAVE_DATA if global else null

	if not _batch_compiler:
		_batch_compiler = HenSaveAll.new()
		_batch_compiler.batch_started.connect(start)
		_batch_compiler.batch_finished.connect(reset)
	_batch_compiler.start(save_data)


func _on_history_press() -> void:
	if HenCompileResultPanel.last_report.is_empty():
		return
	var global: HenGlobal = Engine.get_singleton(&'Global')
	if not global or not global.HENGO_ROOT:
		return
	var ui_base: Control = global.HENGO_ROOT.get_node_or_null('%UIBase')
	if not ui_base:
		return
	# if a panel is already open, just dismiss it (toggle off)
	for child in ui_base.get_children():
		if child is HenCompileResultPanel:
			child._dismiss()
			return
	# otherwise open a fresh one
	var panel := HenCompileResultPanel.new()
	panel.report = HenCompileResultPanel.last_report
	ui_base.add_child(panel)


func start() -> void:
	set_process(true)
	compile_bt.disabled = true


func reset() -> void:
	set_process(false)
	compile_bt.disabled = false
	if _history_bt:
		_history_bt.visible = not HenCompileResultPanel.last_report.is_empty()
		var success: bool = bool(HenCompileResultPanel.last_report.get('success', false))
		_history_bt.modulate = Color('22c55e') if success else Color('ef4444')


static func start_load() -> void:
	var instance: HenCompile = (Engine.get_singleton(&'Global') as HenGlobal).HENGO_ROOT.get_node('%CompileContainer')
	instance.start()


static func reset_load() -> void:
	var instance: HenCompile = (Engine.get_singleton(&'Global') as HenGlobal).HENGO_ROOT.get_node('%CompileContainer')
	instance.reset()
