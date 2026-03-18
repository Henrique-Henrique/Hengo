@tool
extends HBoxContainer

signal value_changed

var my_value: Vector3 = Vector3.ZERO

func _ready() -> void:
	get_node('x').connect('value_changed', _on_x_changed)
	get_node('y').connect('value_changed', _on_y_changed)
	get_node('z').connect('value_changed', _on_z_changed)


func _on_x_changed(_value: float) -> void:
	my_value.x = _value
	value_changed.emit(my_value)


func _on_y_changed(_value: float) -> void:
	my_value.y = _value
	value_changed.emit(my_value)


func _on_z_changed(_value: float) -> void:
	my_value.z = _value
	value_changed.emit(my_value)


# public
#
func set_font_size(_size: int) -> void:
	get_node('x').set_font_size(_size)
	get_node('y').set_font_size(_size)
	get_node('z').set_font_size(_size)


func set_default(_value: String) -> void:
	var parsed = str_to_var(_value)
	if parsed != null and parsed is Vector3:
		my_value = parsed
	elif _value.begins_with('(') and _value.ends_with(')'):
		var inner = _value.substr(1, _value.length() - 2)
		var parts = inner.split(',')
		if parts.size() >= 3:
			my_value = Vector3(
				float(parts[0].strip_edges()),
				float(parts[1].strip_edges()),
				float(parts[2].strip_edges())
			)

	get_node('x').value = my_value.x
	get_node('y').value = my_value.y
	get_node('z').value = my_value.z


func set_default_raw(_value: Vector3) -> void:
	my_value = _value

	get_node('x').value = my_value.x
	get_node('y').value = my_value.y
	get_node('z').value = my_value.z


func get_value() -> Vector3:
	return my_value

func get_generated_code() -> String:
	return var_to_str(my_value)