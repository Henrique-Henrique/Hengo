@tool
extends HBoxContainer


signal value_changed


var my_value: Vector3i = Vector3i.ZERO


func _ready() -> void:
	get_node('x').connect('value_changed', _on_x_changed)
	get_node('y').connect('value_changed', _on_y_changed)
	get_node('z').connect('value_changed', _on_z_changed)


func _on_x_changed(_value: float) -> void:
	my_value.x = int(_value)
	value_changed.emit(my_value)


func _on_y_changed(_value: float) -> void:
	my_value.y = int(_value)
	value_changed.emit(my_value)


func _on_z_changed(_value: float) -> void:
	my_value.z = int(_value)
	value_changed.emit(my_value)


# public
func set_default(_value) -> void:
	if _value is Vector3i:
		my_value = _value
	elif _value is String:
		# try var_to_str format first
		var parsed = str_to_var(_value)
		if parsed != null and parsed is Vector3i:
			my_value = parsed
		elif _value.begins_with('(') and _value.ends_with(')'):
			var inner = _value.substr(1, _value.length() - 2)
			var parts = inner.split(',')
			if parts.size() >= 3:
				my_value = Vector3i(
					int(float(parts[0].strip_edges())),
					int(float(parts[1].strip_edges())),
					int(float(parts[2].strip_edges()))
				)

	get_node('x').value = my_value.x
	get_node('y').value = my_value.y
	get_node('z').value = my_value.z


func set_default_raw(_value: Vector3i) -> void:
	my_value = _value

	get_node('x').value = my_value.x
	get_node('y').value = my_value.y
	get_node('z').value = my_value.z


func get_value() -> Vector3i:
	return my_value


func get_generated_code() -> String:
	return var_to_str(my_value)
