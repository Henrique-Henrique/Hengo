#[hengo] {"comments":[],"connections":[{"from_cnode":13,"input":0,"output":0,"to_cnode":14},{"from_cnode":14,"input":0,"output":0,"to_cnode":15}],"debug_symbols":{"2":[7],"4":[8,"cnode"],"8":[7]},"flow_connections":[{"from_cnode":8,"from_connector":0,"to_cnode":15}],"func_item_list":[],"func_list":[],"generals":[{"cnode_list":[{"hash":2,"inputs":[],"name":"_input","outputs":[{"name":"event","type":"InputEvent"}],"pos":"Vector2(0, 0)","sub_type":"virtual"}],"cnode_name":"_input","id":1,"name":"Input","pos":"Vector2(-120, -200)"},{"cnode_list":[{"hash":4,"inputs":[],"name":"_process","outputs":[{"name":"delta","type":"float"}],"pos":"Vector2(0, 0)","sub_type":"virtual"}],"cnode_name":"_process","color":"#401d3f","id":3,"name":"Process","param":{"name":"delta","type":"float"},"pos":"Vector2(9, -200)"},{"cnode_list":[{"hash":6,"inputs":[],"name":"_physics_process","outputs":[{"name":"delta","type":"float"}],"pos":"Vector2(0, 0)","sub_type":"virtual"}],"cnode_name":"_physics_process","color":"#1f2950","id":5,"name":"Physics Process","param":{"name":"delta","type":"float"},"pos":"Vector2(167, -200)"}],"local_var_items":[],"node_counter":15,"props":[],"signal_item_list":[],"state_name_counter":1,"states":[{"cnode_list":[{"hash":8,"inputs":[],"name":"enter","outputs":[],"pos":"Vector2(389.001, 176.001)","sub_type":"virtual"},{"hash":9,"inputs":[],"name":"update","outputs":[{"name":"delta","type":"float"}],"pos":"Vector2(1193, 198.001)","sub_type":"virtual"},{"hash":15,"inputs":[{"name":"SceneTreeTimer","ref":true,"type":"SceneTreeTimer"},{"category":"signal","data":"SceneTreeTimer","in_prop":"Variant","name":"signal","sub_type":"@dropdown","type":"StringName"},{"category":"callable","in_prop":"Variant","name":"callable","sub_type":"@dropdown","type":"Callable"},{"in_prop":0,"name":"flags","type":"int"}],"name":"connect","outputs":[{"name":"","type":"int"}],"pos":"Vector2(56.9404, 427.84)","sub_type":"func"},{"hash":13,"inputs":[{"name":"Sprite2D","ref":true,"type":"Sprite2D"}],"name":"get_tree","outputs":[{"name":"","type":"SceneTree"}],"pos":"Vector2(-725.062, 433.84)","sub_type":"func"},{"hash":14,"inputs":[{"name":"SceneTree","ref":true,"type":"SceneTree"},{"in_prop":0,"name":"time_sec","type":"float"},{"in_prop":false,"name":"process_always","type":"bool"},{"in_prop":false,"name":"process_in_physics","type":"bool"},{"in_prop":false,"name":"ignore_time_scale","type":"bool"}],"name":"create_timer","outputs":[{"name":"","type":"SceneTreeTimer"}],"pos":"Vector2(-412.061, 431.84)","sub_type":"func"}],"events":[{"name":"Start","type":"start"}],"id":7,"name":"State Name 1","pos":"Vector2(0, 0)","route":{"id":"173523602912987","name":"State Name 1","type":0},"transitions":[]}],"type":"Sprite2D","var_item_list":[]}

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
		EngineDebugger.send_message('hengo:debug_state', [2])
		_STATE_CONTROLLER.change_state("state_name_1")


func _process(delta: float) -> void:
	_STATE_CONTROLLER.static_process(delta)



func _physics_process(delta: float) -> void:
	_STATE_CONTROLLER.static_physics_process(delta)








# Functions
#

# Signals Callables
class StateName1 extends HengoState:
	func enter() -> void:
		#hen_dbg#var __hen_id__: float = 0.

		_ref.get_tree().create_timer(0, false, false, false).connect("Variant", _ref.variant, 0)
		#hen_dbg#__hen_id__ += 4
		#hen_dbg#EngineDebugger.send_message('hengo:cnode', [__hen_id__])
		#hen_dbg#EngineDebugger.send_message('hengo:debug_state', [8])



