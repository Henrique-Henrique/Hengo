class_name MyCustomHook
extends GdUnitTestSessionHook

const HENGO_ROOT = preload('res://addons/hengo/scenes/hengo_root.tscn')

var _hengo_root_instance: Node = null

func _init():
    super ("MyCustomHook", "Description of what this hook does")
	

func startup(_session: GdUnitTestSession) -> GdUnitResult:
    register_singletons()

    return GdUnitResult.success()


func shutdown(_session: GdUnitTestSession) -> GdUnitResult:
    unregister_singletons()

    return GdUnitResult.success()


func register_singletons() -> void:
    if not _hengo_root_instance:
        _hengo_root_instance = HENGO_ROOT.instantiate()

    for singleton_name: StringName in HenEnums.SINGLETON_LIST:
        var node: Node = _hengo_root_instance.get_node(NodePath(StringName('%'+ singleton_name)))
        Engine.register_singleton(singleton_name, node)
   
    HenTest.set_global_config()


func unregister_singletons() -> void:
    for singleton_name: StringName in HenEnums.SINGLETON_LIST:
        if Engine.has_singleton(singleton_name):
            Engine.unregister_singleton(singleton_name)

    if is_instance_valid(_hengo_root_instance):
        _hengo_root_instance.free()

        _hengo_root_instance = null