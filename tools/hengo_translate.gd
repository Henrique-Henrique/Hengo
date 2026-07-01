class_name HenHengoTranslate extends RefCounted

# just for tests purposes

# translates a high-level json description into a hengo graph using the builder
# api. all values (conditions, set values, args, return, loop bounds) are compiled
# into real node sub-graphs by HenHengoExpr and wired by data connections — never
# dumped as raw text. returns '' on success or an error message.

const HenHengoExpr = preload('res://tools/hengo_expr.gd')

const LIFECYCLE: Dictionary = {
	ready = {method = '_ready', outputs = []},
	process = {method = '_process', outputs = [ {name = 'delta', type = 'float'}]},
	physics_process = {method = '_physics_process', outputs = [ {name = 'delta', type = 'float'}]},
	enter_tree = {method = '_enter_tree', outputs = []},
	exit_tree = {method = '_exit_tree', outputs = []},
	input = {method = '_input', outputs = [ {name = 'event', type = 'InputEvent'}]},
	unhandled_input = {method = '_unhandled_input', outputs = [ {name = 'event', type = 'InputEvent'}]},
}

const COL_WIDTH: float = 360.0
const ROW_HEIGHT: float = 420.0
const SUB_ROW: float = 220.0


static func build(_save_data: HenSaveData, _json: Dictionary, _all_scripts: Dictionary = {}) -> String:
	var ctx: Dictionary = {save_data = _save_data, vars = {}, funcs = {}, states = {}, scope = {}, all_scripts = _all_scripts}

	# 1. declare script variables
	for v: Dictionary in _json.get('vars', []):
		var sv: HenSaveVar = _save_data.add_var(false)
		sv.name = _snake(v.name)
		sv.type = v.get('type', 'Variant')
		if v.has('value'):
			sv.default_value = _coerce_default(v.value, sv.type)
		ctx.vars[sv.name] = sv

	# 2. declare signals
	for s: Dictionary in _json.get('signals', []):
		var ss: HenSaveSignal = _save_data.add_signal(false)
		ss.name = _snake(s.name)
		for p: Dictionary in s.get('params', []):
			ss.inputs.append(HenSaveParam.create({name = _snake(p.name), type = p.get('type', 'Variant')}))

	# 3. declare functions
	var func_bodies: Array = []
	for f: Dictionary in _json.get('funcs', []):
		var sf: HenSaveFunc = _save_data.add_func(false)
		sf.name = _snake(f.name)
		for p: Dictionary in f.get('params', []):
			sf.inputs.append(HenSaveParam.create({name = _snake(p.name), type = p.get('type', 'Variant')}))
		for r: Dictionary in f.get('returns', []):
			sf.outputs.append(HenSaveParam.create({name = _snake(r.get('name', 'result')), type = r.get('type', 'Variant')}))
		ctx.funcs[sf.name] = sf
		func_bodies.append([sf, f])

	# 4. declare states (+ sub-states); register all by name for transition_to
	var state_bodies: Array = []
	for st: Dictionary in _json.get('states', []):
		var hs: HenSaveState = _save_data.add_state(false)
		hs.name = st.name
		if st.get('start', false):
			hs.start = true
		if st.has('description'):
			hs.description = st.description
		ctx.states[hs.name] = hs
		state_bodies.append([hs, st])

		for sub: Dictionary in st.get('sub_states', []):
			hs.add_sub_state(_save_data)
			var siblings: Array = hs.get_sub_states(_save_data)
			var shs: HenSaveState = siblings[siblings.size() - 1]
			shs.name = sub.name
			if sub.get('start', false):
				shs.start = true
			ctx.states[shs.name] = shs
			state_bodies.append([shs, sub])

	# 5. lifecycle flows
	var row: int = 0
	for key: String in LIFECYCLE:
		if not _json.has(key):
			continue
		var route: HenRouteData = _save_data.get_base_route()
		var origin: Vector2 = Vector2(0, row * ROW_HEIGHT)
		var entry: HenVirtualCNode = _virtual_entry(_save_data, route, LIFECYCLE[key], origin)
		var lctx: Dictionary = _scoped(ctx, entry, LIFECYCLE[key].outputs)
		var err: String = _build_flow(lctx, route, entry, StringName('0'), _json.get(key, []), origin + Vector2(COL_WIDTH, 0))
		if not err.is_empty():
			return err
		row += 1

	# 6. function bodies
	for pair: Array in func_bodies:
		var err: String = _build_function_body(ctx, pair[0], pair[1])
		if not err.is_empty():
			return err

	# 7. state bodies
	for pair: Array in state_bodies:
		var err: String = _build_state_body(ctx, pair[0], pair[1])
		if not err.is_empty():
			return err

	return ''


