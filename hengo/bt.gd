#[hengo] {"comments":[],"connections":[{"from_cnode":11,"input":0,"output":0,"to_cnode":10}],"debug_symbols":{"16":[7],"2":[7],"4":[15,"cnode"],"8":[8,"cnode"]},"flow_connections":[{"from_cnode":15,"from_connector":0,"to_cnode":17},{"from_cnode":8,"from_connector":0,"to_cnode":10},{"from_cnode":10,"from_connector":0,"to_cnode":13},{"from_cnode":13,"from_connector":0,"to_cnode":19}],"func_list":[{"cnode_list":[{"group":"f_14","hash":15,"inputs":[],"name":"input","outputs":[],"pos":"Vector2(100.915, 0)","sub_type":10},{"group":"f_14","hash":16,"inputs":[],"name":"output","outputs":[],"pos":"Vector2(0, 500)","sub_type":18},{"category":"native","hash":17,"inputs":[{"name":"content","type":"Variant"}],"name":"print","outputs":[],"pos":"Vector2(43.4154, 199)","sub_type":1}],"hash":14,"pos":"Vector2(180.267, -59.1451)","props":[{"name":"name","type":"String","value":"func_name"},{"name":"inputs","type":"in_out","value":[]},{"name":"outputs","type":"in_out","value":[]}],"ref_count":0}],"generals":[{"cnode_list":[{"hash":2,"inputs":[],"name":"_input","outputs":[{"name":"event","type":"InputEvent"}],"pos":"Vector2(0, 0)","sub_type":9}],"cnode_name":"_input","id":1,"name":"Input","pos":"Vector2(-120, -200)"},{"cnode_list":[{"hash":4,"inputs":[],"name":"_process","outputs":[{"name":"delta","type":"float"}],"pos":"Vector2(0, 0)","sub_type":9}],"cnode_name":"_process","color":"#401d3f","id":3,"name":"Process","param":{"name":"delta","type":"float"},"pos":"Vector2(9, -200)"},{"cnode_list":[{"hash":6,"inputs":[],"name":"_physics_process","outputs":[{"name":"delta","type":"float"}],"pos":"Vector2(0, 0)","sub_type":9}],"cnode_name":"_physics_process","color":"#1f2950","id":5,"name":"Physics Process","param":{"name":"delta","type":"float"},"pos":"Vector2(167, -200)"}],"node_counter":19,"props":[],"state_name_counter":2,"states":[{"cnode_list":[{"hash":8,"inputs":[],"name":"enter","outputs":[],"pos":"Vector2(80.882, 0)","sub_type":9},{"hash":9,"inputs":[],"name":"update","outputs":[{"name":"delta","type":"float"}],"pos":"Vector2(400, 0)","sub_type":9},{"category":"native","hash":10,"inputs":[{"name":"content","type":"Variant"}],"name":"print","outputs":[],"pos":"Vector2(65.382, 199)","sub_type":1},{"hash":11,"inputs":[{"name":"Sprite2D","ref":true,"type":"Sprite2D"}],"name":"get_vframes","outputs":[{"name":"","type":"int"}],"pos":"Vector2(-271.618, 199)","sub_type":0},{"category":"native","hash":13,"inputs":[{"in_prop":"dasdsZas","name":"content","type":"String"}],"name":"print","outputs":[],"pos":"Vector2(-16.118, 447)","sub_type":1},{"category":"native","hash":19,"inputs":[{"category":"state_transition","in_prop":"transition_0","name":"name","sub_type":"@dropdown","type":"Variant"}],"name":"make_transition","outputs":[],"pos":"Vector2(-17.118, 706)","sub_type":0}],"events":[{"name":"Start","type":"start"}],"id":7,"name":"State 1","pos":"Vector2(-190.001, 44.0002)","route":{"id":"17386116280675","name":"State 1","type":0},"transitions":[{"name":"Transition 0","to_state_id":18},{"name":"Transition 1"},{"name":"Transition 2"}]},{"cnode_list":[],"events":[],"id":18,"name":"State 2","pos":"Vector2(174.268, 261.169)","route":{"id":"173861162808776","name":"State 2","type":0},"transitions":[{"name":"Transition 0"},{"name":"Transition 1"},{"name":"Transition 2"}]}],"type":"Sprite2D"}

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
		state_1=State1.new(self, {
			transition_0="state_2"
		}),
		state_2=State2.new(self)
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
func func_name():
	#hen_dbg#var __hen_id__: float = 0.
	print(null)
	#hen_dbg#__hen_id__ += 4
	#hen_dbg#EngineDebugger.send_message('hengo:cnode', [__hen_id__])
class State1 extends HengoState:
	func enter() -> void:
		#hen_dbg#var __hen_id__: float = 0.

		print(_ref.get_vframes())
		print("dasdsZas")
		make_transition("transition_0")
		#hen_dbg#__hen_id__ += 8
		#hen_dbg#EngineDebugger.send_message('hengo:cnode', [__hen_id__])
		#hen_dbg#EngineDebugger.send_message('hengo:debug_state', [16])



class State2 extends HengoState:
	pass

