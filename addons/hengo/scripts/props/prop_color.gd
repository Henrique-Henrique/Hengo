@tool
extends ColorPickerButton


signal value_changed


func _ready() -> void:
	color_changed.connect(_on_color_changed)


func _on_color_changed(_color: Color) -> void:
	value_changed.emit(_color)


# public
func set_font_size(_size: int) -> void:
	pass


func set_default(_value) -> void:
	if not _value or str(_value) == 'null':
		color = Color()
		return
	
	if _value is Color:
		color = _value
	elif _value is String:
		# try var_to_str format first
		var parsed = str_to_var(_value)
		if parsed != null and parsed is Color:
			color = parsed
		elif _value.begins_with('(') and _value.ends_with(')'):
			var inner = _value.substr(1, _value.length() - 2)
			var parts = inner.split(',')
			if parts.size() >= 3:
				color = Color(
					float(parts[0].strip_edges()),
					float(parts[1].strip_edges()),
					float(parts[2].strip_edges()),
					float(parts[3].strip_edges()) if parts.size() > 3 else 1.0
				)


func get_value() -> Color:
	return color


func get_generated_code() -> String:
	return var_to_str(color)
