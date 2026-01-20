@tool
extends HBoxContainer


signal value_changed


var my_value: Vector2i = Vector2i.ZERO


func _ready() -> void:
	get_node('x').connect('value_changed', _on_x_changed)
	get_node('y').connect('value_changed', _on_y_changed)


func _on_x_changed(_value: float) -> void:
	my_value.x = int(_value)
	value_changed.emit(var_to_str(my_value))


func _on_y_changed(_value: float) -> void:
	my_value.y = int(_value)
	value_changed.emit(var_to_str(my_value))


# public
func set_default(_value) -> void:
	if _value is Vector2i:
		my_value = _value
	elif _value is String:
		# try var_to_str format first
		var parsed = str_to_var(_value)
		if parsed != null and parsed is Vector2i:
			my_value = parsed
		elif _value.begins_with('(') and _value.ends_with(')'):
			var inner = _value.substr(1, _value.length() - 2)
			var parts = inner.split(',')
			if parts.size() >= 2:
				my_value = Vector2i(
					int(float(parts[0].strip_edges())),
					int(float(parts[1].strip_edges()))
				)

	get_node('x').value = my_value.x
	get_node('y').value = my_value.y


func set_default_raw(_value: Vector2i) -> void:
	my_value = _value

	get_node('x').value = my_value.x
	get_node('y').value = my_value.y


func get_value() -> Vector2i:
	return my_value


func get_generated_code() -> String:
	return var_to_str(my_value)
