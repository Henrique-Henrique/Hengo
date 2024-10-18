@tool
extends Button

# errors
var cnode_errors: Dictionary = {}

func _ready() -> void:
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	#TODO show errors screen
	print(cnode_errors)

func _set_count(_count: int) -> void:
	text = str(_count)

	if _count <= 0:
		get('theme_override_styles/normal').set('bg_color', Color('#468b68'))
	else:
		get('theme_override_styles/normal').set('bg_color', Color('#c16460'))

# public
#
func reset() -> void:
	cnode_errors = {}
	_set_count(0)

func set_error_on_id(_id: int, _errors: Array[Dictionary]) -> void:
	cnode_errors[_id] = _errors

	var count: int = 0

	for id: int in cnode_errors:
		count += cnode_errors[id].size()
	
	_set_count(count)
