class_name HenVirtualState extends RefCounted


var id: int
var name: String
var route: Dictionary
var position: Vector2
var size: Vector2
var transitions: Array = []

var is_showing: bool = false
var state_ref: HenState


class TransitionData:
	var name: String
	var to: HenVirtualState


func check_visibility(_rect: Rect2) -> void:
	is_showing = _rect.intersects(
		Rect2(
			position,
			size
		)
	)

	if is_showing and state_ref == null:
		show()
	elif not is_showing:
		hide()


func show() -> void:
	for state: HenState in HenGlobal.state_pool:
		if not state.visible:
			state.position = position
			state.visible = true
			state.virtual_ref = self

			state_ref = state

			var idx: int = 0

			for transition: HenStateTransition in state.get_node('%TransitionContainer').get_children():
				transition.visible = false

				if idx < transitions.size():
					var transition_data: TransitionData = transitions[idx]

					transition.visible = true
					transition.set_transition_name(transition_data.name)

				idx += 1


			state.route = route
			state.set_state_name(name)
			
			state.reset_size()
			break


func hide() -> void:
	if state_ref:
		state_ref.visible = false
		state_ref.virtual_ref = null
		state_ref = null


func add_transition(_config: Dictionary) -> void:
	var transition: TransitionData = TransitionData.new()

	transition.name = _config.name
	transitions.append(transition)


static func instantiate_virtual_state(_config: Dictionary) -> HenVirtualState:
	var v_state: HenVirtualState = HenVirtualState.new()

	v_state.id = HenGlobal.get_new_node_counter() if not _config.has('id') else _config.id
	v_state.name = _config.name
	v_state.route.id = HenUtilsName.get_unique_name()

	HenRouter.route_reference[v_state.route.id] = []
	HenRouter.line_route_reference[v_state.route.id] = []
	HenRouter.comment_reference[v_state.route.id] = []

	if _config.has('pos'):
		v_state.position = str_to_var(_config.pos)
	elif _config.has('position'):
		v_state.position = _config.position

	HenGlobal.vs_list.append(v_state)

	return v_state