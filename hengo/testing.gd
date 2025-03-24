#[hengo] {"comments":[],"connections":[],"debug_symbols":{"2":[3,"cnode"]},"flow_connections":[],"func_list":[],"generals":[],"node_counter":5,"prop_counter":0,"props":[],"state_name_counter":0,"type":"Sprite2D","virtual_cnode_list":[{"flow_connections":[{"to_id":2,"to_idx":0}],"id":1,"input_connections":[],"inputs":[],"name":"State","output_connections":[],"outputs":[],"position":"Vector2(0, 0)","size":"Vector2(66, 68)","sub_type":36,"type":0},{"flow_connections":[],"id":2,"input_connections":[],"inputs":[],"name":"State 1","output_connections":[],"outputs":[],"position":"Vector2(225.478, 344.377)","size":"Vector2(77, 60)","sub_type":35,"type":4,"virtual_vc_list":[{"flow_connections":[{"to_id":5,"to_idx":0}],"id":3,"input_connections":[],"inputs":[],"name":"enter","output_connections":[],"outputs":[],"position":"Vector2(0, 0)","size":"Vector2(66, 68)","sub_type":9,"type":0},{"flow_connections":[],"id":4,"input_connections":[],"inputs":[],"name":"update","output_connections":[],"outputs":[{"name":"delta","type":"float"}],"position":"Vector2(400, 0)","size":"Vector2(112, 111)","sub_type":9,"type":0},{"category":"native","flow_connections":[],"id":5,"input_connections":[],"inputs":[{"code_value":"null","name":"content","type":"Variant"}],"name":"print","output_connections":[],"outputs":[],"position":"Vector2(115.629, 347.927)","size":"Vector2(200, 112)","sub_type":1,"type":0}]}]}

# ***************************************************************
# *                 CREATED BY HENGO VISUAL SCRIPT              *
# *    This file is automatically generated and maintained by   *
# *               the Hengo Visual Script tool.                 *
# *       Edit only if you are confident in your changes.       *
# ***************************************************************

extends Sprite2D

 # Variables #

var _STATE_CONTROLLER = HengoStateController.new()

func _init() -> void:
	_STATE_CONTROLLER.set_states({
		state_1=State1.new(self)
	})

func _ready() -> void:
	if not _STATE_CONTROLLER.current_state:
		_STATE_CONTROLLER.change_state("state_1")


func _process(delta: float) -> void:
	_STATE_CONTROLLER.static_process(delta)



func _physics_process(delta: float) -> void:
	_STATE_CONTROLLER.static_physics_process(delta)








# Functions
class State1 extends HengoState:
	func enter() -> void:
		#hen_dbg#var __hen_id__: float = 0.

		print(null)
		#hen_dbg#__hen_id__ += 2
		#hen_dbg#EngineDebugger.send_message('hengo:cnode', [__hen_id__])
		#hen_dbg#EngineDebugger.send_message('hengo:debug_state', [99])



