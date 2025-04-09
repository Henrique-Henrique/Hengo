class_name HenUtils extends Node


static func move_array_item(_arr: Array, _ref, _factor: int) -> bool:
    var target_idx: int = _arr.find(_ref) - _factor
    var can_move: bool = false

    match _factor:
        1:
            can_move = target_idx >= 0
        (-1):
            can_move = target_idx < _arr.size()

    if can_move:
        var value_to_change = _arr[target_idx]
        _arr[target_idx] = _ref
        _arr[target_idx + _factor] = value_to_change

    return can_move


static func move_array_item_to_idx(_arr: Array, _ref, _pos: int) -> void:
    var value_to_change = _arr[_pos]
    var old_pos: int = _arr.find(_ref)

    _arr[_pos] = _ref
    _arr[old_pos] = value_to_change