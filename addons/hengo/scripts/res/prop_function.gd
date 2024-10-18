@tool
extends Resource

# imports
const _Global = preload('res://addons/hengo/scripts/global.gd')

var item_ref: Node
var inputs: Array = []
var outputs: Array = []

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
                        
                        # TODO make validation with snake case here
                        # do in var too
                        if new_value == item.get_node('%Name').text:
                            can_change_name = false
                            new_value = value
                            break
                
                # TODO show error on screen when name is repeated
                if can_change_name:
                    if item_ref:
                        item_ref.get_node('%Name').text = new_value
                    
                    if item_ref:
                        for node in item_ref.instance_reference:
                            if node.type != 'func_input' and node.type != 'func_output':
                                match node.type:
                                    'signal_connection':
                                        node.change_name('Connect -> ' + new_value)
                                    'signal_disconnection':
                                        node.change_name('Disconnect -> ' + new_value)
                                    'signal_emit':
                                        node.change_name('Emit Signal -> ' + new_value)
                                    _:
                                        node.change_name_and_raw(new_value)
        
        value = new_value

@export var sub_type: String = ''

# private
#
func _move_in_out(_obj: Dictionary, _type: String, _factor: int) -> int:
    var idx_ref = 0

    # TODO when changing position needs to redraw line
    match _type:
        'in':
            var idx = inputs.find(_obj)
            var target_idx = clamp(idx - _factor, 0, inputs.size() - 1)
            var before = inputs[target_idx]
            
            inputs[idx] = before
            inputs[target_idx] = _obj
            idx_ref = idx
        'out':
            var idx = outputs.find(_obj)
            var target_idx = clamp(idx - _factor, 0, outputs.size() - 1)
            var before = outputs[target_idx]
            
            outputs[idx] = before
            outputs[target_idx] = _obj
            idx_ref = idx
    
    return idx_ref

#public
#
func move_up_down(_res: Resource, _move_type: String, _type: String) -> void:
    var obj = {res = _res}
    
    match _move_type:
        'up':
            var idx = _move_in_out(obj, _type, 1)

            if idx > 0:
                for in_out in _res.in_out_ref:
                    in_out.move_up_down('up')
        'down':
            _move_in_out(obj, _type, -1)

            for in_out in _res.in_out_ref:
                in_out.move_up_down('down')

func remove_in_out(_res: Resource, _type: String) -> void:
    var obj = {res = _res}

    for in_out in _res.in_out_ref:
        in_out.remove()

    match _type:
        'in':
            inputs.erase(obj)
        'out':
            outputs.erase(obj)

func add_in_out(_res: Resource, _type: String) -> void:
    var obj = {res = _res}

    print('obj type -> ', _type)

    match _type:
        'in':
            inputs.append(obj)
            for node in item_ref.instance_reference:
                match node.type:
                    'func_output':
                        pass
                    'func_input':
                        node.add_output(obj)
                    _:
                        node.add_input(obj)
        'out':
            outputs.append(obj)
            for node in item_ref.instance_reference:
                match node.type:
                    'func_input', 'signal_disconnection':
                        pass
                    'signal_connection', 'signal_emit', 'func_output':
                        node.add_input(obj)
                    _:
                        node.add_output(obj)
