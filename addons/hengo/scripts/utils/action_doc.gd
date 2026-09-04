@tool
class_name HenActionDoc

# builds the hover documentation of an action from its macro: the summary plus a
# per-field explanation, in two flavors — rich bbcode for the custom tooltip and
# plain text for the native one (the add-action popup renders above the custom
# tooltip, so only the native one is visible there)

const DIM_COLOR: String = '#7a8699'
const FIELD_COLOR: String = '#8fd0ff'
const OUTPUT_COLOR: String = '#7fd6a8'
const BRANCH_COLOR: String = '#b39dff'


static func bbcode(_macro: HenSaveMacro) -> String:
	if not _macro:
		return ''

	var out: PackedStringArray = ['[b]' + _macro.name + '[/b]']

	if not _macro.description.is_empty():
		out.append(_macro.description)

	_append_section(out, _header('FIELDS'), _field_lines(_macro.inputs, FIELD_COLOR, false))
	_append_section(out, _header('RETURNS'), _field_lines(_macro.outputs, OUTPUT_COLOR, false))
	_append_section(out, _header('BRANCHES'), _field_lines(_macro.flow_outputs, BRANCH_COLOR, false))

	return '\n'.join(out)


static func plain(_macro: HenSaveMacro) -> String:
	if not _macro:
		return ''

	var out: PackedStringArray = [_macro.name]

	if not _macro.description.is_empty():
		out.append(_macro.description)

	_append_section(out, 'Fields:', _field_lines(_macro.inputs, '', true))
	_append_section(out, 'Returns:', _field_lines(_macro.outputs, '', true))
	_append_section(out, 'Branches:', _field_lines(_macro.flow_outputs, '', true))

	return '\n'.join(out)


# a dim section header for the bbcode flavor
static func _header(_text: String) -> String:
	return '[color=' + DIM_COLOR + ']' + _text + '[/color]'


static func _append_section(_out: PackedStringArray, _header_text: String, _lines: PackedStringArray) -> void:
	if _lines.is_empty():
		return

	_out.append('')
	_out.append(_header_text)
	_out.append_array(_lines)


# one line per documented field; a field with neither a doc nor options is skipped
static func _field_lines(_params: Array, _color: String, _plain: bool) -> PackedStringArray:
	var lines: PackedStringArray = []

	for param: HenSaveParam in _params:
		var extra: String = _options_hint(param)
		if param.doc.is_empty() and extra.is_empty():
			continue

		if _plain:
			var doc: String = param.doc
			if not extra.is_empty():
				doc += (' ' if not doc.is_empty() else '') + extra
			lines.append('• ' + param.name + ' — ' + doc)
		else:
			var line: String = '[color=' + _color + ']' + param.name + '[/color]  ' + param.doc
			if not extra.is_empty():
				line += (' ' if not param.doc.is_empty() else '') + '[color=' + DIM_COLOR + ']' + extra + '[/color]'
			lines.append(line)

	return lines


# the fixed set an options input accepts, surfaced so beginners see the choices
static func _options_hint(_param: HenSaveParam) -> String:
	if _param.options.is_empty():
		return ''

	return '(' + ' / '.join(_param.options) + ')'
