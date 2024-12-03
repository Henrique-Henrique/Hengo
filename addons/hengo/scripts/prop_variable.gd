@tool
extends HBoxContainer

const type = StringName('VARIABLE')


func _ready() -> void:
	($Name as LineEdit).text_changed.connect(_on_change_name)
	$Types.value_changed.connect(_on_type_changed)


func _on_change_name(_new_text) -> void:
	get_tree().call_group('p' + str(get_index()), 'set_default', _new_text)


func _on_type_changed(_type: String) -> void:
	get_tree().call_group('p' + str(get_index()), 'set_default', 't:' + _type)


func get_value() -> Dictionary:
	return {
		name = $Name.text,
		type = get_node('Types').get_value(),
		'export' = (get_node('Export') as CheckBox).button_pressed,
		prop_type = 'prop'
	}


func set_value(_dict: Dictionary) -> void:
	$Name.text = _dict.name
	get_node('Types').set_default(_dict.type)
	(get_node('Export') as CheckBox).button_pressed = _dict. export
