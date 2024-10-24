@tool
extends HBoxContainer

# imports
const _CodeGeneration = preload('res://addons/hengo/scripts/code_generation.gd')

var icon: TextureRect

func _ready() -> void:
	icon = get_node('LoadIcon')
	get_node('%Compile').pressed.connect(_on_compile_press)
	set_process(false)


func _on_compile_press() -> void:
	# icon.pivot_offset = icon.size / 2
	# icon.texture = load('res://addons/hengo/assets/icons/menu/loading.svg')
	# set_process(true)

	_CodeGeneration.generate_and_save(self)


# func generate() -> void:
# 	_CodeGeneration.generate_and_save(self)


# func success() -> void:
# 	set_process(false)

# 	icon.rotation = 0
# 	icon.texture = load('res://addons/hengo/assets/icons/menu/compile.svg')


func _process(_delta: float) -> void:
	icon.rotation += 5 * _delta