@tool
extends VBoxContainer

const _PropVariable = preload('res://addons/hengo/scripts/prop_variable.gd')

func get_values() -> Dictionary:
	var data: Dictionary = {
		variables = []
	}


	for prop in get_node('%List').get_children():
		match prop.type:
			StringName('VARIABLE'):
				data.variables.append(prop.get_value())


	return data

func get_all_values(_get_item: bool = false) -> Array:
	var arr: Array = []

	for prop in get_node('%List').get_children():
		var dt: Dictionary = prop.get_value()
		dt.prop_type = prop.type
		if _get_item:
			dt.item = prop
		arr.append(dt)

	return arr