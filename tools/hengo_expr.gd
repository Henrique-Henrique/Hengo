class_name HenHengoExpr extends RefCounted


#  just for tests purposes

# compiles a gdscript expression string into a real hengo node graph (literals,
# operators, var/prop gets, native/user calls) wired by data connections, and
# returns the value-producing output port: { ok, error, node, out_id }.
#
# ctx carries the symbol table: { save_data, route_type, extends_class,
#   vars: {name -> HenSaveVar}, funcs: {name -> HenSaveFunc}, scope: {name -> {node, out_id}} }

const COMPOSITE_LITERALS: Dictionary = {
	Vector2 = ['x', 'y'], Vector2i = ['x', 'y'],
	Vector3 = ['x', 'y', 'z'], Vector3i = ['x', 'y', 'z'],
	Vector4 = ['x', 'y', 'z', 'w'], Vector4i = ['x', 'y', 'z', 'w'],
	Color = ['r', 'g', 'b', 'a'],
}

const BINARY_OPS: Dictionary = {
	'||' = 1, 'or' = 1,
	'&&' = 2, 'and' = 2,
	'==' = 3, '!=' = 3, '<' = 3, '>' = 3, '<=' = 3, '>=' = 3, 'is' = 3, 'as' = 3,
	'|' = 4, '^' = 5, '&' = 6,
	'<<' = 7, '>>' = 7,
	'+' = 8, '-' = 8,
	'*' = 9, '/' = 9, '%' = 9,
}

# binary ops whose right operand is a TYPE name (kept as text, not a wired atom)
const TYPE_RHS_OPS: Array = ['is', 'as']

# normalizes gdscript keyword operators to the forms hengo's codegen emits
const OP_ALIAS: Dictionary = {'and' = '&&', 'or' = '||', 'not' = '!'}

static var _singletons: PackedStringArray = PackedStringArray()


static func compile(_ctx: Dictionary, _route: HenRouteData, _text: String, _pos: Vector2) -> Dictionary:
	var parsed: Dictionary = _parse(_text)
	if not parsed.ok:
		return parsed
	var lay: Dictionary = {base = _pos, n = 0}
	return _emit(_ctx, _route, parsed.ast, lay)


# compiles a json arg value: a plain string is a STRING LITERAL, a number/bool is
# a literal, and { "expr": "..." } is a compiled expression
static func compile_json_value(_ctx: Dictionary, _route: HenRouteData, _value: Variant, _pos: Vector2) -> Dictionary:
	if _value is Dictionary and (_value as Dictionary).has('expr'):
		return compile(_ctx, _route, str((_value as Dictionary).expr), _pos)

	var lit: Dictionary = {}
	match typeof(_value):
		TYPE_STRING, TYPE_STRING_NAME:
			lit = {kind = 'lit', value = String(_value), type = 'String'}
		TYPE_BOOL:
			lit = {kind = 'lit', value = _value, type = 'bool'}
		TYPE_INT:
			lit = {kind = 'lit', value = _value, type = 'int'}
		TYPE_FLOAT:
			if is_finite(_value) and _value == floor(_value):
				lit = {kind = 'lit', value = int(_value), type = 'int'}
			else:
				lit = {kind = 'lit', value = _value, type = 'float'}
		_:
			lit = {kind = 'lit', value = String(_value), type = 'String'}
	return _ok(_build_literal(_route, lit, _pos), '0')


# compiles a call used as a flow statement (or value): callee is "name" or
# "Singleton.method"/"obj.method"; json_args are arg values (see compile_json_value)
static func compile_call_node(_ctx: Dictionary, _route: HenRouteData, _callee: String, _json_args: Array, _pos: Vector2) -> Dictionary:
	var parsed: Dictionary = _parse(_callee)
	if not parsed.ok:
		return parsed
	var callee_ast: Dictionary = parsed.ast
	if not (callee_ast.kind in ['ident', 'member']):
		return {ok = false, error = 'invalid call target: ' + _callee}

	var args: Array = []
	for jv: Variant in _json_args:
		args.append(_json_to_ast(jv))

	var lay: Dictionary = {base = _pos, n = 0}
	return _emit_call(_ctx, _route, {kind = 'call', callee = callee_ast, args = args}, lay)


