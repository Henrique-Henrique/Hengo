@tool
@abstract
class_name HenScriptMacroBase

# returns an array of dictionary with { name: string, type: string, id: stringname }
func get_inputs() -> Array[Dictionary]:
	return []


# returns an array of dictionary with { name: string, type: string, id: stringname }
# for each output define a func get_output_{id}() -> String that returns the expression
# placeholders: {{input_id}} for each input, {{VCNODE_ID}} for unique instance id
func get_outputs() -> Array[Dictionary]:
	return []


# returns an array of dictionary with { name: string, id: stringname }
func get_flow_inputs() -> Array[Dictionary]:
	return []


# returns an array of dictionary with { name: string, id: stringname }
func get_flow_outputs() -> Array[Dictionary]:
	return []


# returns an array of Dictionary with { name: String, params: Array[{name: String, type: String}], body: Variant }
# body can be a String template or a Callable that returns a String template
# string templates support {{VCNODE_ID}} and any input/flow output ids as {{placeholder}}
func get_function_overrides() -> Array[Dictionary]:
	return []


# returns an optional string of gdscript code injected as class-level variables
# use {{VCNODE_ID}} to make variable names unique per instance
func get_script_base() -> String:
	return ''


# returns the id of the macro
# must be unique so hengo doesn't lose the macro when reloading the project
@abstract func get_id() -> StringName