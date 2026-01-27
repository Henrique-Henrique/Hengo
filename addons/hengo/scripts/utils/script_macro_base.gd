@tool
@abstract
class_name HenScriptMacroBase extends RefCounted

# returns the id of the macro
# you need to return a unique id for each macro to hengo not loose the macro when reloading the project
func get_id() -> int:
	return 10000

# returns an array of dictionary with { name: string, type: string, id: int }
func get_inputs() -> Array[Dictionary]:
	return []

# returns an array of dictionary with { name: string, type: string, id: int }
func get_outputs() -> Array[Dictionary]:
	return []

# returns an array of dictionary with { name: string, id: int }
func get_flow_inputs() -> Array[Dictionary]:
	return []

# returns an array of dictionary with { name: string, id: int }
func get_flow_outputs() -> Array[Dictionary]:
	return []

# returns an array of Dictionary with { name: String, params: Array[{name: String, type: String}], body: Callable }
func get_function_overrides() -> Array[Dictionary]:
	return []