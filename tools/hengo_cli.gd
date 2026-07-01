extends SceneTree

# this cli is just for tests purposes; it is not a supported entry point for hengo usage

# headless entry point to generate a hengo script from a high-level json.
# usage: godot --headless -s tools/hengo_cli.gd -- <script.json> [collection_name]


const HENGO_ROOT_SCENE: String = 'res://addons/hengo/scenes/hengo_root.tscn'
const HenHengoTranslate = preload('res://tools/hengo_translate.gd')


func _initialize() -> void:
	var user_args: PackedStringArray = OS.get_cmdline_user_args()

	if user_args.is_empty():
		_fail('usage: godot --headless -s tools/hengo_cli.gd -- <script.json> [collection_name]')
		return

	var json_path: String = user_args[0]
	var collection_name: String = user_args[1] if user_args.size() > 1 else 'AI'

	var json: Dictionary = _read_json(json_path)
	if json.is_empty():
		_fail('could not read or parse json: ' + json_path)
		return

	var root_scene: Node = await _bootstrap()
	if not root_scene:
		_fail('bootstrap failed (api not ready)')
		return

	var result: Dictionary = await _generate(json, collection_name)
	root_scene.free()

	if not result.ok:
		_fail(result.get('error', 'unknown error'))
		return

	print('OK -> collection: ', result.collection)
	for s: Dictionary in result.scripts:
		var rt: String = 'round-trip ok' if s.roundtrip_ok else ('ROUND-TRIP MISMATCH: ' + str(s.roundtrip_detail))
		print('OK -> ', s.script_path, '  [', rt, ']')
		print('        nodes: ', s.nodes)

	if result.roundtrip_ok:
		quit(0)
	else:
		printerr('[hengo_cli] one or more scripts failed round-trip')
		quit(2)


# instantiates the hengo scene, registers singletons and waits for the native api
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

	return root_scene


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

	# pass 2: build graphs. scripts referenced cross-script (transition_other) must
	# come earlier in the list so their states exist when a later script references them
	for b: Dictionary in built:
		global.SAVE_DATA = b.save_data
		router.current_route = b.base_route
		map_deps.ast_list.set(b.identity.id, HenUtils.get_current_ast_list())
		var err: String = HenHengoTranslate.build(b.save_data, b.spec, all_scripts)
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
			nodes = _tally_subtypes(b.save_data),
		})

	collection.last_active_id = StringName(str(built[0].id))
	HenCollectionManager.save_active_collection()
	HenUtils.rebuild_script_index()

	# pass 4: round-trip verify each script (reload .res -> codegen must match)
	var all_rt: bool = true
	for s: Dictionary in scripts:
		var rt: Dictionary = _verify_roundtrip(s.save_path, s.code)
		s.roundtrip_ok = rt.ok
		s.roundtrip_detail = rt.detail
		all_rt = all_rt and rt.ok

	return {ok = true, collection = collection.name, scripts = scripts, roundtrip_ok = all_rt}


# creates the on-disk folder + identity + empty save_data for one script spec
func _create_script_resource(_collection: HenSaveCollection, _spec: Dictionary) -> Dictionary:
	var script_name: String = String(_spec.get('name', 'generated')).to_snake_case()
	var extends_class: StringName = _spec.get('extends', 'Node')
	if not ClassDB.class_exists(extends_class):
		extends_class = 'Node'

	var id: int = ResourceUID.create_id()
	var id_path: String = HenEnums.HENGO_COLLECTION_PATH.path_join(_collection.id).path_join(str(id))
	if not DirAccess.dir_exists_absolute(id_path):
		DirAccess.make_dir_recursive_absolute(id_path)

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


# compact count of node sub_types across all routes (proves real nodes, not raw)
func _tally_subtypes(_save_data: HenSaveData) -> String:
	var rev: Dictionary = {}
	for k: String in HenVirtualCNode.SubType.keys():
		rev[HenVirtualCNode.SubType[k]] = k

	var tally: Dictionary = {}
	for route_id: StringName in _save_data.routes:
		for vc: HenVirtualCNode in (_save_data.routes[route_id] as HenRouteData).virtual_cnode_list:
			var nm: String = rev.get(vc.sub_type, str(vc.sub_type))
			tally[nm] = tally.get(nm, 0) + 1

	var keys: Array = tally.keys()
	keys.sort()
	var parts: PackedStringArray = []
	for k: String in keys:
		parts.append('%s:%d' % [k, tally[k]])
	return ' '.join(parts)


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


func _fail(_msg: String) -> void:
	push_error('[hengo_cli] ' + _msg)
	printerr('[hengo_cli] ', _msg)
	quit(1)