# builds an assignment statement node (SET_VAR or SET_PROP) with the rhs wired.
# desugars compound ops (a -= b -> a = a - (b)).
static func compile_assignment(_ctx: Dictionary, _route: HenRouteData, _target: String, _value: String, _op: String, _pos: Vector2) -> Dictionary:
	var value_expr: String = _value
	if not _op.is_empty() and _op != '=':
		value_expr = '(%s) %s (%s)' % [_target, _op.trim_suffix('='), _value]

	var tparsed: Dictionary = _parse(_target)
	if not tparsed.ok:
		return tparsed
	var tast: Dictionary = tparsed.ast

	var lay: Dictionary = {base = _pos, n = 0}

	# target is a declared script variable -> SET_VAR
	if tast.kind == 'ident' and (_ctx.vars as Dictionary).has(tast.name):
		var sv: HenSaveVar = _ctx.vars[tast.name]
		var cfg: Dictionary = sv.get_setter_cnode_data('')
		cfg.route = _route
		cfg.position = _pos
		var setn: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode(cfg)
		var val: Dictionary = compile(_ctx, _route, value_expr, _pos)
		if not val.ok:
			return val
		setn.get_new_input_connection_command(StringName('0'), StringName(val.out_id), val.node).add()
		return _ok(setn, '0')

	# otherwise an assignment to a property path -> SET_PROP
	var base: Dictionary = _resolve_set_target(_ctx, _route, tast, lay)
	if not base.get('ok', true):
		return base

	var node: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'Set -> ' + base.path, sub_type = HenVirtualCNode.SubType.SET_PROP,
		inputs = [ {id = 0, name = 'Node', type = 'Variant', is_ref = true}, {id = 1, name = base.path, type = 'Variant'}],
		route = _route, position = _pos,
	})
	_set_ref_base(_ctx, node, 0, base)

	var pval: Dictionary = compile(_ctx, _route, value_expr, _pos)
	if not pval.ok:
		return pval
	node.get_new_input_connection_command(StringName('1'), StringName(pval.out_id), pval.node).add()
	return _ok(node, '0')


# resolves the base value + property path for a SET_PROP target (ident or member)
static func _resolve_set_target(_ctx: Dictionary, _route: HenRouteData, _ast: Dictionary, _lay: Dictionary) -> Dictionary:
	if _ast.kind == 'ident':
		if (_ctx.scope as Dictionary).has(_ast.name) or (_ctx.vars as Dictionary).has(_ast.name):
			return {ok = false, error = 'cannot set non-property identifier as property: ' + _ast.name}
		return {node = null, out_id = '0', path = _ast.name}
	if _ast.kind == 'member':
		return _resolve_member_base(_ctx, _route, _ast, _lay)
	return {ok = false, error = 'invalid assignment target'}


static func _json_to_ast(_jv: Variant) -> Dictionary:
	if _jv is Dictionary and (_jv as Dictionary).has('expr'):
		var parsed: Dictionary = _parse(str((_jv as Dictionary).expr))
		return parsed.ast if parsed.ok else {kind = 'lit', value = null, type = 'Variant'}
	match typeof(_jv):
		TYPE_STRING, TYPE_STRING_NAME:
			return {kind = 'lit', text = '"%s"' % String(_jv), value = String(_jv), type = 'String'}
		TYPE_BOOL:
			return {kind = 'lit', text = 'true' if _jv else 'false', value = _jv, type = 'bool'}
		TYPE_INT:
			return {kind = 'lit', text = str(_jv), value = _jv, type = 'int'}
		TYPE_FLOAT:
			if is_finite(_jv) and _jv == floor(_jv):
				return {kind = 'lit', text = str(int(_jv)), value = int(_jv), type = 'int'}
			return {kind = 'lit', text = str(_jv), value = _jv, type = 'float'}
	return {kind = 'lit', value = null, type = 'Variant'}


static func _parse(_text: String) -> Dictionary:
	var tok: Dictionary = _tokenize(_text)
	if not tok.ok:
		return {ok = false, error = tok.error}
	var p: Dictionary = {toks = tok.toks, i = 0, error = ''}
	var ast: Dictionary = _parse_expr(p, 0)
	if not p.error.is_empty():
		return {ok = false, error = 'parse error in "%s": %s' % [_text, p.error]}
	if p.i < (p.toks as Array).size():
		return {ok = false, error = 'unexpected trailing token in "%s": %s' % [_text, str(p.toks[p.i])]}
	return {ok = true, ast = ast}


# ----------------------------------------------------------------------------
# tokenizer
# ----------------------------------------------------------------------------

static func _tokenize(_text: String) -> Dictionary:
	var toks: Array = []
	var n: int = _text.length()
	var i: int = 0

	while i < n:
		var c: String = _text[i]

		if c == ' ' or c == '\t' or c == '\n' or c == '\r':
			i += 1
			continue

		if c.is_valid_int() or (c == '.' and i + 1 < n and _text[i + 1].is_valid_int()):
			var start: int = i
			while i < n and (_text[i].is_valid_int() or _text[i] == '.' or _text[i] == 'e' or _text[i] == 'E' or ((_text[i] == '+' or _text[i] == '-') and i > start and (_text[i - 1] == 'e' or _text[i - 1] == 'E'))):
				i += 1
			var num: String = _text.substr(start, i - start)
			toks.append({type = 'num', text = num})
			continue

		if c == '"' or c == "'":
			var q: String = c
			i += 1
			var sb: String = ''
			while i < n and _text[i] != q:
				if _text[i] == '\\' and i + 1 < n:
					sb += _text[i] + _text[i + 1]
					i += 2
				else:
					sb += _text[i]
					i += 1
			if i >= n:
				return {ok = false, error = 'unterminated string in "%s"' % _text}
			i += 1
			toks.append({type = 'str', value = sb, text = q + sb + q})
			continue

		if c == '_' or c.to_lower() != c.to_upper() or c.unicode_at(0) > 127:
			var s2: int = i
			while i < n and (_text[i] == '_' or _text[i].to_lower() != _text[i].to_upper() or _text[i].is_valid_int()):
				i += 1
			toks.append({type = 'ident', text = _text.substr(s2, i - s2)})
			continue

		# operators / punctuation (multi-char first)
		var two: String = _text.substr(i, 2)
		if two in ['==', '!=', '<=', '>=', '&&', '||', '<<', '>>']:
			toks.append({type = 'op', text = two})
			i += 2
			continue

		if c in ['+', '-', '*', '/', '%', '<', '>', '!', '&', '|', '^', '~', '.', ',', '(', ')', '[', ']']:
			toks.append({type = 'op', text = c})
			i += 1
			continue

		return {ok = false, error = 'unexpected char "%s" in "%s"' % [c, _text]}

	return {ok = true, toks = toks}


