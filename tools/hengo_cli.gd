extends SceneTree

# this cli is just for tests purposes; it is not a supported entry point for hengo usage

# headless entry point to generate a hengo script from a high-level json. the json
# describes variables, states and the actions each state runs — an action is
# referenced by its macro id, never redeclared.
# usage: godot --headless -s tools/hengo_cli.gd -- <script.json> [collection_name]
#        godot --headless -s tools/hengo_cli.gd -- --list-actions [--class=Node2D]


const HENGO_ROOT_SCENE: String = 'res://addons/hengo/scenes/hengo_root.tscn'
const USAGE: String = 'usage: godot --headless -s tools/hengo_cli.gd -- <script.json> [collection_name] | --list-actions [--class=Node2D]'
# codegen marks an action it could not emit with this prefix
const UNRESOLVED_MARKER: String = '# hengo: action '


func _initialize() -> void:
	var user_args: PackedStringArray = OS.get_cmdline_user_args()

	if user_args.is_empty():
		_fail(USAGE)
		return

	var root_scene: Node = await _bootstrap()
	if not root_scene:
		_fail('bootstrap failed (api not ready)')
		return

	if user_args[0] == '--list-actions':
		print(JSON.stringify(_list_actions(_arg_value(user_args, '--class', 'Node')), '\t'))
		root_scene.free()
		quit(0)
		return

	if user_args[0] == '--export-actions':
		var out_path: String = user_args[1] if user_args.size() > 1 else 'res://data/actions.json'
		var export_err: String = _export_actions(out_path)
		root_scene.free()

		if export_err.is_empty():
			quit(0)
		else:
			_fail(export_err)

		return

	if user_args[0] == '--lint-exprs':
		var found: int = _lint_exprs()
		root_scene.free()
		quit(0 if found == 0 else 3)
		return

	var json: Dictionary = _read_json(user_args[0])
	if json.is_empty():
		root_scene.free()
		_fail('could not read or parse json: ' + user_args[0])
		return

	var collection_name: String = user_args[1] if user_args.size() > 1 else 'AI'
	var result: Dictionary = _generate(json, collection_name)
	root_scene.free()

	if not result.ok:
		_fail(result.get('error', 'unknown error'))
		return

	_report(result)

	if result.roundtrip_ok and result.resolved_ok:
		quit(0)
	else:
		quit(2)


# instantiates the hengo scene, registers singletons, waits for the native api and
# loads the action pools (they need a SAVE_DATA to exist)
func _bootstrap() -> Node:
	var root_scene: Node = (load(HENGO_ROOT_SCENE) as PackedScene).instantiate()

	for singleton_name: StringName in HenEnums.SINGLETON_LIST:
		var node: Node = root_scene.get_node(NodePath('%'+ singleton_name))
		if not Engine.has_singleton(singleton_name):
			Engine.register_singleton(singleton_name, node)

	var global: HenGlobal = Engine.get_singleton(&'Global')
	global.IS_HEADLESS = true

	# the api node loads asynchronously; trigger and await it manually since the
	# scene is not added to the tree (no _ready fires)
	var api: HenApi = Engine.get_singleton(&'API')
	await api._generate_compressed_data()

	if api.api_data.is_empty():
		root_scene.free()
		return null

	# macro loading creates routes in the active save data, so it runs against a
	# scratch one instead of polluting a generated script
	global.SAVE_DATA = HenSaveData.new()
	HenScriptMacroLoader.load_native_actions()
	HenScriptMacroLoader.load_script_macros()

	return root_scene


# every action the pool offers, as the contract for writing the json
func _list_actions(_class: String) -> Array:
	var list: Array = []

	for macro: HenSaveMacro in HenHengoActions.pool():
		if not macro.serves_class(StringName(_class)):
			continue

		list.append({
			id = str(macro.id),
			name = macro.name,
			category = macro.category,
			icon = macro.icon,
			phases = HenSaveAction.supported_phases(macro).map(func(p: StringName) -> String: return str(p)),
			default_phase = str(HenSaveAction.default_phase(macro)),
			inputs = macro.inputs.map(_input_data),
			outputs = macro.outputs.map(func(p: HenSaveParam) -> Dictionary: return {id = str(p.id), name = p.name, type = str(p.type)}),
			has_body = macro.has_body,
			branches = macro.flow_outputs.map(func(f: HenSaveFlowParam) -> String: return str(f.id)),
			target_classes = macro.target_classes.map(func(c: StringName) -> String: return str(c)),
		})

	list.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.id < b.id)

	return list


