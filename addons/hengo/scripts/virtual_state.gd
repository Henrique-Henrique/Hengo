class_name HenVirtualState extends RefCounted


var id: int
var name: String
var route: Dictionary
var position: Vector2
var size: Vector2
var transitions: Array = []
var from_transitions: Array = []
var events: Array = []
var is_showing: bool = false
var state_ref: HenState


class EventData:
	var name: String
	var type: StringName

	func _init(_name: String, _type: String) -> void:
		name = _name
		type = _type

class TransitionData:
	var name: String
	var from: HenVirtualState
	var to: HenVirtualState
	var line_ref: HenStateConnectionLine
	var from_pos: Vector2
	var to_pos: Vector2


	func get_save() -> Dictionary:
		return {
			name = name,
			to_state_id = to.id,
		}


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

			var event_container = state.get_node('%EventContainer')
			var event_list = event_container.get_child(0).get_node('%EventList')

			var idx: int = 0

			if events.size() > 0:
				event_container.visible = true

			for event_data: EventData in events:
				var event

				if idx < event_list.get_child_count():
					event = event_list.get_child(idx)
				else:
					event = HenAssets.EventScene.instantiate()
					event_list.add_child(event)
				
				(event.get_child(0) as Variant).text = event_data.name

				idx += 1

			idx = 0

			for transition: HenStateTransition in state.get_node('%TransitionContainer').get_children():
				transition.visible = false

				if idx < transitions.size():
					var transition_data: TransitionData = transitions[idx]

					transition.visible = true
					transition.transition_ref = transition_data
					transition.set_transition_name(transition_data.name)

					if transition_data.to:
						if not transition_data.line_ref:
							transition_data.line_ref = HenPool.get_state_line_from_pool()
						
						transition_data.line_ref.from_pool_visible = true
						transition_data.line_ref.from_transition = transition

						transition_data.line_ref.to_virtual_pos = transition_data.to_pos

						transition_data.line_ref.update_line()

						# signal to update connection line
						if not state_ref.is_connected('on_move', transition_data.line_ref.update_line):
							state_ref.connect('on_move', transition_data.line_ref.update_line)

				idx += 1


			for transition: TransitionData in from_transitions:
				if transition.from:
					if not transition.line_ref:
						transition.line_ref = HenPool.get_state_line_from_pool()


					transition.line_ref.to_pool_visible = true
					transition.line_ref.to_state = state_ref

					transition.line_ref.from_virtual_pos = transition.from_pos
					transition.line_ref.update_line()
					
					# signal to update connection line
					if not state_ref.is_connected('on_move', transition.line_ref.update_line):
						state_ref.connect('on_move', transition.line_ref.update_line)


			state.route = route
			state.set_state_name(name)
			
			state.reset_size()
			size = state.size
			break


func hide() -> void:
	if state_ref:
		for signal_data: Dictionary in state_ref.get_signal_connection_list('on_move'):
			state_ref.disconnect('on_move', signal_data.callable)
		
		var event_container = state_ref.get_node('%EventContainer')
		event_container.visible = false

		for transition: TransitionData in transitions:
			if transition.to:
				if transition.line_ref:
					transition.line_ref.from_pool_visible = false

					transition.from_pos = transition.line_ref.points[0]
					transition.line_ref.from_virtual_pos = transition.from_pos
					
					if not transition.to.is_showing:
						transition.line_ref.visible = false
						transition.line_ref = null
					

		for transition: TransitionData in from_transitions:
			transition.line_ref.to_pool_visible = false
			
			transition.to_pos = transition.line_ref.points[-1]
			transition.line_ref.to_virtual_pos = transition.to_pos

			if not transition.from.is_showing:
				transition.line_ref.visible = false
				transition.line_ref = null
			

		state_ref.visible = false
		state_ref.virtual_ref = null
		state_ref = null


func add_transition(_config: Dictionary) -> void:
	var transition: TransitionData = TransitionData.new()

	transition.name = _config.name
	transitions.append(transition)


func reset() -> void:
	is_showing = false

	if state_ref:
		state_ref.virtual_ref = null
		state_ref.visible = false
		state_ref = null


func add_event(_config: Dictionary) -> void:
	events.append(EventData.new(_config.name, _config.type))


static func instantiate_virtual_state(_config: Dictionary) -> HenVirtualState:
	var v_state: HenVirtualState = HenVirtualState.new()

	v_state.id = HenGlobal.get_new_node_counter() if not _config.has('id') else _config.id
	v_state.name = _config.name
	v_state.route.id = HenUtilsName.get_unique_name()
	v_state.route.type = HenRouter.ROUTE_TYPE.STATE

	HenRouter.route_reference[v_state.route.id] = []
	HenRouter.line_route_reference[v_state.route.id] = []
	HenRouter.comment_reference[v_state.route.id] = []

	if _config.has('pos'):
		v_state.position = str_to_var(_config.pos)
	elif _config.has('position'):
		v_state.position = _config.position

	HenGlobal.vs_list.append(v_state)

	return v_state