static func _virtual_entry(_save_data: HenSaveData, _route: HenRouteData, _conf: Dictionary, _pos: Vector2) -> HenVirtualCNode:
	return HenVirtualCNode.instantiate_virtual_cnode({
		name = _conf.method,
		sub_type = HenVirtualCNode.SubType.OVERRIDE_VIRTUAL,
		outputs = _conf.outputs,
		route = _route,
		position = _pos,
	})


# returns a ctx whose scope exposes a node's named outputs (delta/event/params) as
# value providers for expression compilation
static func _scoped(_ctx: Dictionary, _node: HenVirtualCNode, _output_specs: Array) -> Dictionary:
	var c: Dictionary = _ctx.duplicate()
	c.scope = (_ctx.scope as Dictionary).duplicate()
	for i: int in _output_specs.size():
		var spec: Dictionary = _output_specs[i]
		var out: HenVCInOutData = _node.get_output_by_idx(i)
		if out:
			c.scope[String(spec.name)] = {node = _node, out_id = str(out.id)}
	return c


static func _build_flow(_ctx: Dictionary, _route: HenRouteData, _prev_node: HenVirtualCNode, _prev_flow: StringName, _steps: Array, _origin: Vector2) -> String:
	var prev_node: HenVirtualCNode = _prev_node
	var prev_flow: StringName = _prev_flow
	var col: int = 0

	for step: Dictionary in _steps:
		var st: Dictionary = _build_statement(_ctx, _route, step, _origin + Vector2(col * COL_WIDTH, 0))
		if not st.ok:
			return st.error
		prev_node.add_flow_connection(prev_flow, StringName('0'), st.entry).add()
		prev_node = st.exit_node
		prev_flow = st.exit_flow
		col += 1

	return ''


static func _build_statement(_ctx: Dictionary, _route: HenRouteData, _step: Dictionary, _pos: Vector2) -> Dictionary:
	if _step.has('call'):
		return _linear(HenHengoExpr.compile_call_node(_ctx, _route, str(_step.call), _step.get('args', []), _pos))

	if _step.has('call_func'):
		return _linear(HenHengoExpr.compile_call_node(_ctx, _route, _snake(_step.call_func), _step.get('args', []), _pos))

	if _step.has('emit'):
		var args: Array = [_snake(_step.emit)]
		args.append_array(_step.get('args', []))
		return _linear(HenHengoExpr.compile_call_node(_ctx, _route, 'emit_signal', args, _pos))

	if _step.has('set_var'):
		return _linear(HenHengoExpr.compile_assignment(_ctx, _route, _snake(_step.set_var), str(_step.get('value', 'null')), str(_step.get('op', '')), _pos))

	if _step.has('set'):
		return _linear(HenHengoExpr.compile_assignment(_ctx, _route, str(_step.set), str(_step.get('value', 'null')), str(_step.get('op', '')), _pos))

	if _step.has('if'):
		return _build_if(_ctx, _route, _step, _pos)

	if _step.has('for') or _step.has('for_range'):
		return _build_for(_ctx, _route, _step, _pos)

	if _step.has('transition_to'):
		return _build_transition(_ctx, _route, _step, _pos)

	if _step.has('transition_other'):
		return _build_transition_other(_ctx, _route, _step, _pos)

	return {ok = false, error = 'unsupported step: ' + str(_step)}


# wraps a compiled call/assignment result as a linear flow statement
static func _linear(_res: Dictionary) -> Dictionary:
	if not _res.ok:
		return {ok = false, error = _res.error}
	return {ok = true, entry = _res.node, exit_node = _res.node, exit_flow = StringName('0')}


