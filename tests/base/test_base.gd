extends GdUnitTestSessionHook

const HENGO_ROOT = preload('res://addons/hengo/scenes/hengo_root.tscn')

func _init():
	super ("MyCustomHook", "Description of what this hook does")

func startup(_session: GdUnitTestSession) -> GdUnitResult:
	register_singletons()

	return GdUnitResult.success()


func shutdown(_session: GdUnitTestSession) -> GdUnitResult:
	unregister_singletons()
	return GdUnitResult.success()


func register_singletons() -> void:
	for singleton_name: StringName in HenEnums.SINGLETON_LIST:
		var root: HenHengoRoot = HENGO_ROOT.instantiate()
		Engine.register_singleton(singleton_name, root.get_node(NodePath(StringName('%'+ singleton_name))))


func unregister_singletons() -> void:
	for singleton_name: StringName in HenEnums.SINGLETON_LIST:
		if Engine.has_singleton(singleton_name):
			Engine.unregister_singleton(singleton_name)