# ----------------------------------------------------------------------------
# parser (precedence climbing)
# ----------------------------------------------------------------------------

static func _peek(_p: Dictionary) -> Dictionary:
	if _p.i < (_p.toks as Array).size():
		return _p.toks[_p.i]
	return {}


static func _next(_p: Dictionary) -> Dictionary:
	var t: Dictionary = _peek(_p)
	_p.i += 1
	return t


static func _parse_expr(_p: Dictionary, _min_prec: int) -> Dictionary:
	var left: Dictionary = _parse_unary(_p)
	if not _p.error.is_empty():
		return {}

	while true:
		var t: Dictionary = _peek(_p)
		var op: String = _binary_op(t)
		if op.is_empty():
			break
		var prec: int = BINARY_OPS[op]
		if prec < _min_prec:
			break
		_p.i += 1
		var right: Dictionary = _parse_expr(_p, prec + 1)
		if not _p.error.is_empty():
			return {}
		left = {kind = 'binary', op = _norm_op(op), prec = prec, left = left, right = right}

	return left


static func _binary_op(_t: Dictionary) -> String:
	if _t.is_empty():
		return ''
	if (_t.type == 'op' or _t.type == 'ident') and BINARY_OPS.has(_t.text):
		return _t.text
	return ''


static func _parse_unary(_p: Dictionary) -> Dictionary:
	var t: Dictionary = _peek(_p)
	if (t.get('type') == 'op' and t.text in ['-', '!', '~']) or (t.get('type') == 'ident' and t.text == 'not'):
		_p.i += 1
		var operand: Dictionary = _parse_unary(_p)
		if not _p.error.is_empty():
			return {}
		return {kind = 'unary', op = _norm_op(t.text), operand = operand}
	return _parse_postfix(_p)


static func _parse_postfix(_p: Dictionary) -> Dictionary:
	var node: Dictionary = _parse_primary(_p)
	if not _p.error.is_empty():
		return {}

	while true:
		var t: Dictionary = _peek(_p)
		if t.get('type') == 'op' and t.text == '.':
			_p.i += 1
			var name_tok: Dictionary = _next(_p)
			if name_tok.get('type') != 'ident':
				_p.error = 'expected name after "."'
				return {}
			node = {kind = 'member', obj = node, name = name_tok.text}
		elif t.get('type') == 'op' and t.text == '(':
			_p.i += 1
			var args: Array = _parse_args(_p)
			if not _p.error.is_empty():
				return {}
			node = {kind = 'call', callee = node, args = args}
		elif t.get('type') == 'op' and t.text == '[':
			_p.i += 1
			var idx: Dictionary = _parse_expr(_p, 0)
			if not _p.error.is_empty():
				return {}
			var close: Dictionary = _next(_p)
			if close.get('text') != ']':
				_p.error = 'expected "]"'
				return {}
			node = {kind = 'index', obj = node, index = idx}
		else:
			break

	return node


static func _parse_args(_p: Dictionary) -> Array:
	var args: Array = []
	if _peek(_p).get('text') == ')':
		_p.i += 1
		return args
	while true:
		var arg: Dictionary = _parse_expr(_p, 0)
		if not _p.error.is_empty():
			return []
		args.append(arg)
		var t: Dictionary = _next(_p)
		if t.get('text') == ')':
			break
		if t.get('text') != ',':
			_p.error = 'expected "," or ")" in arguments'
			return []
	return args


static func _parse_primary(_p: Dictionary) -> Dictionary:
	var t: Dictionary = _next(_p)
	if t.is_empty():
		_p.error = 'unexpected end of expression'
		return {}

	match t.type:
		'num':
			var is_float: bool = '.' in t.text or 'e' in t.text or 'E' in t.text
			return {kind = 'lit', text = t.text, value = (t.text.to_float() if is_float else t.text.to_int()), type = ('float' if is_float else 'int')}
		'str':
			return {kind = 'lit', text = t.text, value = t.value, type = 'String'}
		'ident':
			match t.text:
				'true':
					return {kind = 'lit', text = 'true', value = true, type = 'bool'}
				'false':
					return {kind = 'lit', text = 'false', value = false, type = 'bool'}
				'null':
					return {kind = 'lit', text = 'null', value = null, type = 'Variant'}
				_:
					return {kind = 'ident', name = t.text}
		'op':
			if t.text == '(':
				var inner: Dictionary = _parse_expr(_p, 0)
				if not _p.error.is_empty():
					return {}
				var close: Dictionary = _next(_p)
				if close.get('text') != ')':
					_p.error = 'expected ")"'
					return {}
				inner['grouped'] = true
				return inner
			if t.text == '[':
				var elems: Array = []
				if _peek(_p).get('text') == ']':
					_p.i += 1
					return {kind = 'array', elements = elems}
				while true:
					var el: Dictionary = _parse_expr(_p, 0)
					if not _p.error.is_empty():
						return {}
					elems.append(el)
					var sep: Dictionary = _next(_p)
					if sep.get('text') == ']':
						break
					if sep.get('text') != ',':
						_p.error = 'expected "," or "]" in array'
						return {}
				return {kind = 'array', elements = elems}

	_p.error = 'unexpected token: ' + str(t)
	return {}


