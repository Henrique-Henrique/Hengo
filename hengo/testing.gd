#[hengo] {"comments":[],"connections":[],"debug_symbols":{"2.0":[3,"cnode"],"4.0":[6,"cnode"]},"flow_connections":[],"func_list":[],"generals":[],"node_counter":32,"prop_counter":0,"props":[],"side_bar_list":{"func_list":[{"id":5,"inputs":[{"id":8,"name":"my input","type":"Variant"},{"id":32,"name":"asd","type":"Variant"}],"name":"maybe ok","outputs":[{"id":9,"name":"my output","type":"Variant"},{"id":31,"name":"ds","type":"Variant"}],"virtual_cnode_list":[{"flow_connections":[{"to_id":10,"to_idx":0}],"id":6,"input_connections":[],"name":"input","output_connections":[],"outputs":[{"name":"my input","ref_id":8,"type":"Variant"},{"name":"asd","ref_id":32,"type":"Variant"}],"position":"Vector2(-485.699, -57.1411)","ref_id":5,"size":"Vector2(79, 111)","sub_type":10,"type":0},{"flow_connections":[],"id":7,"input_connections":[{"from_idx":0,"from_vc_id":13,"idx":0}],"inputs":[{"category":"default_value","code_value":"null","name":"my output","ref_id":9,"type":"Variant"},{"name":"ds","ref_id":31,"type":"Variant"}],"name":"output","output_connections":[],"position":"Vector2(938.24, 175.634)","ref_id":5,"size":"Vector2(80, 111)","sub_type":18,"type":0},{"category":"native","flow_connections":[{"to_id":17,"to_idx":0}],"id":10,"input_connections":[{"from_idx":0,"from_vc_id":6,"idx":0}],"inputs":[{"category":"default_value","code_value":"null","name":"content","type":"Variant"}],"name":"print","output_connections":[],"position":"Vector2(-271.795, 262.181)","size":"Vector2(135, 111)","sub_type":1,"type":0},{"flow_connections":[],"id":11,"input_connections":[],"inputs":[{"category":"default_value","code_value":"_ref","is_ref":true,"name":"Sprite2D","type":"Sprite2D"}],"name":"get_offset","output_connections":[],"outputs":[{"name":"","type":"Vector2"}],"position":"Vector2(-950.836, 587.712)","size":"Vector2(259, 112)","sub_type":0,"type":0},{"flow_connections":[],"id":12,"input_connections":[],"inputs":[{"category":"default_value","code_value":"_ref","is_ref":true,"name":"Sprite2D","type":"Sprite2D"}],"name":"get_transform","output_connections":[],"outputs":[{"name":"","type":"Transform2D"}],"position":"Vector2(280.568, 756.687)","size":"Vector2(259, 112)","sub_type":0,"type":0},{"flow_connections":[],"id":13,"input_connections":[{"from_idx":0,"from_vc_id":12,"idx":0}],"inputs":[{"category":"default_value","code_value":"Transform2D()","is_ref":true,"name":"Transform2D","type":"Transform2D"}],"name":"get_rotation","output_connections":[],"outputs":[{"name":"","type":"float"}],"position":"Vector2(576.611, 391.515)","size":"Vector2(230, 111)","sub_type":0,"type":0},{"category":"native","flow_connections":[],"id":17,"input_connections":[{"from_idx":0,"from_vc_id":11,"idx":0}],"inputs":[{"category":"default_value","code_value":"null","name":"content","type":"Variant"}],"name":"print","output_connections":[],"position":"Vector2(-485.884, 577.455)","size":"Vector2(135, 111)","sub_type":1,"type":0}]}],"var_list":[]},"state_event_list":[],"type":"Sprite2D","virtual_cnode_list":[{"flow_connections":[{"to_id":2,"to_idx":0}],"id":1,"input_connections":[],"name":"State","output_connections":[],"position":"Vector2(0, 0)","size":"Vector2(91, 84)","sub_type":36,"type":5},{"flow_connections":[],"id":2,"input_connections":[],"name":"State 1","output_connections":[],"position":"Vector2(5.98538, 412.461)","size":"Vector2(77, 60)","sub_type":35,"type":4,"virtual_cnode_list":[{"flow_connections":[{"to_id":14,"to_idx":0}],"id":3,"input_connections":[],"name":"enter","output_connections":[],"position":"Vector2(0, 0)","size":"Vector2(66, 68)","sub_type":9,"type":0},{"flow_connections":[],"id":4,"input_connections":[],"name":"update","output_connections":[],"outputs":[{"name":"delta","type":"float"}],"position":"Vector2(400, 0)","size":"Vector2(112, 111)","sub_type":9,"type":0},{"category":"native","flow_connections":[{"to_id":30,"to_idx":0}],"id":14,"input_connections":[{"from_idx":0,"from_vc_id":16,"idx":0}],"inputs":[{"category":"default_value","code_value":"null","name":"content","type":"Variant"}],"name":"print","output_connections":[],"position":"Vector2(-31.6969, 344.713)","size":"Vector2(135, 111)","sub_type":1,"type":0},{"flow_connections":[],"id":15,"input_connections":[],"inputs":[{"category":"default_value","code_value":"_ref","is_ref":true,"name":"Sprite2D","type":"Sprite2D"}],"name":"get_transform","output_connections":[],"outputs":[{"name":"","type":"Transform2D"}],"position":"Vector2(-714.664, 347.288)","size":"Vector2(259, 112)","sub_type":0,"type":0},{"flow_connections":[],"id":16,"input_connections":[{"from_idx":0,"from_vc_id":15,"idx":0}],"inputs":[{"category":"default_value","code_value":"Transform2D()","is_ref":true,"name":"Transform2D","type":"Transform2D"}],"name":"get_origin","output_connections":[],"outputs":[{"name":"","type":"Vector2"}],"position":"Vector2(-376.592, 285.005)","size":"Vector2(230, 111)","sub_type":0,"type":0},{"flow_connections":[],"id":30,"input_connections":[],"inputs":[{"category":"default_value","code_value":"null","name":"my input","ref_id":8,"type":"Variant"},{"name":"asd","ref_id":32,"type":"Variant"}],"name":"maybe ok","output_connections":[],"outputs":[{"name":"my output","ref_id":9,"type":"Variant"},{"name":"ds","ref_id":31,"type":"Variant"}],"position":"Vector2(-63.17, 709.706)","ref_id":5,"size":"Vector2(204, 112)","sub_type":5,"type":0}]}]}

