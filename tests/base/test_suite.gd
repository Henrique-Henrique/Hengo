class_name HenTestSuite extends GdUnitTestSuite

var save_data: HenSaveData
var root: HenHengoRoot


func before_test() -> void:
	root = (preload('res://addons/hengo/scenes/hengo_root.tscn') as PackedScene).instantiate()

	for singleton_name: StringName in HenEnums.SINGLETON_LIST:
		var node: Node = root.get_node(NodePath(StringName('%'+ singleton_name)))
		Engine.register_singleton(singleton_name, node)

	set_global_config()


func after_test() -> void:
	for singleton_name: StringName in HenEnums.SINGLETON_LIST:
		if Engine.has_singleton(singleton_name):
			Engine.unregister_singleton(singleton_name)
		
	root.free()


func set_global_config() -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var router: HenRouter = Engine.get_singleton(&'Router')

	var _save_data: HenSaveData = HenSaveData.new()
	var _class: StringName = 'Node'
	var id: int = ResourceUID.create_id()
	var identity: HenSaveDataIdentity = HenSaveDataIdentity.create(str(id), _class, 'Test')

	_save_data.identity = identity
	_save_data.counter = 1

	var base_route: HenRouteData = HenRouteData.create(
		'Base',
		HenRouter.ROUTE_TYPE.BASE,
		_save_data.identity.id,
	)

	HenCreateScript.get_start_state(base_route)

	_save_data.add_route(_save_data.identity.id, base_route)

	global.SAVE_DATA = _save_data
	global.IS_HEADLESS = true
	router.current_route = global.SAVE_DATA.get_base_route()

	var map_deps: HenMapDependencies = Engine.get_singleton(&'MapDependencies')
	map_deps.ast_list.set(_save_data.identity.id, HenUtils.get_current_ast_list())

	save_data = _save_data