func _input_data(_param: HenSaveParam) -> Dictionary:
	return {
		id = str(_param.id),
		name = _param.name,
		type = str(_param.type),
		default = _param.default_value,
		raw = _param.raw,
		lvalue = _param.lvalue,
		bind_only = _param.bind_only,
		optional = _param.optional,
		type_from = str(_param.type_from),
		options = _param.options,
	}


# writes the full actions catalog (categories + actions) as json for the docs site
func _export_actions(_out_path: String) -> String:
	var actions: Array = []
	var present: Dictionary = {}

	for macro: HenSaveMacro in HenHengoActions.pool():
		present[macro.category] = true
		actions.append({
			id = str(macro.id),
			name = macro.name,
			category = macro.category,
			color = macro.color,
			icon = macro.icon,
			description = macro.description,
			default_phase = str(HenSaveAction.default_phase(macro)),
			phases = HenSaveAction.supported_phases(macro).map(func(p: StringName) -> String: return str(p)),
			inputs = macro.inputs.map(_export_input),
			outputs = macro.outputs.map(func(p: HenSaveParam) -> Dictionary: return {id = str(p.id), name = p.name, type = str(p.type), doc = p.doc}),
			branches = macro.flow_outputs.map(func(f: HenSaveFlowParam) -> Dictionary: return {id = str(f.id), name = f.name, doc = f.doc}),
			has_body = macro.has_body,
			target_classes = macro.target_classes.map(func(c: StringName) -> String: return str(c)),
		})

	actions.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.id < b.id)

	# category metadata (label/icon/color/count), sorted by the plugin's own order
	var categories: Array = []

	for cid: String in HenActionCategories.sorted(present.keys()):
		var data: Dictionary = HenActionCategories.get_data(cid)
		var count: int = actions.filter(func(a: Dictionary) -> bool: return a.category == cid).size()
		categories.append({id = cid, name = data.name, icon = data.icon, color = data.color, count = count})

	var doc: Dictionary = {version = Engine.get_version_info().string, categories = categories, actions = actions}

	DirAccess.make_dir_recursive_absolute(_out_path.get_base_dir())
	var file: FileAccess = FileAccess.open(_out_path, FileAccess.WRITE)

	if not file:
		return 'could not write ' + _out_path

	file.store_string(JSON.stringify(doc, '\t'))
	file.close()
	print('exported ', actions.size(), ' actions to ', _out_path)

	return ''


# an expression that matches one of these is doing by hand what an action already
# does. order matters: the first match wins, so the specific ones come first
const EXPR_HINTS: Array[Dictionary] = [
	{pattern = 'Vector2\\(randf_range', hint = 'Random Vector2'},
	{pattern = 'Vector3\\(randf_range', hint = 'Random Vector3'},
	{pattern = 'Vector3\\(\\s*\\w+\\.x\\s*,\\s*0(\\.0)?\\s*,\\s*\\w+\\.z\\s*\\)', hint = 'Drop Height'},
	{pattern = 'Vector2\\(\\s*\\w+\\.x\\s*,\\s*\\w+\\.z\\s*\\)', hint = 'Vector3 To Vector2'},
	{pattern = 'Vector3\\(\\s*\\w+\\.x\\s*,\\s*[\\w.]+\\s*,\\s*\\w+\\.y\\s*\\)', hint = 'Vector2 To Vector3'},
	{pattern = '[+-]\\s*Vector2\\(', hint = 'Vector2 Math'},
	{pattern = '[+-]\\s*Vector3\\(', hint = 'Vector3 Math'},
	{pattern = '\\.reduce\\(', hint = 'Best In List'},
	{pattern = '\\.map\\(', hint = 'Collect Property'},
	{pattern = 'not\\s+\\w+\\s+in\\s+\\w+', hint = 'Subtract List'},
	{pattern = '\\.filter\\(', hint = 'Filter List, or Get Nodes Where'},
	{pattern = '\\brange\\(', hint = 'Number List'},
	{pattern = '\\bstr\\((int|roundi|snappedf)\\(', hint = 'To Text'},
	{pattern = '\\+\\s*str\\(|str\\(\\w+\\)\\s*\\+', hint = 'Fill Text'},
	{pattern = '\\bif\\b.+\\belse\\b', hint = 'Pick Value, fed by a Check'},
	{pattern = '\\s(and|or)\\s', hint = 'Combine Checks'},
	{pattern = '^\\s*[a-zA-Z_]\\w*\\s*(==|!=|>=|<=|>|<)\\s*[^=]+$', hint = 'Check'},
	{pattern = '^\\s*[a-zA-Z_]\\w*\\.global_position\\s*$', hint = 'Get Position'},
	{pattern = '^\\s*[a-zA-Z_]\\w*\\.[a-zA-Z_][\\w.]*\\s*$', hint = 'Get Property'},
	{pattern = '\\.get\\(', hint = 'Dictionary Get, which takes a default'},
	{pattern = '^\\s*\\[.+\\]\\s*\\[', hint = 'an Array variable plus Array Get'}
]


