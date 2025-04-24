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


static func is_type_relation_valid(_type: StringName, _to_type: StringName) -> bool:
	# check if type is the same e.g. String == String
	if _type == _to_type:
		return true

	# check if one of the types are Variant e.g. Variant <-> Object
	if _type == &'Variant' or _to_type == &'Variant':
		return true

	# check some rules for types e.g. String <-> StringName
	if HenEnums.RULES_TO_CONNECT.has(_to_type):
		if HenEnums.RULES_TO_CONNECT[_to_type].has(_type):
			return true

	# check if class is from Node, this is useful when using methods like "get_node" e.g. Node -> BaseButton
	if _type == &'Node' and ClassDB.is_parent_class(_to_type, &'Node'):
		return true

	# check if type inherits the other type e.g. Control -> Button
	if ClassDB.is_parent_class(_type, _to_type):
		return true

	# denies if none is true
	return false


static func reposition_control_inside(_control: Control) -> void:
	var rect: Rect2 = HenGlobal.CAM.get_viewport_rect()

	# x
	if _control.position.x + _control.size.x > rect.size.x:
		_control.position.x = rect.size.x - _control.size.x - 8
	
	if _control.position.x < rect.position.x:
		_control.position.x = rect.position.x + _control.size.x + 8
	
	# y
	if _control.position.y + _control.size.y > rect.size.y:
		_control.position.y = rect.size.y - _control.size.y - 8
	elif _control.position.y < rect.position.y:
		_control.position.y = rect.position.y + _control.size.y + 8