static func _norm_op(_op: String) -> String:
	return OP_ALIAS.get(_op, _op)


# ----------------------------------------------------------------------------
# emitter
# ----------------------------------------------------------------------------

static func _emit(_ctx: Dictionary, _route: HenRouteData, _ast: Dictionary, _lay: Dictionary) -> Dictionary:
	match _ast.kind:
		'lit':
			# null has no concrete type; a Variant LITERAL would render `Variant(null)`,
			# so emit it as a constant-text node
			if _ast.value == null:
				return _ok(_const_text_node(_route, 'null', _next_pos(_lay)), '0')
			return _ok(_build_literal(_route, _ast, _next_pos(_lay)), '0')
		'ident':
			return _emit_ident(_ctx, _route, _ast.name, _lay)
		'member':
			return _emit_member(_ctx, _route, _ast, _lay)
		'call':
			return _emit_call(_ctx, _route, _ast, _lay)
		'unary', 'binary', 'array':
			return _emit_operator(_ctx, _route, _ast, _lay)
		'index':
			return {ok = false, error = 'index expressions (a[i]) not supported yet'}
	return {ok = false, error = 'cannot compile node: ' + str(_ast)}


static func _emit_ident(_ctx: Dictionary, _route: HenRouteData, _name: String, _lay: Dictionary) -> Dictionary:
	if (_ctx.scope as Dictionary).has(_name):
		var s: Dictionary = _ctx.scope[_name]
		return {ok = true, node = s.node, out_id = s.out_id}

	if (_ctx.vars as Dictionary).has(_name):
		var sv: HenSaveVar = _ctx.vars[_name]
		var cfg: Dictionary = sv.get_getter_cnode_data('')
		cfg.route = _route
		cfg.position = _next_pos(_lay)
		return _ok(HenVirtualCNode.instantiate_virtual_cnode(cfg), '0')

	# unknown identifier -> treat as a property of self (self-ref typed so codegen
	# emits `self.`/`_ref.`, not `null.`)
	var prop: HenVirtualCNode = _build_get_prop(_route, _name, &'Variant', _next_pos(_lay))
	_set_ref_base(_ctx, prop, 0, {node = null})
	return _ok(prop, '0')


static func _emit_member(_ctx: Dictionary, _route: HenRouteData, _ast: Dictionary, _lay: Dictionary) -> Dictionary:
	# singleton constant/enum access (e.g. Input.MOUSE_MODE_CAPTURED) -> CONST node
	var flat: Dictionary = _flatten_member(_ast)
	if flat.root.kind == 'ident' and _is_singleton(flat.root.name):
		var const_node: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
			name = flat.root.name, name_to_code = '.'.join(flat.names),
			sub_type = HenVirtualCNode.SubType.CONST, type = 0,
			outputs = [ {id = 0, name = '.'.join(flat.names), type = 'Variant'}],
			route = _route, position = _next_pos(_lay),
		})
		return _ok(const_node, '0')

	# resolve the longest leading value base; the rest is a property path
	var base: Variant = _resolve_member_base(_ctx, _route, _ast, _lay)
	if base is Dictionary and not base.get('ok', true):
		return base

	var prop: HenVirtualCNode = _build_get_prop(_route, base.path, &'Variant', _next_pos(_lay))
	_set_ref_base(_ctx, prop, 0, base)
	return _ok(prop, '0')


# wires the self-ref input of a prop node to a value base, or leaves it as self.
# the ref type is the script's class when self (so codegen emits `self.`) or
# Variant when connected (so any base type is accepted by the connection check).
static func _set_ref_base(_ctx: Dictionary, _node: HenVirtualCNode, _ref_idx: int, _base: Dictionary) -> void:
	var ref_in: HenVCInOutData = _node.get_input_by_idx(_ref_idx)
	if not ref_in:
		return
	if _base.get('node'):
		ref_in.type = 'Variant'
		_node.get_new_input_connection_command(StringName(ref_in.id), StringName(_base.out_id), _base.node).add()
	else:
		ref_in.type = _ctx.save_data.identity.type


# returns a dotted type name from an ident/member ast, or '' if not a type
static func _type_text(_ast: Dictionary) -> String:
	if _ast.kind == 'ident':
		return _ast.name
	if _ast.kind == 'member':
		var flat: Dictionary = _flatten_member(_ast)
		if flat.root.kind == 'ident':
			return flat.root.name + '.' + '.'.join(flat.names)
	return ''