# reports every expression in the saved scripts that an action could replace
func _lint_exprs() -> int:
	var base: String = HenEnums.HENGO_COLLECTION_PATH

	if not DirAccess.dir_exists_absolute(base):
		print('no collection to lint at ', base)
		return 0

	var total: int = 0
	var flagged: int = 0

	for collection_dir: String in DirAccess.get_directories_at(base):
		var collection_path: String = base.path_join(collection_dir)

		for script_dir: String in DirAccess.get_directories_at(collection_path):
			var save_path: String = collection_path.path_join(script_dir).path_join(HenEnums.SAVE_FILE)

			if not FileAccess.file_exists(save_path):
				continue

			var save_data: HenSaveData = ResourceLoader.load(save_path, '', ResourceLoader.CACHE_MODE_IGNORE_DEEP)

			if not save_data:
				continue

			var report: Array = _lint_save(save_data)
			total += report.size()

			for line: Dictionary in report:
				if not str(line.hint).is_empty():
					flagged += 1

			if not report.is_empty():
				_print_lint(save_data, report)

	print('')
	print('%d expressions, %d with an action that covers them' % [total, flagged])
	print('a hint is a suggestion: an expression that IS the logic can stay one')

	return flagged


func _print_lint(_save_data: HenSaveData, _report: Array) -> void:
	var name: String = _save_data.identity.name if _save_data.identity else '(unnamed)'
	print('')
	print('--- ', name, ' ---')

	for line: Dictionary in _report:
		var where: String = '%s / %s / %s' % [line.state, line.action, line.input]

		if str(line.hint).is_empty():
			print('    ok    ', where, ': ', line.code)
		else:
			print('  ACTION  ', where, ': ', line.code)
			print('          -> ', line.hint)


# every expression of a save, each with the action that would replace it
func _lint_save(_save_data: HenSaveData) -> Array:
	var report: Array = []

	for state_id: Variant in _save_data.state_actions:
		var state: HenSaveState = HenGeneratorAction.find_state(_save_data, StringName(str(state_id)))
		var state_name: String = state.name if state else str(state_id)

		for action: HenSaveAction in _save_data.state_actions[state_id]:
			_lint_action(action, state_name, report)

	return report


func _lint_action(_action: HenSaveAction, _state: String, _report: Array) -> void:
	for key: Variant in _action.input_expressions:
		var expr: HenSaveActionExpression = _action.input_expressions[key]

		_report.append({
			state = _state,
			action = str(_action.macro_id),
			input = str(key),
			code = expr.code,
			hint = _hint_for(expr.code)
		})

	for child: HenSaveAction in _action.body_actions:
		_lint_action(child, _state, _report)

	for key: Variant in _action.input_actions:
		var inline: Variant = _action.input_actions[key]
		var child_action: Variant = inline.get('action') if inline is Dictionary else inline

		if child_action is HenSaveAction:
			_lint_action(child_action as HenSaveAction, _state, _report)


