@tool
extends Resource

# imports
const _Enums = preload('res://addons/hengo/references/enums.gd')
const _Global = preload('res://addons/hengo/scripts/global.gd')

var _ref: Node
var cnode_var_ref: Resource
var dropdown_options: Array = _Enums.DROPDOWN_ALL_CLASSES

# props
@export var name: String = ''
@export var type: int = -1
@export var value = null:
    set(new_value):
        # item_name tells hengo o change prop and instances names
        match sub_type:
            'item_name':
                var can_change_name: bool = true

                # checking all items name
                for section in _Global.SIDE_BAR.get_node('%Sections').get_children():
                    for item in section.get_node('%Container').get_children():
                        if item.is_queued_for_deletion():
                            continue

                        if new_value == item.get_node('%Name').text:
                            can_change_name = false
                            new_value = value
                            break

                # TODO show error on screen when name is repeated
                if can_change_name:
                    if _ref:
                        _ref.get_node('%Name').text = new_value
                        cnode_var_ref.name = new_value
            'item_type':
                if cnode_var_ref:
                    cnode_var_ref.type = new_value
        
        value = new_value

@export var sub_type: String = ''