# flattens a member chain into { root, names } where names is [n1, n2, ...]
static func _flatten_member(_ast: Dictionary) -> Dictionary:
	var names: Array = []
	var cur: Dictionary = _ast
	while cur.kind == 'member':
		names.push_front(cur.name)
		cur = cur.obj
	return {root = cur, names = names}


# returns { node, out_id, path } where node is the value base (null = self) and
# path is the remaining property chain. errors propagate as { ok=false, error }
static func _resolve_member_base(_ctx: Dictionary, _route: HenRouteData, _ast: Dictionary, _lay: Dictionary) -> Dictionary:
	# flatten the member chain into [root, name1, name2, ...]
	var names: Array = []
	var cur: Dictionary = _ast
	while cur.kind == 'member':
		names.push_front(cur.name)
		cur = cur.obj

	# root must be an identifier (a value: var/param) or a self-property
	if cur.kind != 'ident':
		# base is an arbitrary expression (e.g. a call) -> compile it, rest is path
		var compiled: Dictionary = _emit(_ctx, _route, cur, _lay)
		if not compiled.ok:
			return compiled
		return {node = compiled.node, out_id = compiled.out_id, path = '.'.join(names)}

	var root: String = cur.name
	if (_ctx.scope as Dictionary).has(root):
		var s: Dictionary = _ctx.scope[root]
		return {node = s.node, out_id = s.out_id, path = '.'.join(names)}
	if (_ctx.vars as Dictionary).has(root):
		var sv: HenSaveVar = _ctx.vars[root]
		var cfg: Dictionary = sv.get_getter_cnode_data('')
		cfg.route = _route
		cfg.position = _next_pos(_lay)
		return {node = HenVirtualCNode.instantiate_virtual_cnode(cfg), out_id = '0', path = '.'.join(names)}

	# root is a self property -> whole chain is the path, base = self (unconnected)
	return {node = null, out_id = '0', path = root + '.' + '.'.join(names)}


static func _emit_operator(_ctx: Dictionary, _route: HenRouteData, _ast: Dictionary, _lay: Dictionary) -> Dictionary:
	if _ast.kind == 'binary' and _ast.op in TYPE_RHS_OPS:
		return _emit_expression_combinator(_ctx, _route, _ast, _lay)
	if (_ast.kind == 'unary' or _ast.kind == 'binary') and _is_simple_operator(_ast):
		return _emit_operator_node(_ctx, _route, _ast, _lay)
	return _emit_expression_combinator(_ctx, _route, _ast, _lay)


static func _is_simple_operator(_ast: Dictionary) -> bool:
	if _ast.kind == 'unary':
		return not (_ast.operand.kind in ['unary', 'binary'])
	return not (_ast.left.kind in ['unary', 'binary']) and not (_ast.right.kind in ['unary', 'binary'])


static func _emit_operator_node(_ctx: Dictionary, _route: HenRouteData, _ast: Dictionary, _lay: Dictionary) -> Dictionary:
	var pos: Vector2 = _next_pos(_lay)
	if _ast.kind == 'unary':
		var u: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
			name = _ast.op, name_to_code = _ast.op, sub_type = HenVirtualCNode.SubType.OPERATOR,
			input_code_value_map = {operator_type = 'unary'},
			inputs = [ {id = '0', name = 'a', type = 'Variant'}],
			outputs = [ {id = '0', name = 'result', type = 'Variant'}],
			route = _route, position = pos,
		})
		var op: Dictionary = _emit(_ctx, _route, _ast.operand, _lay)
		if not op.ok:
			return op
		u.get_new_input_connection_command(StringName('0'), StringName(op.out_id), op.node).add()
		return _ok(u, '0')

	var b: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = _ast.op, name_to_code = _ast.op, sub_type = HenVirtualCNode.SubType.OPERATOR,
		input_code_value_map = {operator_type = 'binary'},
		inputs = [ {id = '0', name = 'a', type = 'Variant'}, {id = '1', name = 'b', type = 'Variant'}],
		outputs = [ {id = '0', name = 'result', type = 'Variant'}],
		route = _route, position = pos,
	})
	var l: Dictionary = _emit(_ctx, _route, _ast.left, _lay)
	if not l.ok:
		return l
	var r: Dictionary = _emit(_ctx, _route, _ast.right, _lay)
	if not r.ok:
		return r
	b.get_new_input_connection_command(StringName('0'), StringName(l.out_id), l.node).add()
	b.get_new_input_connection_command(StringName('1'), StringName(r.out_id), r.node).add()
	return _ok(b, '0')


# builds an EXPRESSION node: operators/parens/literals stay as text, atoms
# (vars/props/calls) become wired named-word inputs -> precedence stays correct
static func _emit_expression_combinator(_ctx: Dictionary, _route: HenRouteData, _ast: Dictionary, _lay: Dictionary) -> Dictionary:
	var atoms: Array = []
	var text: String = _serialize(_ctx, _route, _ast, atoms, _lay, 0)
	if text.begins_with(' '):
		return {ok = false, error = text.substr(1)}

	var inputs: Array = [ {id = 0, name = '', type = 'Variant', sub_type = 'expression', category = 'default_value', is_static = true}]
	for j in atoms.size():
		inputs.append({id = j + 1, name = 'w' + str(j), type = 'Variant'})

	var node: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		type = HenVirtualCNode.Type.EXPRESSION,
		sub_type = HenVirtualCNode.SubType.EXPRESSION,
		name = 'Expression',
		input_code_value_map = {0: {type = 'Variant', value = text, code_value = 'null'}},
		inputs = inputs,
		outputs = [ {id = 0, name = 'result', type = 'Variant'}],
		category = 'native',
		route = _route, position = _next_pos(_lay),
	})

	for j in atoms.size():
		var a: Dictionary = atoms[j]
		node.get_new_input_connection_command(StringName(str(j + 1)), StringName(a.out_id), a.node).add()

	return _ok(node, '0')


