@tool
class_name HenSaveVar extends HenSaveResType

@export var type: StringName

func _init() -> void:
    id = (Engine.get_singleton(&'Global') as HenGlobal).get_new_node_counter()


func get_inputs(_type: HenVirtualCNode.SubType) -> Array[Dictionary]:
    if _type == HenVirtualCNode.SubType.SET_VAR:
        return [
            {
                id = 0,
                name = name,
                type = type,
            }
        ]
    
    return []


func get_outputs(_type: HenVirtualCNode.SubType) -> Array[Dictionary]:
    if _type == HenVirtualCNode.SubType.VAR:
        return [
            {
                id = 0,
                name = name,
                type = type,
            },
            {
                id = 1,
                name = name + '_2',
                type = &'int',
            },
        ]
    
    return []


func get_getter_cnode_data() -> Dictionary:
    var router: HenRouter = Engine.get_singleton(&'Router')

    return {
        name = 'Get ' + name,
        sub_type = HenVirtualCNode.SubType.VAR,
        route = router.current_route,
        res = self,
    }


func get_setter_cnode_data() -> Dictionary:
    var router: HenRouter = Engine.get_singleton(&'Router')

    return {
        name = 'Set ' + name,
        sub_type = HenVirtualCNode.SubType.SET_VAR,
        route = router.current_route,
        res = self,
    }