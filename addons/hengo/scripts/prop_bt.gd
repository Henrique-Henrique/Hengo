@tool
extends Button

enum Types {
	VARIABLE,
}

@export var type: Types = Types.VARIABLE
@export var list_container: VBoxContainer


func _ready() -> void:
	pressed.connect(_on_press)


func _on_press() -> void:
	match type:
		Types.VARIABLE:
			var prop = load('res://addons/hengo/scenes/prop_variable.tscn').instantiate()
			list_container.add_child(prop)