# serializes the operator tree to text, compiling atoms into wired words.
# returns " <error>" on failure (sentinel since gdscript lacks exceptions)
static func _serialize(_ctx: Dictionary, _route: HenRouteData, _ast: Dictionary, _atoms: Array, _lay: Dictionary, _parent_prec: int) -> String:
	match _ast.kind:
		'lit':
			return _ast.text
		'array':
			var parts: Array = []
			for el: Dictionary in _ast.elements:
				var et: String = _serialize(_ctx, _route, el, _atoms, _lay, 0)
				if et.begins_with(' '):
					return et
				parts.append(et)
			return '[' + ', '.join(parts) + ']'
		'unary':
			var inner: String = _serialize(_ctx, _route, _ast.operand, _atoms, _lay, 10)
			if inner.begins_with(' '):
				return inner
			return _ast.op + inner
		'binary':
			var l: String = _child_text(_ctx, _route, _ast.left, _atoms, _lay, _ast.prec, false)
			if l.begins_with(' '):
				return l
			# `is`/`as` keep the right operand as a bare type name (not a wired atom)
			if _ast.op in TYPE_RHS_OPS:
				var ty: String = _type_text(_ast.right)
				if ty.is_empty():
					return ' invalid type on right of "%s"' % _ast.op
				return l + ' ' + _ast.op + ' ' + ty
			var r: String = _child_text(_ctx, _route, _ast.right, _atoms, _lay, _ast.prec, true)
			if r.begins_with(' '):
				return r
			return l + ' ' + _ast.op + ' ' + r
		_:
			# atom: compile it as a node and wire it as a fresh word
			var res: Dictionary = _emit(_ctx, _route, _ast, _lay)
			if not res.ok:
				return ' ' + res.error
			var word: String = 'w' + str(_atoms.size())
			_atoms.append({node = res.node, out_id = res.out_id})
			return word


static func _child_text(_ctx: Dictionary, _route: HenRouteData, _child: Dictionary, _atoms: Array, _lay: Dictionary, _parent_prec: int, _is_right: bool) -> String:
	var t: String = _serialize(_ctx, _route, _child, _atoms, _lay, _parent_prec)
	if t.begins_with(' '):
		return t
	if _child.kind == 'binary':
		var cp: int = _child.prec
		if cp < _parent_prec or (cp == _parent_prec and _is_right):
			return '(' + t + ')'
	return t


static func _emit_call(_ctx: Dictionary, _route: HenRouteData, _ast: Dictionary, _lay: Dictionary) -> Dictionary:
	var callee: Dictionary = _ast.callee
	var pos: Vector2 = _next_pos(_lay)

	if callee.kind == 'ident':
		var name: String = callee.name

		if COMPOSITE_LITERALS.has(name):
			return _emit_constructor(_ctx, _route, name, _ast.args, pos, _lay)

		if (_ctx.funcs as Dictionary).has(name):
			return _emit_user_func(_ctx, _route, _ctx.funcs[name], _ast.args, pos, _lay)

		var cfg: Dictionary = _resolve_native(_ctx.save_data, name)
		if cfg.is_empty():
			return {ok = false, error = 'unknown function/identifier: ' + name}
		return _emit_native(_ctx, _route, cfg, _ast.args, pos, _lay, null)

	if callee.kind == 'member':
		var method: String = callee.name
		var obj: Dictionary = callee.obj
		var on_class: bool = obj.kind == 'ident' and not (_ctx.scope as Dictionary).has(obj.name) and not (_ctx.vars as Dictionary).has(obj.name) and (_is_singleton(obj.name) or ClassDB.class_exists(obj.name))
		if on_class:
			# singleton (Input.x) or class static (PhysicsRayQueryParameters3D.create) call
			var scfg: Dictionary = _resolve_native(_ctx.save_data, method, obj.name)
			if scfg.is_empty():
				scfg = _generic_method_cfg(method, _ast.args.size())
			scfg = _make_singleton(scfg, obj.name)
			return _emit_native(_ctx, _route, scfg, _ast.args, pos, _lay, null)

		# method on a value: compile the object, wire it to the self-ref input.
		# resolve the method on the base's type when known so the right overload
		# (e.g. Vector3.normalized, not Vector2.normalized) is used
		var base: Dictionary = _emit(_ctx, _route, obj, _lay)
		if not base.ok:
			return base
		# resolve ONLY as a method on the base's class (never as a global utility —
		# e.g. `scale.lerp(...)` must stay a method, not the utility `lerp`). unknown
		# base type or user method -> generic `<obj>.method(args)`
		var mcfg: Dictionary = _resolve_method(_ctx.save_data, method, _base_type_hint(_ctx, obj))
		if mcfg.is_empty():
			mcfg = _generic_method_cfg(method, _ast.args.size())
		return _emit_native(_ctx, _route, mcfg, _ast.args, pos, _lay, base)

	return {ok = false, error = 'unsupported call target'}