func _hint_for(_code: String) -> String:
	for entry: Dictionary in EXPR_HINTS:
		var reg: RegEx = RegEx.new()
		reg.compile(str(entry.pattern))

		if reg.search(_code):
			return str(entry.hint)

	return ''


func _export_input(_param: HenSaveParam) -> Dictionary:
	return {
		id = str(_param.id),
		name = _param.name,
		type = str(_param.type),
		default = _fmt_default(_param.default_value),
		doc = _param.doc,
		lvalue = _param.lvalue,
		optional = _param.optional,
		type_from = str(_param.type_from),
		options = _param.options,
	}


# a readable string for a default value, or null when there is none
func _fmt_default(_value: Variant) -> Variant:
	if _value == null:
		return null

	if _value is String or _value is StringName:
		return "'" + str(_value) + "'"

	if _value is bool:
		return 'true' if _value else 'false'

	if _value is float and is_equal_approx(_value, floorf(_value)):
		return '%.1f' % _value

	return str(_value)


# builds a collection of one or more scripts, persists savedata and compiles .gd.
# a json may hold a single script (top-level) or many via a `scripts` array.
func _generate(_json: Dictionary, _collection_name: String) -> Dictionary:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var router: HenRouter = Engine.get_singleton(&'Router')
	var map_deps: HenMapDependencies = Engine.get_singleton(&'MapDependencies')

	var specs: Array = _json.get('scripts', [])
	if specs.is_empty():
		specs = [_json]
	var col_name: String = _json.get('collection', _collection_name)

	# idempotent regen: drop any prior collection with the same name so repeated runs
	# don't pile up duplicates
	_purge_collections_named(col_name)

	var collection: HenSaveCollection = HenCollectionManager.create_collection(col_name)
	global.ACTIVE_COLLECTION = collection
	global.OPEN_SCRIPTS = []

	# pass 1: create resources so every script exists before any graph is built
	var built: Array = []
	var all_scripts: Dictionary = {}
	for spec: Dictionary in specs:
		var b: Dictionary = _create_script_resource(collection, spec)
		global.OPEN_SCRIPTS.append(b.save_data)
		built.append(b)
		all_scripts[String(b.identity.name).to_snake_case()] = b.save_data

	# pass 2a: declare vars and states of every script, so a cross-script branch
	# resolves whatever order the json lists them
	for b: Dictionary in built:
		global.SAVE_DATA = b.save_data
		var err: String = HenHengoActions.declare(b.save_data, b.spec)
		if not err.is_empty():
			return {ok = false, error = 'in script ' + b.identity.name + ': ' + err}

	# pass 2b: fill the action lists
	for b: Dictionary in built:
		global.SAVE_DATA = b.save_data
		router.current_route = b.base_route
		map_deps.ast_list.set(b.identity.id, HenUtils.get_current_ast_list())
		var err: String = HenHengoActions.build_actions(b.save_data, b.spec, all_scripts)
		if not err.is_empty():
			return {ok = false, error = 'in script ' + b.identity.name + ': ' + err}

	# refresh ast_list now that declarations exist (cross-script resolution)
	for b: Dictionary in built:
		global.SAVE_DATA = b.save_data
		map_deps.ast_list.set(b.identity.id, HenUtils.get_current_ast_list())

	# pass 3: persist + compile each script. debug instrumentation is left on when
	# the json requests it (needed for the hengo state debugger)
	var debug: bool = _json.get('debug', false)
	ProjectSettings.set_setting(HenSettings.DEBUG_COMPILATION_PATH, debug)
	var code_gen: HenCodeGeneration = Engine.get_singleton(&'CodeGeneration')
	if not DirAccess.dir_exists_absolute(HenEnums.HENGO_SCRIPTS_PATH):
		DirAccess.make_dir_recursive_absolute(HenEnums.HENGO_SCRIPTS_PATH)

	var scripts: Array = []
	for b: Dictionary in built:
		if not DirAccess.dir_exists_absolute(b.id_path):
			DirAccess.make_dir_recursive_absolute(b.id_path)
		b.identity.take_over_path(b.id_path.path_join(HenEnums.IDENTITY_FILE))
		b.save_data.take_over_path(b.id_path.path_join(HenEnums.SAVE_FILE))
		var r1: int = ResourceSaver.save(b.identity)
		var r2: int = ResourceSaver.save(b.save_data)
		if r1 != OK or r2 != OK:
			return {ok = false, error = 'failed to save resources for ' + b.identity.name}
		collection.add_script(StringName(str(b.id)))

		global.SAVE_DATA = b.save_data
		router.current_route = b.base_route
		var code: String = code_gen.get_code(b.save_data)
		var file: FileAccess = FileAccess.open(b.identity.script_path, FileAccess.WRITE)
		if not file:
			return {ok = false, error = 'could not write ' + b.identity.script_path}
		file.store_string(code)
		file.close()

		scripts.append({
			name = b.identity.name,
			save_path = b.id_path.path_join(HenEnums.SAVE_FILE),
			script_path = b.identity.script_path,
			code = code,
			actions = _tally_actions(b.save_data),
			unresolved = _unresolved_lines(code),
			parse_error = _parse_error(code, b.identity.script_path),
		})

	collection.last_active_id = StringName(str(built[0].id))
	HenCollectionManager.save_active_collection()
	HenUtils.rebuild_script_index()

	# pass 4: round-trip verify each script (reload .res -> codegen must match)
	var all_rt: bool = true
	var all_resolved: bool = true
	for s: Dictionary in scripts:
		var rt: Dictionary = _verify_roundtrip(s.save_path, s.code)
		s.roundtrip_ok = rt.ok
		s.roundtrip_detail = rt.detail
		all_rt = all_rt and rt.ok
		all_resolved = all_resolved and (s.unresolved as Array).is_empty() and str(s.parse_error).is_empty()

	return {ok = true, collection = collection.name, scripts = scripts, roundtrip_ok = all_rt, resolved_ok = all_resolved}


