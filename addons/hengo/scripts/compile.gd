@tool
class_name HenCompile extends HBoxContainer

@onready var compile_bt: Button = get_node('%Compile')

func _ready() -> void:
	if HenUtils.disable_scene_with_owner(self):
		return
	
	compile_bt.pressed.connect(_on_compile_press)
	set_process(false)
	

var _batch_compiler: HenSaveAll


# starts the batch compilation
func _on_compile_press() -> void:
	if not _batch_compiler:
		_batch_compiler = HenSaveAll.new()
		_batch_compiler.batch_started.connect(start)
		_batch_compiler.batch_finished.connect(reset)
	_batch_compiler.start()


func start() -> void:
	set_process(true)
	compile_bt.disabled = true


func reset() -> void:
	set_process(false)
	compile_bt.disabled = false


static func start_load() -> void:
	var instance: HenCompile = (Engine.get_singleton(&'Global') as HenGlobal).HENGO_ROOT.get_node('%CompileContainer')
	instance.start()


static func reset_load() -> void:
	var instance: HenCompile = (Engine.get_singleton(&'Global') as HenGlobal).HENGO_ROOT.get_node('%CompileContainer')
	instance.reset()
