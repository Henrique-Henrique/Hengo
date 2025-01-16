#[hengo] {"comments":[],"connections":[{"from_cnode":12,"input":0,"output":0,"to_cnode":13}],"debug_symbols":{"2":[7],"4":[8,"cnode"],"8":[7]},"flow_connections":[{"from_cnode":8,"from_connector":0,"to_cnode":12},{"from_cnode":12,"from_connector":0,"to_cnode":13}],"func_list":[],"generals":[{"cnode_list":[{"hash":2,"inputs":[],"name":"_input","outputs":[{"name":"event","type":"InputEvent"}],"pos":"Vector2(0, 0)","sub_type":9}],"cnode_name":"_input","id":1,"name":"Input","pos":"Vector2(-120, -200)"},{"cnode_list":[{"hash":4,"inputs":[],"name":"_process","outputs":[{"name":"delta","type":"float"}],"pos":"Vector2(0, 0)","sub_type":9}],"cnode_name":"_process","color":"#401d3f","id":3,"name":"Process","param":{"name":"delta","type":"float"},"pos":"Vector2(9, -200)"},{"cnode_list":[{"hash":6,"inputs":[],"name":"_physics_process","outputs":[{"name":"delta","type":"float"}],"pos":"Vector2(0, 0)","sub_type":9}],"cnode_name":"_physics_process","color":"#1f2950","id":5,"name":"Physics Process","param":{"name":"delta","type":"float"},"pos":"Vector2(167, -200)"}],"node_counter":13,"props":[],"state_name_counter":1,"states":[{"cnode_list":[{"hash":8,"inputs":[],"name":"enter","outputs":[],"pos":"Vector2(0, 0)","sub_type":9},{"hash":9,"inputs":[],"name":"update","outputs":[{"name":"delta","type":"float"}],"pos":"Vector2(400, 0)","sub_type":9},{"hash":12,"inputs":[{"25":0,"name":"start","type":"int"},{"25":10,"name":"end","type":"int"},{"25":1,"name":"step","type":"int"}],"name":"For -> Range","outputs":[{"name":"index","type":"int"}],"pos":"Vector2(-94.0881, 201.912)","sub_type":15},{"category":"native","hash":13,"inputs":[{"name":"content","type":"Variant"}],"name":"print","outputs":[],"pos":"Vector2(-18.0836, 573.934)","sub_type":1}],"events":[{"name":"Start","type":"start"}],"id":7,"name":"State 1","pos":"Vector2(0, 0)","route":{"id":"173705291054122","name":"State 1","type":0},"transitions":[]}],"type":"Sprite2D"}

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


func go_to_event(_obj_ref: Node, _state_name: StringName) -> void:
	_obj_ref._STATE_CONTROLLER.change_state(_state_name)


func _ready() -> void:
	if not _STATE_CONTROLLER.current_state:
		EngineDebugger.send_message('hengo:debug_state', [2])
		_STATE_CONTROLLER.change_state("state_1")


func _process(delta: float) -> void:
	_STATE_CONTROLLER.static_process(delta)



func _physics_process(delta: float) -> void:
	_STATE_CONTROLLER.static_physics_process(delta)








# Functions
class State1 extends HengoState:
	func enter() -> void:
		#hen_dbg#var __hen_id__: float = 0.

		for loop_idx in range(0, 10, 1):
			print(loop_idx)
		#hen_dbg#__hen_id__ += 4
		#hen_dbg#EngineDebugger.send_message('hengo:cnode', [__hen_id__])
		#hen_dbg#EngineDebugger.send_message('hengo:debug_state', [8])