func _report(_result: Dictionary) -> void:
	print('OK -> collection: ', _result.collection)

	for s: Dictionary in _result.scripts:
		var rt: String = 'round-trip ok' if s.roundtrip_ok else ('ROUND-TRIP MISMATCH: ' + str(s.roundtrip_detail))
		print('OK -> ', s.script_path, '  [', rt, ']')
		print('        actions: ', s.actions)

		for line: String in s.unresolved:
			printerr('[hengo_cli] ', s.name, ': ', line)

		if not str(s.parse_error).is_empty():
			printerr('[hengo_cli] ', s.name, ': ', s.parse_error)

	if not _result.resolved_ok:
		printerr('[hengo_cli] one or more scripts could not be emitted')

	if not _result.roundtrip_ok:
		printerr('[hengo_cli] one or more scripts failed round-trip')


# builds identity + empty save_data for one script spec; the folder is written
# later in pass 3 so a failed pass 2 leaves no orphaned folders behind
func _create_script_resource(_collection: HenSaveCollection, _spec: Dictionary) -> Dictionary:
	var script_name: String = String(_spec.get('name', 'generated')).to_snake_case()
	var extends_class: StringName = _spec.get('extends', 'Node')
	if not ClassDB.class_exists(extends_class):
		extends_class = 'Node'

	var id: int = ResourceUID.create_id()
	var id_path: String = HenEnums.HENGO_COLLECTION_PATH.path_join(_collection.id).path_join(str(id))

	var identity: HenSaveDataIdentity = HenSaveDataIdentity.create(str(id), extends_class, script_name)
	identity.script_path = HenEnums.HENGO_SCRIPTS_PATH + script_name + '.gd'

	var save_data: HenSaveData = HenSaveData.new()
	save_data.identity = identity
	save_data.counter = 1
	var base_route: HenRouteData = save_data.create_route(identity.id, 'Base', HenRouter.ROUTE_TYPE.BASE)

	return {id = id, id_path = id_path, identity = identity, save_data = save_data, base_route = base_route, spec = _spec}


