#[hengo] {"comments":[],"connections":[{"from_cnode":13,"input":0,"output":0,"to_cnode":14},{"from_cnode":14,"input":0,"output":0,"to_cnode":15}],"debug_symbols":{"16.0":[7],"2.0":[7],"4.0":[19,"cnode"],"8.0":[8,"cnode"]},"flow_connections":[{"from_cnode":8,"from_connector":0,"to_cnode":15},{"from_cnode":19,"from_connector":0,"to_cnode":21}],"func_item_list":[],"func_list":[{"cnode_list":[{"fantasy_name":"Func -> haha","group":"f_18","hash":19,"inputs":[],"name":"input","outputs":[],"pos":"Vector2(0, 0)","sub_type":"func_input"},{"fantasy_name":"Func -> haha","group":"f_18","hash":20,"inputs":[],"name":"output","outputs":[],"pos":"Vector2(0, 500)","sub_type":"func_output"},{"category":"native","hash":21,"inputs":[{"in_prop":"xxx","name":"content","type":"String"}],"name":"print","outputs":[],"pos":"Vector2(-26.9638, 222.095)","sub_type":"void"}],"hash":18,"pos":"Vector2(263, -45)","props":[{"name":"name","type":"String","value":"haha"},{"name":"inputs","type":"in_out","value":[]},{"name":"outputs","type":"in_out","value":[]}],"ref_count":0}],"generals":[{"cnode_list":[{"hash":2,"inputs":[],"name":"_input","outputs":[{"name":"event","type":"InputEvent"}],"pos":"Vector2(0, 0)","sub_type":"virtual"}],"cnode_name":"_input","id":1,"name":"Input","pos":"Vector2(-120, -200)"},{"cnode_list":[{"hash":4,"inputs":[],"name":"_process","outputs":[{"name":"delta","type":"float"}],"pos":"Vector2(0, 0)","sub_type":"virtual"}],"cnode_name":"_process","color":"#401d3f","id":3,"name":"Process","param":{"name":"delta","type":"float"},"pos":"Vector2(9, -200)"},{"cnode_list":[{"hash":6,"inputs":[],"name":"_physics_process","outputs":[{"name":"delta","type":"float"}],"pos":"Vector2(0, 0)","sub_type":"virtual"}],"cnode_name":"_physics_process","color":"#1f2950","id":5,"name":"Physics Process","param":{"name":"delta","type":"float"},"pos":"Vector2(167, -200)"}],"local_var_items":[],"node_counter":21,"props":[],"signal_item_list":[],"state_name_counter":1,"states":[{"cnode_list":[{"hash":8,"inputs":[],"name":"enter","outputs":[],"pos":"Vector2(389.001, 176.001)","sub_type":"virtual"},{"hash":9,"inputs":[],"name":"update","outputs":[{"name":"delta","type":"float"}],"pos":"Vector2(1193, 198.001)","sub_type":"virtual"},{"hash":15,"inputs":[{"name":"SceneTreeTimer","ref":true,"type":"SceneTreeTimer"},{"category":"signal","data":"SceneTreeTimer","in_prop":"timeout","name":"signal","sub_type":"@dropdown","type":"StringName"},{"category":"callable","in_prop":"haha","name":"callable","sub_type":"@dropdown","type":"Callable"},{"in_prop":0.0,"name":"flags","type":"int"}],"name":"connect","outputs":[{"name":"","type":"int"}],"pos":"Vector2(297.155, 341.095)","sub_type":"func"},{"hash":13,"inputs":[{"name":"Sprite2D","ref":true,"type":"Sprite2D"}],"name":"get_tree","outputs":[{"name":"","type":"SceneTree"}],"pos":"Vector2(-322.035, 339.088)","sub_type":"func"},{"hash":14,"inputs":[{"name":"SceneTree","ref":true,"type":"SceneTree"},{"in_prop":3.0,"name":"time_sec","type":"float"},{"in_prop":false,"name":"process_always","type":"bool"},{"in_prop":false,"name":"process_in_physics","type":"bool"},{"in_prop":false,"name":"ignore_time_scale","type":"bool"}],"name":"create_timer","outputs":[{"name":"","type":"SceneTreeTimer"}],"pos":"Vector2(-57.0768, 339.758)","sub_type":"func"}],"events":[{"name":"Start","type":"start"}],"id":7,"name":"State Name 1","pos":"Vector2(0, 0)","route":{"id":"17354165074414","name":"State Name 1","type":0},"transitions":[]}],"type":"Sprite2D","var_item_list":[]}

extends Sprite2D

# Variables #

var _STATE_CONTROLLER = HengoStateController.new()

func _init() -> void:
	_STATE_CONTROLLER.set_states({
		state_name_1=StateName1.new(self)
	})


func go_to_event(_obj_ref: Node, _state_name: StringName) -> void:
	_obj_ref._STATE_CONTROLLER.change_state(_state_name)


func _ready() -> void:
	if not _STATE_CONTROLLER.current_state:
		EngineDebugger.send_message('hengo:debug_state', [2.0])
		_STATE_CONTROLLER.change_state("state_name_1")


func _process(delta: float) -> void:
	_STATE_CONTROLLER.static_process(delta)



func _physics_process(delta: float) -> void:
	_STATE_CONTROLLER.static_physics_process(delta)








# Functions
func haha():
	#hen_dbg#var __hen_id__: float = 0.
	print("xxx")
	#hen_dbg#__hen_id__ += 4.0
	#hen_dbg#EngineDebugger.send_message('hengo:cnode', [__hen_id__])
#

# Signals Callables
class StateName1 extends HengoState:
	func enter() -> void:
		#hen_dbg#var __hen_id__: float = 0.

		_ref.get_tree().create_timer(3.0, false, false, false).connect("timeout", _ref.haha, 0.0)
		#hen_dbg#__hen_id__ += 8.0
		#hen_dbg#EngineDebugger.send_message('hengo:cnode', [__hen_id__])
		#hen_dbg#EngineDebugger.send_message('hengo:debug_state', [16.0])



