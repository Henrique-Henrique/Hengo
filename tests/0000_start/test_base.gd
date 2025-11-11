extends GdUnitTestSuite

const HENGO_ROOT = preload('res://addons/hengo/scenes/hengo_root.tscn')

func before_test() -> void:
	register_singletons()


func test_start() -> void:
	pass


func register_singletons() -> void:
	for singleton_name: StringName in HenEnums.SINGLETON_LIST:
		var root: HenHengoRoot = HENGO_ROOT.instantiate()
		Engine.register_singleton(singleton_name, root.get_node(NodePath(StringName('%'+ singleton_name))))


func unregister_singletons() -> void:
	for singleton_name: StringName in HenEnums.SINGLETON_LIST:
		if Engine.has_singleton(singleton_name):
			Engine.unregister_singleton(singleton_name)