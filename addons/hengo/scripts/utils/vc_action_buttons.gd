@tool
class_name HenVCActionButtons extends Control

const BUTTON_SCENE = preload('res://addons/hengo/scenes/utils/connection_action_button.tscn')
const POOL_SIZE: int = 30
const ENTER_MARGIN: float = 65.
const EXIT_MARGIN: float = 65.

var button_pool: Array[HenConnectionActionButton] = []
var active_buttons: Array[HenConnectionActionButton] = []
var current_vc: HenVirtualCNode
var current_cnode: HenCnode
var is_showing: bool = false


func _ready() -> void:
	if HenUtils.disable_scene_with_owner(self):
		return

	_instantiate_pool()
	set_process(true)


# creates pool of action buttons
func _instantiate_pool() -> void:
	for i in POOL_SIZE:
		var btn: HenConnectionActionButton = BUTTON_SCENE.instantiate()
		btn.visible = false
		button_pool.append(btn)
		add_child(btn)


# gets a button from the pool
func _get_button_from_pool() -> HenConnectionActionButton:
	for btn in button_pool:
		if not btn.visible:
			return btn
	return null


# checks mouse position against bounding boxes
func _process(_delta: float) -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	if not global or not global.CAM or not global.HENGO_ROOT or not global.HENGO_ROOT.visible:
		return
	
	var mouse_pos: Vector2 = global.CAM.get_relative_vec2(get_global_mouse_position())
	
	# if showing, check if mouse left the extended bounding box
	if is_showing and current_cnode:
		var extended_rect = Rect2(
			current_cnode.position - Vector2(EXIT_MARGIN, EXIT_MARGIN),
			current_cnode.size + Vector2(EXIT_MARGIN * 2, EXIT_MARGIN * 2)
		)
		if not extended_rect.has_point(mouse_pos):
			hide_action()
			return
	
	# if not showing, check if mouse entered any cnode bounding box (with margin)
	if not is_showing:
		var router: HenRouter = Engine.get_singleton(&'Router')
		if not router or not router.current_route:
			return
		
		for vc: HenVirtualCNode in router.current_route.virtual_cnode_list:
			if not vc.cnode_instance:
				continue
			
			var cnode: HenCnode = vc.cnode_instance
			var rect = Rect2(
				cnode.position - Vector2(ENTER_MARGIN, ENTER_MARGIN),
				cnode.size + Vector2(ENTER_MARGIN * 2, ENTER_MARGIN * 2)
			)
			
			if rect.has_point(mouse_pos):
				show_action(cnode)
				return


