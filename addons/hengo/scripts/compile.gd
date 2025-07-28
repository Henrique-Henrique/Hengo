@tool
class_name HenCompile extends HBoxContainer

const LOAD_ICON = preload('res://addons/hengo/assets/icons/loader-circle.svg')
const BUILD_ICON = preload('res://addons/hengo/assets/icons/menu/compile.svg')

var icon: TextureRect
@onready var compile_bt: Button = get_node('%Compile')

func _ready() -> void:
	icon = get_node('LoadIcon')
	compile_bt.pressed.connect(_on_compile_press)
	set_process(false)
	HenGlobal.SIGNAL_BUS.scripts_generation_started.connect(start)
	HenGlobal.SIGNAL_BUS.scripts_generation_finished.connect(reset)
	

func _on_compile_press() -> void:
	HenSaver.save()


func _process(_delta: float) -> void:
	icon.rotation += 5 * _delta


func start() -> void:
	icon.texture = LOAD_ICON
	icon.pivot_offset = icon.size / 2
	set_process(true)
	icon.modulate = Color.SKY_BLUE
	compile_bt.disabled = true


func reset(_script_list: PackedStringArray) -> void:
	icon.texture = BUILD_ICON
	set_process(false)
	icon.rotation = 0
	icon.modulate = Color.WHITE
	compile_bt.disabled = false


static func start_load() -> void:
	var instance: HenCompile = HenGlobal.HENGO_ROOT.get_node('%CompileContainer')
	instance.start()


static func reset_load() -> void:
	var instance: HenCompile = HenGlobal.HENGO_ROOT.get_node('%CompileContainer')
	instance.reset([])
