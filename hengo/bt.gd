#[hengo] {"comments":[],"connections":[{"from_cnode":15,"input":0,"output":0,"to_cnode":16},{"from_cnode":16,"input":0,"output":0,"to_cnode":17},{"from_cnode":21,"input":0,"output":2,"to_cnode":17}],"debug_symbols":{"16":[7],"2":[7],"4":[11,"cnode"],"8":[8,"cnode"]},"flow_connections":[{"from_cnode":11,"from_connector":0,"to_cnode":25},{"from_cnode":8,"from_connector":0,"to_cnode":17}],"func_item_list":[],"func_list":[{"cnode_list":[{"group":"f_10","hash":11,"inputs":[],"name":"input","outputs":[],"pos":"Vector2(0, 0)","sub_type":"func_input"},{"group":"f_10","hash":12,"inputs":[],"name":"output","outputs":[],"pos":"Vector2(0, 500)","sub_type":"func_output"},{"category":"native","hash":25,"inputs":[{"in_prop":"IT'S WORKS!!!!!!!!!!","name":"content","type":"String"}],"name":"print","outputs":[],"pos":"Vector2(-125.834, 168.62)","sub_type":"void"}],"hash":10,"pos":"Vector2(357.312, 28.3835)","props":[{"name":"name","type":"String","value":"func_name"},{"name":"inputs","type":"in_out","value":[]},{"name":"outputs","type":"in_out","value":[]}],"ref_count":0}],"generals":[{"cnode_list":[{"hash":2,"inputs":[],"name":"_input","outputs":[{"name":"event","type":"InputEvent"}],"pos":"Vector2(0, 0)","sub_type":"virtual"}],"cnode_name":"_input","id":1,"name":"Input","pos":"Vector2(-120, -200)"},{"cnode_list":[{"hash":4,"inputs":[],"name":"_process","outputs":[{"name":"delta","type":"float"}],"pos":"Vector2(0, 0)","sub_type":"virtual"}],"cnode_name":"_process","color":"#401d3f","id":3,"name":"Process","param":{"name":"delta","type":"float"},"pos":"Vector2(9, -200)"},{"cnode_list":[{"hash":6,"inputs":[],"name":"_physics_process","outputs":[{"name":"delta","type":"float"}],"pos":"Vector2(0, 0)","sub_type":"virtual"}],"cnode_name":"_physics_process","color":"#1f2950","id":5,"name":"Physics Process","param":{"name":"delta","type":"float"},"pos":"Vector2(167, -200)"}],"local_var_items":[],"node_counter":25,"props":[],"signal_item_list":[],"state_name_counter":1,"states":[{"cnode_list":[{"hash":8,"inputs":[],"name":"enter","outputs":[],"pos":"Vector2(655.988, 100.997)","sub_type":"virtual"},{"hash":9,"inputs":[],"name":"update","outputs":[{"name":"delta","type":"float"}],"pos":"Vector2(1599.01, 90.0005)","sub_type":"virtual"},{"hash":15,"inputs":[{"name":"Sprite2D","ref":true,"type":"Sprite2D"}],"name":"get_tree","outputs":[{"name":"","type":"SceneTree"}],"pos":"Vector2(-205.857, 318.838)","sub_type":"func"},{"hash":16,"inputs":[{"name":"SceneTree","ref":true,"type":"SceneTree"},{"in_prop":3,"name":"time_sec","type":"float"},{"in_prop":false,"name":"process_always","type":"bool"},{"in_prop":false,"name":"process_in_physics","type":"bool"},{"in_prop":false,"name":"ignore_time_scale","type":"bool"}],"name":"create_timer","outputs":[{"name":"","type":"SceneTreeTimer"}],"pos":"Vector2(84.1442, 317.838)","sub_type":"func"},{"hash":17,"inputs":[{"name":"SceneTreeTimer","ref":true,"type":"SceneTreeTimer"},{"in_prop":"timeout","name":"signal","type":"StringName"},{"name":"callable","type":"Callable"},{"in_prop":0,"name":"flags","type":"int"}],"name":"connect","outputs":[{"name":"","type":"int"}],"pos":"Vector2(554.148, 318.838)","sub_type":"func"},{"category":"native","hash":21,"inputs":[{"category":"disabled","in_prop":"Callable.create(_ref, \"func_name\")","name":"","type":"String"}],"name":"Raw Code","outputs":[{"name":"code","type":"Variant"}],"pos":"Vector2(-32.8562, 680.838)","sub_type":"raw_code"}],"events":[{"name":"Start","type":"start"}],"id":7,"name":"State Name 1","pos":"Vector2(0, 0)","route":{"id":"173497652137261","name":"State Name 1","type":0},"transitions":[]}],"type":"Sprite2D","var_item_list":[]}

extends Sprite2D

# Variables #

var _STATE_CONTROLLER = HengoStateController.new()

func _init() -> void:
	_STATE_CONTROLLER.set_states({
		state_name_1 = StateName1.new(self)
	})


func go_to_event(_obj_ref: Node, _state_name: StringName) -> void:
	_obj_ref._STATE_CONTROLLER.change_state(_state_name)


func _ready() -> void:
	if not _STATE_CONTROLLER.current_state:
		EngineDebugger.send_message('hengo:debug_state', [2])
		_STATE_CONTROLLER.change_state("state_name_1")


func _process(delta: float) -> void:
	_STATE_CONTROLLER.static_process(delta)


func _physics_process(delta: float) -> void:
	_STATE_CONTROLLER.static_physics_process(delta)


# Functions
func func_name():
	#hen_dbg#var __hen_id__: float = 0.
	print("IT'S WORKS!!!!!!!!!!")
	#hen_dbg#__hen_id__ += 4
	#hen_dbg#EngineDebugger.send_message('hengo:cnode', [__hen_id__])
#

# Signals Callables
class StateName1 extends HengoState:
	func enter() -> void:
		#hen_dbg#var __hen_id__: float = 0.

		_ref.get_tree().create_timer(3, false, false, false).connect("timeout", Callable.create(_ref, "func_name"), 0)
		#hen_dbg#__hen_id__ += 8
		#hen_dbg#EngineDebugger.send_message('hengo:cnode', [__hen_id__])
		#hen_dbg#EngineDebugger.send_message('hengo:debug_state', [16])