# resolves a method strictly on the given class (no utility/broad fallback)
static func _resolve_method(_save_data: HenSaveData, _name: String, _class: StringName) -> Dictionary:
	if _class.is_empty() or _class == &'Variant':
		return {}
	var data: Dictionary = (Engine.get_singleton(&'API') as HenApi).api_data
	for bucket_name: StringName in [&'classes', &'native_classes']:
		var hit: Dictionary = _method_from_class(data.get(bucket_name, {}), _class, _name)
		if not hit.is_empty():
			return hit
	return {}


# the declared type of a value base, used to resolve the right method overload
static func _base_type_hint(_ctx: Dictionary, _obj: Dictionary) -> StringName:
	if _obj.kind == 'ident' and (_ctx.vars as Dictionary).has(_obj.name):
		return (_ctx.vars[_obj.name] as HenSaveVar).type
	return &''


# config for an unresolved method call: a self-ref input + one input per arg
static func _generic_method_cfg(_method: String, _arg_count: int) -> Dictionary:
	var inputs: Array = [ {name = '', type = 'Variant', is_ref = true}]
	for i: int in _arg_count:
		inputs.append({name = 'arg' + str(i), type = 'Variant'})
	return {
		name = _method,
		sub_type = HenVirtualCNode.SubType.FUNC,
		inputs = inputs,
		outputs = [ {name = '', type = 'Variant'}],
	}


static func _emit_constructor(_ctx: Dictionary, _route: HenRouteData, _type: String, _args: Array, _pos: Vector2, _lay: Dictionary) -> Dictionary:
	var names: Array = COMPOSITE_LITERALS[_type]
	var inputs: Array = []
	for k in names.size():
		inputs.append({id = k, name = names[k], type = 'float'})

	var node: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = _type, sub_type = HenVirtualCNode.SubType.LITERAL,
		inputs = inputs, outputs = [ {id = 0, name = 'value', type = _type}],
		route = _route, position = _pos,
	})

	for k in _args.size():
		if k >= names.size():
			break
		var av: Dictionary = _emit(_ctx, _route, _args[k], _lay)
		if not av.ok:
			return av
		node.get_new_input_connection_command(StringName(str(k)), StringName(av.out_id), av.node).add()

	return _ok(node, '0')


static func _emit_user_func(_ctx: Dictionary, _route: HenRouteData, _func: HenSaveFunc, _args: Array, _pos: Vector2, _lay: Dictionary) -> Dictionary:
	var cfg: Dictionary = _func.get_cnode_data('')
	cfg.route = _route
	cfg.position = _pos
	var node: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode(cfg)

	for k in _args.size():
		if k >= _func.inputs.size():
			break
		var av: Dictionary = _emit(_ctx, _route, _args[k], _lay)
		if not av.ok:
			return av
		node.get_new_input_connection_command(StringName(str(_func.inputs[k].id)), StringName(av.out_id), av.node).add()

	var out_id: String = '0'
	if not _func.outputs.is_empty():
		out_id = str(_func.outputs[0].id)
	return _ok(node, out_id)


# builds a resolved native node, wiring args (and an optional value base into the
# leading self-ref input)
static func _emit_native(_ctx: Dictionary, _route: HenRouteData, _cfg: Dictionary, _args: Array, _pos: Vector2, _lay: Dictionary, _base: Variant) -> Dictionary:
	# 'native' forces use_self (empty prefix); only valid when there is no value
	# base. with a base, the base node carries its own prefix (e.g. `_ref.camera`)
	if _base == null:
		_cfg.category = 'native'
	_cfg.route = _route
	_cfg.position = _pos

	# drop trailing optional params the caller did not supply, so they are not
	# emitted as (often mis-defaulted) extra arguments
	var cfg_inputs: Array = _cfg.get('inputs', [])
	var has_ref: bool = not cfg_inputs.is_empty() and (cfg_inputs[0] as Dictionary).get('is_ref', false)
	var keep: int = (1 if has_ref else 0) + _args.size()
	if keep < cfg_inputs.size():
		_cfg.inputs = cfg_inputs.slice(0, keep)

	var node: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode(_cfg)

	var inputs: Array = node.get_inputs(_ctx.save_data)
	var start: int = 0
	if not inputs.is_empty() and inputs[0].is_ref:
		start = 1
		if _base != null:
			# relax the ref type so any base value connects (e.g. a Node into a typed self-ref)
			inputs[0].type = 'Variant'
			node.get_new_input_connection_command(StringName(inputs[0].id), StringName(_base.out_id), _base.node).add()
		else:
			# self-method (no base): type the self-ref as the script's class so codegen
			# emits `self.`/`_ref.` (broad resolution may pick the wrong owning class)
			inputs[0].type = _ctx.save_data.identity.type

	for k in _args.size():
		var idx: int = start + k
		if idx >= inputs.size():
			break
		var av: Dictionary = _emit(_ctx, _route, _args[k], _lay)
		if not av.ok:
			return av
		# relax the param type so the arg always connects (e.g. String into a NodePath)
		inputs[idx].type = 'Variant'
		node.get_new_input_connection_command(StringName(inputs[idx].id), StringName(av.out_id), av.node).add()

	var out: HenVCInOutData = node.get_output_by_idx(0)
	return _ok(node, str(out.id) if out else '0')