static func _build_if(_ctx: Dictionary, _route: HenRouteData, _step: Dictionary, _pos: Vector2) -> Dictionary:
	var if_node: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'IF',
		type = HenVirtualCNode.Type.IF,
		sub_type = HenVirtualCNode.SubType.IF,
		inputs = [ {id = 0, name = 'condition', type = 'bool'}],
		route = _route,
		position = _pos,
	})

	var cond: Dictionary = HenHengoExpr.compile(_ctx, _route, str(_step.if ), _pos + Vector2(0, -SUB_ROW))
	if not cond.ok:
		return {ok = false, error = cond.error}
	if_node.get_new_input_connection_command(StringName('0'), StringName(cond.out_id), cond.node).add()

	if _step.has('then'):
		var err: String = _build_flow(_ctx, _route, if_node, StringName('0'), _step.then, _pos + Vector2(COL_WIDTH, SUB_ROW))
		if not err.is_empty():
			return {ok = false, error = err}

	if _step.has('else'):
		var err2: String = _build_flow(_ctx, _route, if_node, StringName('1'), _step.else , _pos + Vector2(COL_WIDTH, 2 * SUB_ROW))
		if not err2.is_empty():
			return {ok = false, error = err2}

	return {ok = true, entry = if_node, exit_node = if_node, exit_flow = StringName('2')}


static func _build_for(_ctx: Dictionary, _route: HenRouteData, _step: Dictionary, _pos: Vector2) -> Dictionary:
	var is_range: bool = _step.has('for_range')
	var alias: String = _snake(_step.get('as', 'item'))

	var node: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode({
		name = 'For -> Range' if is_range else 'For -> Array',
		type = HenVirtualCNode.Type.FOR,
		sub_type = HenVirtualCNode.SubType.FOR if is_range else HenVirtualCNode.SubType.FOR_ARR,
		inputs = (
			[ {id = 0, name = 'start', type = 'int'}, {id = 1, name = 'end', type = 'int'}, {id = 2, name = 'step', type = 'int'}]
			if is_range else
			[ {id = 0, name = 'array', type = 'Variant'}]
		),
		outputs = [ {id = 0, name = alias, type = 'Variant'}],
		route = _route,
		position = _pos,
	})

	if is_range:
		var rg: Dictionary = _step.for_range
		for spec: Array in [[0, rg.get('from', 0)], [1, rg.get('to', 0)], [2, rg.get('step', 1)]]:
			var cv: Dictionary = HenHengoExpr.compile_json_value(_ctx, _route, spec[1], _pos + Vector2(0, -SUB_ROW))
			if not cv.ok:
				return {ok = false, error = cv.error}
			node.get_new_input_connection_command(StringName(str(spec[0])), StringName(cv.out_id), cv.node).add()
	else:
		var arr: Dictionary = HenHengoExpr.compile(_ctx, _route, str(_step.for ), _pos + Vector2(0, -SUB_ROW))
		if not arr.ok:
			return {ok = false, error = arr.error}
		node.get_new_input_connection_command(StringName('0'), StringName(arr.out_id), arr.node).add()

	var bctx: Dictionary = _ctx.duplicate()
	bctx.scope = (_ctx.scope as Dictionary).duplicate()
	bctx.scope[alias] = {node = node, out_id = '0'}

	var err: String = _build_flow(bctx, _route, node, StringName('0'), _step.get('body', []), _pos + Vector2(COL_WIDTH, SUB_ROW))
	if not err.is_empty():
		return {ok = false, error = err}

	return {ok = true, entry = node, exit_node = node, exit_flow = StringName('1')}


static func _build_transition(_ctx: Dictionary, _route: HenRouteData, _step: Dictionary, _pos: Vector2) -> Dictionary:
	var target: String = _step.transition_to
	if not (_ctx.states as Dictionary).has(target):
		return {ok = false, error = 'transition_to references unknown state: ' + target}

	var hs: HenSaveState = _ctx.states[target]
	var config: Dictionary = hs.get_transition_cnode_data('')
	config.route = _route
	config.position = _pos
	var node: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode(config)
	return {ok = true, entry = node, exit_node = node, exit_flow = StringName('0')}


