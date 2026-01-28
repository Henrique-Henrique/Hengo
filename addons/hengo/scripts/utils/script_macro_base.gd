@tool
@abstract
class_name HenScriptMacroBase

# returns an array of dictionary with { name: string, type: string, id: stringname }
func get_inputs() -> Array[Dictionary]:
	return []

# returns an array of dictionary with { name: string, type: string, id: stringname }
# for each output you need to define a function called get_output_{id} that receives the inputs as arguments and returns the code string
func get_outputs() -> Array[Dictionary]:
	return []

# returns an array of dictionary with { name: string, id: stringname }
func get_flow_inputs() -> Array[Dictionary]:
	return []

# returns an array of dictionary with { name: string, id: stringname }
func get_flow_outputs() -> Array[Dictionary]:
	return []

# returns an array of Dictionary with { name: String, params: Array[{name: String, type: String}], body: Callable }
func get_function_overrides() -> Array[Dictionary]:
	return []

# returns the id of the macro
# you need to return a unique id for each macro to hengo not loose the macro when reloading the project
@abstract func get_id() -> StringName