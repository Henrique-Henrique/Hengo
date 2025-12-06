@tool
class_name HenCompile extends HBoxContainer

@onready var compile_bt: Button = get_node('%Compile')

func _ready() -> void:
	if HenUtils.disable_scene_with_owner(self):
		return
	
	var signal_bus: HenSignalBus = Engine.get_singleton(&'SignalBus')
	compile_bt.pressed.connect(_on_compile_press)
	set_process(false)

	signal_bus.scripts_generation_started.connect(start)
	signal_bus.scripts_generation_finished.connect(reset)
	

func _on_compile_press() -> void:
	HenSaver.save()


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