# cross-script state transition: drives ANOTHER script's state machine, given a var
# that holds an instance of that script's node. emits STATE_TRANSITION_FROM ->
# `<instance>._STATE_CONTROLLER.change_state("state")`
static func _build_transition_other(_ctx: Dictionary, _route: HenRouteData, _step: Dictionary, _pos: Vector2) -> Dictionary:
	var spec: Dictionary = _step.transition_other
	var other_name: String = _snake(spec.script)
	if not (_ctx.all_scripts as Dictionary).has(other_name):
		return {ok = false, error = 'transition_other: unknown script ' + other_name}

	var other_sd: HenSaveData = _ctx.all_scripts[other_name]
	var target: HenSaveState = null
	for s: HenSaveState in other_sd.states:
		if s.name == spec.state:
			target = s
			break
	if not target:
		return {ok = false, error = 'transition_other: state "%s" not found in %s' % [spec.state, other_name]}

	var config: Dictionary = target.get_transition_cnode_data(other_sd.identity.id, true)
	config.route = _route
	config.position = _pos
	var node: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode(config)

	# wire the instance (a var holding the other node) into the ref input (id 0)
	var inst: Dictionary = HenHengoExpr.compile(_ctx, _route, str(spec.instance), _pos + Vector2(0, -SUB_ROW))
	if not inst.ok:
		return {ok = false, error = inst.error}
	node.get_new_input_connection_command(StringName('0'), StringName(inst.out_id), inst.node).add()

	_ctx.save_data.add_dep(other_sd.identity.id)
	return {ok = true, entry = node, exit_node = node, exit_flow = StringName('0')}


static func _build_function_body(_ctx: Dictionary, _func: HenSaveFunc, _json: Dictionary) -> String:
	var route: HenRouteData = _func.get_route(_ctx.save_data)
	var func_input: HenVirtualCNode = _find_vc_by_subtype(route, HenVirtualCNode.SubType.FUNC_INPUT)
	var func_output: HenVirtualCNode = _find_vc_by_subtype(route, HenVirtualCNode.SubType.FUNC_OUTPUT)
	if not func_input or not func_output:
		return 'function ' + _func.name + ' is missing input/output nodes'

	var fctx: Dictionary = _ctx.duplicate()
	fctx.scope = {}
	for param: HenSaveParam in _func.inputs:
		fctx.scope[param.name] = {node = func_input, out_id = str(param.id)}

	var err: String = _build_flow(fctx, route, func_input, StringName('0'), _json.get('flow', []), Vector2(0, SUB_ROW))
	if not err.is_empty():
		return err

	if _json.has('return') and not _func.outputs.is_empty():
		var ret: Dictionary = HenHengoExpr.compile(fctx, route, str(_json.return ), Vector2(700, 0))
		if not ret.ok:
			return ret.error
		func_output.get_new_input_connection_command(StringName(str(_func.outputs[0].id)), StringName(ret.out_id), ret.node).add()

	return ''


static func _build_state_body(_ctx: Dictionary, _state: HenSaveState, _json: Dictionary) -> String:
	var route: HenRouteData = _state.get_route(_ctx.save_data)
	var enter_vc: HenVirtualCNode = _find_vc_by_name(route, 'enter')
	var update_vc: HenVirtualCNode = _find_vc_by_name(route, 'update')
	if not enter_vc or not update_vc:
		return 'state ' + _state.name + ' is missing enter/update nodes'

	var ectx: Dictionary = _scoped(_ctx, enter_vc, [])
	var err: String = _build_flow(ectx, route, enter_vc, StringName('0'), _json.get('enter', []), Vector2(0, SUB_ROW))
	if not err.is_empty():
		return err

	var uctx: Dictionary = _scoped(_ctx, update_vc, [ {name = 'delta', type = 'float'}])
	return _build_flow(uctx, route, update_vc, StringName('0'), _json.get('update', []), Vector2(0, SUB_ROW * 3))


static func _find_vc_by_subtype(_route: HenRouteData, _sub_type: HenVirtualCNode.SubType) -> HenVirtualCNode:
	for vc: HenVirtualCNode in _route.virtual_cnode_list:
		if vc.sub_type == _sub_type:
			return vc
	return null


static func _find_vc_by_name(_route: HenRouteData, _name: String) -> HenVirtualCNode:
	for vc: HenVirtualCNode in _route.virtual_cnode_list:
		if vc.name == _name:
			return vc
	return null


static func _snake(_name: Variant) -> String:
	return String(_name).to_snake_case()


static func _coerce_default(_value: Variant, _type: StringName) -> Variant:
	if _type == &'int' and _value is float:
		return int(_value)
	return _value
