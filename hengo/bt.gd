#[hengo] {"comments":[],"connections":[{"from_cnode":23,"input":0,"output":0,"to_cnode":24},{"from_cnode":24,"input":0,"output":0,"to_cnode":27}],"debug_symbols":{"16":[7],"2":[7],"32":[19],"4":[16,"cnode"],"8":[8,"cnode"]},"flow_connections":[{"from_cnode":16,"from_connector":0,"to_cnode":26},{"from_cnode":8,"from_connector":0,"to_cnode":27}],"func_item_list":[],"func_list":[{"cnode_list":[{"group":"f_15","hash":16,"inputs":[],"name":"input","outputs":[],"pos":"Vector2(0, 0)","sub_type":"func_input"},{"group":"f_15","hash":17,"inputs":[],"name":"output","outputs":[],"pos":"Vector2(0, 500)","sub_type":"func_output"},{"category":"native","hash":26,"inputs":[{"in_prop":"HYOL!!","name":"content","type":"String"}],"name":"print","outputs":[],"pos":"Vector2(-79.7491, 149.669)","sub_type":"void"}],"hash":15,"pos":"Vector2(357.519, -13.1467)","props":[{"name":"name","type":"String","value":"func_name"},{"name":"inputs","type":"in_out","value":[]},{"name":"outputs","type":"in_out","value":[]}],"ref_count":0}],"generals":[{"cnode_list":[{"hash":2,"inputs":[],"name":"_input","outputs":[{"name":"event","type":"InputEvent"}],"pos":"Vector2(0, 0)","sub_type":"virtual"}],"cnode_name":"_input","id":1,"name":"Input","pos":"Vector2(-120, -200)"},{"cnode_list":[{"hash":4,"inputs":[],"name":"_process","outputs":[{"name":"delta","type":"float"}],"pos":"Vector2(0, 0)","sub_type":"virtual"}],"cnode_name":"_process","color":"#401d3f","id":3,"name":"Process","param":{"name":"delta","type":"float"},"pos":"Vector2(9, -200)"},{"cnode_list":[{"hash":6,"inputs":[],"name":"_physics_process","outputs":[{"name":"delta","type":"float"}],"pos":"Vector2(0, 0)","sub_type":"virtual"}],"cnode_name":"_physics_process","color":"#1f2950","id":5,"name":"Physics Process","param":{"name":"delta","type":"float"},"pos":"Vector2(167, -200)"}],"local_var_items":[],"node_counter":27,"props":[],"signal_item_list":[],"state_name_counter":2,"states":[{"cnode_list":[{"hash":8,"inputs":[],"name":"enter","outputs":[],"pos":"Vector2(183.019, 46.0048)","sub_type":"virtual"},{"hash":9,"inputs":[],"name":"update","outputs":[{"name":"delta","type":"float"}],"pos":"Vector2(400, 0)","sub_type":"virtual"},{"hash":23,"inputs":[{"name":"Sprite2D","ref":true,"type":"Sprite2D"}],"name":"get_tree","outputs":[{"name":"","type":"SceneTree"}],"pos":"Vector2(-695.814, 302.686)","sub_type":"func"},{"hash":24,"inputs":[{"name":"SceneTree","ref":true,"type":"SceneTree"},{"in_prop":3,"name":"time_sec","type":"float"},{"in_prop":false,"name":"process_always","type":"bool"},{"in_prop":false,"name":"process_in_physics","type":"bool"},{"in_prop":false,"name":"ignore_time_scale","type":"bool"}],"name":"create_timer","outputs":[{"name":"","type":"SceneTreeTimer"}],"pos":"Vector2(-383.781, 300.685)","sub_type":"func"},{"hash":27,"inputs":[{"name":"SceneTreeTimer","ref":true,"type":"SceneTreeTimer"},{"category":"signal","data":"SceneTreeTimer","in_prop":"timeout","name":"signal","sub_type":"@dropdown","type":"StringName"},{"category":"callable","in_prop":"func_name","name":"callable","sub_type":"@dropdown","type":"Callable"},{"in_prop":0,"name":"flags","type":"int"}],"name":"connect","outputs":[{"name":"","type":"int"}],"pos":"Vector2(83.1505, 297.951)","sub_type":"func"}],"events":[{"name":"Start","type":"start"}],"id":7,"name":"State Name 1","pos":"Vector2(0, -2)","route":{"id":"173523317626932","name":"State Name 1","type":0},"transitions":[{"name":"Transition 0","to_state_id":19}]},{"cnode_list":[{"hash":20,"inputs":[],"name":"enter","outputs":[],"pos":"Vector2(0, 0)","sub_type":"virtual"},{"hash":21,"inputs":[],"name":"update","outputs":[{"name":"delta","type":"float"}],"pos":"Vector2(400, 0)","sub_type":"virtual"},{"category":"native","hash":22,"inputs":[{"category":"state_transition","in_prop":"Variant","name":"name","sub_type":"@dropdown","type":"Variant"}],"name":"make_transition","outputs":[],"pos":"Vector2(-228.765, 267.682)","sub_type":"func"}],"events":[],"id":19,"name":"State Name 2","pos":"Vector2(286, 292)","route":{"id":"173523317630833","name":"State Name 2","type":0},"transitions":[]}],"type":"Sprite2D","var_item_list":[]}

extends Sprite2D

# Variables #

var _STATE_CONTROLLER = HengoStateController.new()

func _init() -> void:
	_STATE_CONTROLLER.set_states({
		state_name_1=StateName1.new(self, {
			transition_0="state_name_2"
		}),
		state_name_2=StateName2.new(self)
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
	print("HYOL!!")
	#hen_dbg#__hen_id__ += 4
	#hen_dbg#EngineDebugger.send_message('hengo:cnode', [__hen_id__])
#

# Signals Callables
class StateName1 extends HengoState:
	func enter() -> void:
		#hen_dbg#var __hen_id__: float = 0.

		_ref.get_tree().create_timer(3, false, false, false).connect("timeout", _ref.func_name, 0)
		#hen_dbg#__hen_id__ += 8
		#hen_dbg#EngineDebugger.send_message('hengo:cnode', [__hen_id__])
		#hen_dbg#EngineDebugger.send_message('hengo:debug_state', [16])



class StateName2 extends HengoState:
	func enter() -> void:
		#hen_dbg#EngineDebugger.send_message('hengo:debug_state', [32])
		pass



