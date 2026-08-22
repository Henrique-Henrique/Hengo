@tool
class_name HenActionCode
extends RefCounted

# the string-template side of code generation: reading a macro script's body,
# filling its {{placeholders}} and writing a literal. it came out of the cnode
# generator, which is the only reason it used to live there

static func process_script_macro_body(body: String, use_self: bool, macro_id: Variant = null) -> String:
	if use_self:
		var regex: RegEx = RegEx.new()
		regex.compile('\\b_ref\\b')
		body = regex.sub(body, 'self', true)

	if macro_id != null:
		body = body.replace('{{VCNODE_ID}}', str(macro_id))

	return body
static func _inject_placeholder(body: String, placeholder: String, injection: String) -> String:
	# replace {{placeholder}} with injected code preserving line indentation
	var lines: PackedStringArray = body.split('\n')
	var result: String = ''
	var token: String = '{{' + placeholder + '}}'

	for line: String in lines:
		if line.contains(token):
			var line_indent: String = line.substr(0, line.length() - line.strip_edges(true, false).length())
			var injection_lines: PackedStringArray = injection.split('\n')
			var indented: String = injection_lines[0]
			for j: int in range(1, injection_lines.size()):
				indented += '\n' + line_indent + injection_lines[j]
			result += line.replace(token, indented) + '\n'
		else:
			result += line + '\n'

	return result
static func parse_script_function(script: String, func_name: String) -> Dictionary:
	# parse script text to extract the string-template body and its {{placeholders}}
	var lines: PackedStringArray = script.split('\n')
	var found: bool = false
	var is_string_return: bool = false
	var raw_body: String = ''
	var base_indent: int = 0

	for i: int in range(lines.size()):
		var line: String = lines[i]
		if not found:
			var stripped: String = line.strip_edges()
			if stripped.begins_with('func ' + func_name + '('):
				found = true
				is_string_return = '-> String' in stripped or '->String' in stripped

				for j: int in range(i + 1, lines.size()):
					var next_line: String = lines[j]
					if not next_line.strip_edges().is_empty():
						base_indent = next_line.length() - next_line.strip_edges(true, false).length()
						break
		else:
			if line.strip_edges().is_empty():
				raw_body += '\n'
				continue

			var current_indent: int = line.length() - line.strip_edges(true, false).length()

			if is_string_return:
				# keep reading until closing triple-quote is found in accumulated body
				raw_body += line.substr(0) + '\n'
				if raw_body.count('"""') >= 2:
					break
			else:
				if current_indent < base_indent:
					break
				raw_body += line.substr(base_indent) + '\n'

	if not found:
		return {}

	var body: String
	if is_string_return:
		# extract content from triple-quoted string: """..."""
		var tq_start: int = raw_body.find('"""')
		var tq_end: int = raw_body.rfind('"""')
		if tq_start != -1 and tq_end != tq_start:
			body = raw_body.substr(tq_start + 3, tq_end - tq_start - 3)
			body = body.strip_edges(false, true)
			if body.begins_with('\n'):
				body = body.substr(1)
		else:
			# single-line string return: return "code"
			var ret_line: String = raw_body.strip_edges()
			if ret_line.begins_with('return '):
				body = ret_line.trim_prefix('return ').strip_edges().trim_prefix('"').trim_suffix('"')
			else:
				body = ret_line
	else:
		body = raw_body.strip_edges(false, true)

	# normalize spaces to tabs
	var indent_size: int = 4
	if Engine.is_editor_hint():
		var settings = EditorInterface.get_editor_settings()
		if settings:
			indent_size = settings.get_setting('text_editor/behavior/indent/size')
	if indent_size <= 0:
		indent_size = 4

	var spaces_str: String = ' '.repeat(indent_size)
	var body_lines: PackedStringArray = body.split('\n')
	for k: int in range(body_lines.size()):
		var bl: String = body_lines[k]
		var prefix_len: int = 0
		for c_idx: int in range(bl.length()):
			if bl[c_idx] != ' ' and bl[c_idx] != '\t':
				break
			prefix_len += 1
		var prefix: String = bl.substr(0, prefix_len)
		var remainder: String = bl.substr(prefix_len)
		body_lines[k] = prefix.replace(spaces_str, '\t') + remainder
	body = '\n'.join(body_lines)

	# extract {{placeholder}} names from body
	var placeholders: Array = []
	var ph_regex: RegEx = RegEx.new()
	ph_regex.compile('\\{\\{([a-zA-Z0-9_]+)\\}\\}')
	for result: RegExMatch in ph_regex.search_all(body):
		var name: String = result.get_string(1)
		if name != 'VCNODE_ID' and not placeholders.has(name):
			placeholders.append(name)

	return {placeholders = placeholders, body = body}
static func get_default_value_code(_save_data: HenSaveData, _type: String, _use_self: bool, _category: String = '', _data: Variant = null, _default_value: Variant = null) -> String:
	if _default_value != null:
		var raw_val: String = var_to_str(_default_value)
		# escaping goes by the value, since a String also lands on a Variant slot:
		# var_to_str keeps a line break verbatim, which ends the literal early
		if _default_value is String or _default_value is StringName:
			raw_val = raw_val.replace('\n', '\\n').replace('\t', '\\t').replace('\r', '\\r')

		# quote style goes by the declared type, and an apostrophe in the text keeps
		# the double quotes var_to_str wrapped it in
		if _type == 'String' or _type == 'NodePath' or _type == 'StringName':
			if raw_val.begins_with('"') and raw_val.ends_with('"') and not raw_val.contains("'"):
				return "'" + raw_val.substr(1, raw_val.length() - 2) + "'"
		return raw_val

	if _category == 'enum_list' and typeof(_data) == TYPE_ARRAY and (_data as Array).size() >= 2:
		var enum_constants = ClassDB.class_get_enum_constants(_data[0], _data[1])
		if not enum_constants.is_empty():
			return '.'.join(_data as Array) + '.' + enum_constants[0]

	match _type:
		'String', 'NodePath', 'StringName':
			return "''"
		'int':
			return '0'
		'float':
			return '0.'
		'Vector2':
			return 'Vector2(0, 0)'
		'bool':
			return 'false'
		'Variant':
			return 'null'
		_:
			if HenEnums.VARIANT_TYPES.has(_type) and _type != 'Object':
				return _type + '()'
			elif _type != '':
				if not _use_self:
					return '_ref'

				if HenUtils.is_type_relation_valid(
					_save_data.identity.type,
					_type,
				):
					return 'self'
				
				if ClassDB.class_exists(_type) and not ClassDB.can_instantiate(_type):
					return 'null'
				
				return _type + '.new()'
	
	return 'null'