# ***************************************************************
# *                 CREATED BY HENGO VISUAL SCRIPT              *
# *    This file is automatically generated and maintained by   *
# *               the Hengo Visual Script tool.                 *
# *       Edit only if you are confident in your changes.       *
# ***************************************************************

extends Sprite2D


var _STATE_CONTROLLER = HengoStateController.new()

const _EVENTS ={}

func _init() -> void:
	_STATE_CONTROLLER.set_states({
		state_1=State1.new(self)
	})

func _ready() -> void:
	if not _STATE_CONTROLLER.current_state:
		_STATE_CONTROLLER.change_state("state_1")

func trigger_event(_event: String) -> void:
	if _EVENTS.has(_event):
		_STATE_CONTROLLER.change_state(_EVENTS[_event])

func _process(delta: float) -> void:
	_STATE_CONTROLLER.static_process(delta)



func _physics_process(delta: float) -> void:
	_STATE_CONTROLLER.static_physics_process(delta)








# Functions
func maybe_ok(my_input, asd):
	print(my_input)
	print(self.get_offset())
	#hen_dbg#__hen_id__ += 4.0
	#hen_dbg#EngineDebugger.send_message('hengo:cnode', [__hen_id__])
	return [self.get_transform().get_rotation(), null]



class State1 extends HengoState:
	func enter() -> void:
		#hen_dbg#var __hen_id__: float = 0.

		print(_ref.get_transform().get_origin())
		_ref.maybe_ok(null, null)[0]
		#hen_dbg#__hen_id__ += 2.0
		#hen_dbg#EngineDebugger.send_message('hengo:cnode', [__hen_id__])
		#hen_dbg#EngineDebugger.send_message('hengo:debug_state', [99])