# ----------------------------------------------------------------------------
# node builders / helpers
# ----------------------------------------------------------------------------

static func _build_literal(_route: HenRouteData, _ast: Dictionary, _pos: Vector2) -> HenVirtualCNode:
	return HenVirtualCNode.instantiate_virtual_cnode({
		name = _ast.type, sub_type = HenVirtualCNode.SubType.LITERAL,
		inputs = [ {id = 0, name = '', type = _ast.type, value = _ast.value}],
		outputs = [ {id = 0, name = 'value', type = _ast.type}],
		route = _route, position = _pos,
	})


# a value node that renders a fixed text verbatim (e.g. the `null` keyword)
static func _const_text_node(_route: HenRouteData, _text: String, _pos: Vector2) -> HenVirtualCNode:
	return HenVirtualCNode.instantiate_virtual_cnode({
		type = HenVirtualCNode.Type.EXPRESSION,
		sub_type = HenVirtualCNode.SubType.EXPRESSION,
		name = _text,
		input_code_value_map = {0: {type = 'Variant', value = _text, code_value = 'null'}},
		inputs = [ {id = 0, name = '', type = 'Variant', sub_type = 'expression', category = 'default_value', is_static = true}],
		outputs = [ {id = 0, name = 'result', type = 'Variant'}],
		category = 'native',
		route = _route, position = _pos,
	})


static func _build_get_prop(_route: HenRouteData, _path: String, _type: StringName, _pos: Vector2) -> HenVirtualCNode:
	return HenVirtualCNode.instantiate_virtual_cnode({
		name = 'Get -> ' + _path, sub_type = HenVirtualCNode.SubType.GET_PROP,
		inputs = [ {id = 0, name = 'Node', type = 'Variant', is_ref = true}],
		outputs = [ {id = 0, name = _path, type = _type}],
		route = _route, position = _pos,
	})


static func _resolve_native(_save_data: HenSaveData, _name: String, _class: StringName = &'') -> Dictionary:
	var api: HenApi = Engine.get_singleton(&'API')
	var data: Dictionary = api.api_data

	if not _class.is_empty():
		for bucket_name: StringName in [&'classes', &'native_classes']:
			var hit: Dictionary = _method_from_class(data.get(bucket_name, {}), _class, _name)
			if not hit.is_empty():
				return hit

	if (data.get('utilities', {}) as Dictionary).has(_name):
		var md: Dictionary = (data.utilities[_name] as Dictionary).duplicate(true)
		md.name = _name
		md._class_name = &''
		md.is_utility = true
		return HenApiSerialize.get_func_void_hengo_data(md)

	var preferred: StringName = _save_data.identity.type
	for bucket_name: StringName in [&'classes', &'native_classes']:
		var bucket: Dictionary = data.get(bucket_name, {})
		if bucket.has(preferred):
			var hit: Dictionary = _method_from_class(bucket, preferred, _name)
			if not hit.is_empty():
				return hit
	for bucket_name: StringName in [&'classes', &'native_classes']:
		for cls: StringName in data.get(bucket_name, {}):
			var hit: Dictionary = _method_from_class(data[bucket_name], cls, _name)
			if not hit.is_empty():
				return hit
	return {}


static func _method_from_class(_bucket: Dictionary, _cls: StringName, _name: String) -> Dictionary:
	if not _bucket.has(_cls):
		return {}
	var cd: Dictionary = _bucket[_cls]
	if cd.has(&'methods') and (cd.methods as Dictionary).has(_name):
		var md: Dictionary = (cd.methods[_name] as Dictionary).duplicate(true)
		md.name = _name
		md._class_name = _cls
		return HenApiSerialize.get_func_void_hengo_data(md)
	return {}


# turns a resolved method config into a singleton call: prefix with the singleton
# class and drop the instance self-ref input
static func _make_singleton(_cfg: Dictionary, _class: String) -> Dictionary:
	_cfg.singleton_class = _class
	var ins: Array = _cfg.get('inputs', [])
	if not ins.is_empty() and (ins[0] as Dictionary).get('is_ref', false):
		ins.remove_at(0)
	return _cfg


static func _is_singleton(_name: String) -> bool:
	if _singletons.is_empty():
		_singletons = Engine.get_singleton_list()
	return _name in _singletons


static func _next_pos(_lay: Dictionary) -> Vector2:
	var p: Vector2 = (_lay.base as Vector2) + Vector2(-220.0, 70.0 * _lay.n)
	_lay.n += 1
	return p


static func _ok(_node: HenVirtualCNode, _out_id: String) -> Dictionary:
	if not _node:
		return {ok = false, error = 'failed to build node'}
	return {ok = true, node = _node, out_id = _out_id}
