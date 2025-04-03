@tool
extends HBoxContainer

signal param_changed(_value: String, _name: String)

func _ready() -> void:
    %Name.value_changed.connect(_on_value_changed.bind('name'))
    %Type.value_changed.connect(_on_value_changed.bind('type'))


func set_values(_name: String, _type: String) -> void:
    $Name.text = _name
    %Type.text = _type


func _on_value_changed(_value: String, _name: String) -> void:
    param_changed.emit(_value, _name)