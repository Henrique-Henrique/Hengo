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


# creates the on-disk folder + identity + empty save_data for one script spec
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
