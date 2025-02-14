@tool
class_name HenPropBt extends Button

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
			var prop = preload('res://addons/hengo/scenes/prop_variable.tscn').instantiate()
			prop.start_prop()
			list_container.add_child(prop)