# shows action buttons for all ports of the cnode
func show_action(_cnode: HenCnode) -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')

	# find the virtual cnode by id
	var vc: HenVirtualCNode = _find_vc_by_cnode_id(_cnode.id)
	if not vc:
		return

	# hide previous buttons if showing for different node
	if current_vc and current_vc != vc:
		hide_action()

	current_vc = vc
	current_cnode = _cnode
	visible = true
	is_showing = true

	# get container references with their positions
	var center_container: VBoxContainer = _cnode.get_node('%CenterContainer')
	var from_flow_container: HBoxContainer = _cnode.get_node('%FromFlowContainer')
	var flow_container: HBoxContainer = _cnode.get_node('%FlowContainer')

	# show buttons for inputs
	var inputs: Array[HenVCInOutData] = vc.get_inputs(global.SAVE_DATA)
	
	for i in inputs.size():
		var input: HenVCInOutData = inputs[i]
		if input.is_static:
			continue
		
		if i >= center_container.get_child_count():
			break
		
		var panel = center_container.get_child(i)
		var row = panel.get_child(0)
		var input_node: HenCnodeInOut = row.get_node_or_null('Input') if row else null

		if not input_node or not input_node.visible:
			continue
		
		var btn = _get_button_from_pool()
		if not btn:
			break

		var has_connection: bool = vc.input_has_connection(input.id, global.SAVE_DATA)
		btn.configure(vc, HenConnectionActionButton.PortType.INPUT, input.id, has_connection, input.type)
		
		# center_container pos + panel pos + row pos + input pos + centering math
		var y_offset: float = center_container.position.y + panel.position.y + row.position.y + input_node.position.y + input_node.size.y / 2 - btn.size.y / 2
		btn.position = _cnode.position + Vector2(-btn.size.x - 4, y_offset)
		btn.visible = true
		btn.animate_show()
		active_buttons.append(btn)

	# show buttons for outputs
	var outputs: Array[HenVCInOutData] = vc.get_outputs(global.SAVE_DATA)
	
	for i in outputs.size():
		var output: HenVCInOutData = outputs[i]
		
		if i >= center_container.get_child_count():
			break
			
		var panel = center_container.get_child(i)
		var row = panel.get_child(0)
		var output_node: HenCnodeInOut = row.get_node_or_null('Output') if row else null
		
		if not output_node or not output_node.visible:
			continue
		
		var btn = _get_button_from_pool()
		if not btn:
			break

		btn.configure(vc, HenConnectionActionButton.PortType.OUTPUT, output.id, false, output.type)
		
		# center_container pos + panel pos + row pos + output pos + centering math
		var y_offset: float = center_container.position.y + panel.position.y + row.position.y + output_node.position.y + output_node.size.y / 2 - btn.size.y / 2
		btn.position = _cnode.position + Vector2(_cnode.size.x + 4, y_offset)
		btn.visible = true
		btn.animate_show()
		active_buttons.append(btn)

	# show buttons for flow inputs
	var flow_inputs: Array[HenVCFlow] = vc.get_flow_inputs(global.SAVE_DATA)
	
	for i in flow_inputs.size():
		var flow_input: HenVCFlow = flow_inputs[i]
		
		if i >= from_flow_container.get_child_count():
			break
		
		var flow_node = from_flow_container.get_child(i)
		if not flow_node or not flow_node.visible:
			continue
		
		var btn = _get_button_from_pool()
		if not btn:
			break

		var has_connection: bool = vc.flow_input_has_connection(flow_input.id, _cnode.id)
		btn.configure(vc, HenConnectionActionButton.PortType.FLOW_INPUT, flow_input.id, has_connection)
		
		var parent_panel = from_flow_container.get_parent()
		var x_offset: float = parent_panel.position.x + from_flow_container.position.x + flow_node.position.x + flow_node.size.x / 2 - btn.size.x / 2
		btn.position = _cnode.position + Vector2(x_offset, -btn.size.y - 4)
		btn.visible = true
		btn.animate_show()
		active_buttons.append(btn)

	# show buttons for flow outputs
	var flow_outputs: Array[HenVCFlow] = vc.get_flow_outputs(global.SAVE_DATA)
	
	for i in flow_outputs.size():
		var flow_output: HenVCFlow = flow_outputs[i]
		
		if i >= flow_container.get_child_count():
			break
		
		var flow_node = flow_container.get_child(i)
		if not flow_node or not flow_node.visible:
			continue
		
		var btn = _get_button_from_pool()
		if not btn:
			break

		var has_connection: bool = vc.flow_output_has_connection(flow_output.id, _cnode.id)
		btn.configure(vc, HenConnectionActionButton.PortType.FLOW_OUTPUT, flow_output.id, has_connection)
		
		var parent_panel = flow_container.get_parent()
		var x_offset: float = parent_panel.position.x + flow_container.position.x + flow_node.position.x + flow_node.size.x / 2 - btn.size.x / 2
		btn.position = _cnode.position + Vector2(x_offset, _cnode.size.y + 40)
		btn.visible = true
		btn.animate_show()
		active_buttons.append(btn)


func hide_action() -> void:
	for btn in active_buttons:
		btn.visible = false
	
	active_buttons.clear()
	current_vc = null
	current_cnode = null
	visible = false
	is_showing = false


# finds virtual cnode by cnode id
func _find_vc_by_cnode_id(_id: StringName) -> HenVirtualCNode:
	var router: HenRouter = Engine.get_singleton(&'Router')

	if not router.current_route:
		return null

	for vc: HenVirtualCNode in router.current_route.virtual_cnode_list:
		if vc.id == _id:
			return vc

	return null


static func get_singleton() -> HenVCActionButtons:
	return (Engine.get_singleton(&'Global') as HenGlobal).HENGO_ROOT.get_node('%VCActionButtons') as HenVCActionButtons
