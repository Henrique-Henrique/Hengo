@tool
class_name HenStateTransitionProp extends HBoxContainer

enum {
	MOVE_UP,
	MOVE_DOWN,
	DELETE
}

var state_transition_ref: HenStateTransition

# deleted
var parent_ref_deleted
var idx: int

func _ready() -> void:
	get_child(0).value_changed.connect(_on_name_change)
	get_child(1).get_popup().id_pressed.connect(_on_id_pressed)

func _on_name_change(_name: String) -> void:
	# TODO make unique name definition
	state_transition_ref.set_transition_name(_name)

func _on_id_pressed(_id: int) -> void:
	match _id:
		DELETE:
			HenGlobal.history.create_action('Remove transition')
			HenGlobal.history.add_do_method(state_transition_ref.remove_from_scene)
			HenGlobal.history.add_do_method(remove_from_scene)
			HenGlobal.history.add_undo_reference(state_transition_ref)
			HenGlobal.history.add_undo_reference(self)
			HenGlobal.history.add_undo_method(state_transition_ref.add_to_scene)
			HenGlobal.history.add_undo_method(add_to_scene)
			HenGlobal.history.commit_action()
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


func remove_from_scene() -> void:
	if not self.is_inside_tree():
		return
	
	idx = get_index()
	
	parent_ref_deleted = get_parent()
	parent_ref_deleted.remove_child(self)


func add_to_scene() -> void:
	if self.is_inside_tree():
		return

	parent_ref_deleted.add_child(self)
	parent_ref_deleted.move_child(self, idx)

	state_transition_ref.get_parent().move_child(state_transition_ref, idx)
