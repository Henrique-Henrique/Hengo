@tool
extends HBoxContainer

enum {
    MOVE_UP,
    MOVE_DOWN,
    DELETE
}

var state_transition_ref

func _ready() -> void:
	get_child(0).value_changed.connect(_on_name_change)
	get_child(1).get_popup().id_pressed.connect(_on_id_pressed)

func _on_name_change(_name: String) -> void:
	# TODO make unique name definition
	state_transition_ref.set_transition_name(_name)

func _on_id_pressed(_id: int) -> void:
	match _id:
		DELETE:
			var ref = state_transition_ref.root

			state_transition_ref.get_parent().remove_child(state_transition_ref)

			ref.size = Vector2.ZERO
			state_transition_ref.queue_free()
			queue_free()
		# TODO finish this
		# MOVE_UP:
		# 	emit_signal('move_up_pressed')
		# MOVE_DOWN:
		# 	emit_signal('move_down_pressed')

# public
#
func set_prop_name(_name: String) -> void:
	get_child(0).text = _name


func get_prop_name() -> String:
	return get_child(0).text
