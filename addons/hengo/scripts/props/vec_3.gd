@tool
extends HBoxContainer

var my_value: Vector3 = Vector3.ZERO

func _ready() -> void:
	get_node('x').connect('value_changed', _on_x_changed)
	get_node('y').connect('value_changed', _on_y_changed)
	get_node('z').connect('value_changed', _on_z_changed)


func _on_x_changed(_value: float) -> void:
	my_value.x = _value


func _on_y_changed(_value: float) -> void:
	my_value.y = _value


func _on_z_changed(_value: float) -> void:
	my_value.z = _value


# public
#
func set_default(_value: String) -> void:
	my_value = str_to_var(_value)

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