@tool
class_name HenCompile extends HBoxContainer


var icon: TextureRect

func _ready() -> void:
	icon = get_node('LoadIcon')
	get_node('%Compile').pressed.connect(_on_compile_press)
	set_process(false)


func _on_compile_press() -> void:
	HenCodeGeneration.generate_and_save(self)


func _process(_delta: float) -> void:
	icon.rotation += 5 * _delta