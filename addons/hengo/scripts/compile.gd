@tool
class_name HenCompile extends HBoxContainer

@onready var compile_bt: Button = get_node('%Compile')

func _ready() -> void:
	compile_bt.pressed.connect(_on_compile_press)
	set_process(false)
	HenGlobal.SIGNAL_BUS.scripts_generation_started.connect(start)
	HenGlobal.SIGNAL_BUS.scripts_generation_finished.connect(reset)
	

func _on_compile_press() -> void:
	HenSaver.save()


func start() -> void:
	set_process(true)
	compile_bt.disabled = true


func reset(_script_list: PackedStringArray) -> void:
	set_process(false)
	compile_bt.disabled = false


static func start_load() -> void:
	var instance: HenCompile = HenGlobal.HENGO_ROOT.get_node('%CompileContainer')
	instance.start()


static func reset_load() -> void:
	var instance: HenCompile = HenGlobal.HENGO_ROOT.get_node('%CompileContainer')
	instance.reset([])