# reloads the .res from disk bypassing the resource cache (a genuinely fresh
# deserialization, not the in-memory instance) and re-runs codegen, comparing to
# the in-memory output. globals are pointed at the reloaded graph so both codegen
# passes use the same context — the only variable is in-memory vs serialized graph.
func _verify_roundtrip(_save_path: String, _expected_code: String) -> Dictionary:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var router: HenRouter = Engine.get_singleton(&'Router')

	var reloaded: HenSaveData = ResourceLoader.load(_save_path, '', ResourceLoader.CACHE_MODE_IGNORE_DEEP)
	if not reloaded:
		return {ok = false, detail = 'reload failed: ' + _save_path}

	global.SAVE_DATA = reloaded
	global.OPEN_SCRIPTS = [reloaded]
	router.current_route = reloaded.get_base_route()

	var map_deps: HenMapDependencies = Engine.get_singleton(&'MapDependencies')
	map_deps.ast_list.set(reloaded.identity.id, HenUtils.get_current_ast_list())

	# keep the same DEBUG_COMPILATION_PATH set during compilation so both codegen
	# passes match (the setting was applied per the json `debug` flag)
	var code_gen: HenCodeGeneration = Engine.get_singleton(&'CodeGeneration')
	var reloaded_code: String = code_gen.get_code(reloaded)

	if reloaded_code == _expected_code:
		return {ok = true, detail = 'identical'}

	return {ok = false, detail = 'reloaded code differs from in-memory (%d vs %d chars)' % [reloaded_code.length(), _expected_code.length()]}


# actions per state and phase, so the report proves what was built
func _tally_actions(_save_data: HenSaveData) -> String:
	var parts: PackedStringArray = []

	for state_id: Variant in _save_data.state_actions:
		var state: HenSaveState = HenGeneratorAction.find_state(_save_data, StringName(str(state_id)))
		var phases: Dictionary = {}

		for action: HenSaveAction in _save_data.state_actions[state_id]:
			var phase: String = str(action.phase)
			phases[phase] = phases.get(phase, 0) + 1

		var counts: PackedStringArray = []
		for phase: StringName in HenSaveAction.PHASE_ORDER:
			if phases.has(str(phase)):
				counts.append('%s:%d' % [phase, phases[str(phase)]])

		parts.append((state.name if state else str(state_id)) + ': ' + ' '.join(counts))

	return ' · '.join(parts) if not parts.is_empty() else '(none)'


# feeds the emitted source to the gdscript parser, so a broken macro body is
# caught here instead of at runtime
func _parse_error(_code: String, _path: String) -> String:
	var script: GDScript = GDScript.new()
	script.source_code = _code
	script.take_over_path(_path)

	return '' if script.reload() == OK else 'does not parse'


# codegen leaves a comment where an action could not be emitted; those are errors here
func _unresolved_lines(_code: String) -> Array:
	var lines: Array = []

	for line: String in _code.split('\n'):
		if line.strip_edges().begins_with(UNRESOLVED_MARKER):
			lines.append(line.strip_edges())

	return lines


# removes every existing collection whose manifest name matches (keeps regen idempotent)
func _purge_collections_named(_name: String) -> void:
	var base: String = HenEnums.HENGO_COLLECTION_PATH
	if not DirAccess.dir_exists_absolute(base):
		return

	for dir_name: String in DirAccess.get_directories_at(base):
		var manifest: String = base.path_join(dir_name).path_join(HenEnums.COLLECTION_FILE)
		if not FileAccess.file_exists(manifest):
			continue
		var col: HenSaveCollection = ResourceLoader.load(manifest, '', ResourceLoader.CACHE_MODE_IGNORE_DEEP)
		if col and col.name == _name:
			HenCollectionManager.delete_collection(StringName(dir_name))


func _read_json(_path: String) -> Dictionary:
	if not FileAccess.file_exists(_path):
		return {}
	var text: String = FileAccess.get_file_as_string(_path)
	var parsed: Variant = JSON.parse_string(text)
	return parsed if parsed is Dictionary else {}


func _arg_value(_args: PackedStringArray, _flag: String, _fallback: String) -> String:
	for arg: String in _args:
		if arg.begins_with(_flag + '='):
			return arg.substr(_flag.length() + 1)

	return _fallback


func _fail(_msg: String) -> void:
	push_error('[hengo_cli] ' + _msg)
	printerr('[hengo_cli] ', _msg)
	quit(1)
