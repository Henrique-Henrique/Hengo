#[hengo] {"comments":[],"connections":[{"from_cnode":4,"input":0,"output":0,"to_cnode":5},{"from_cnode":5,"input":0,"output":0,"to_cnode":34}],"debug_symbols":{"16":[1],"2":[1],"32":[3,"cnode"],"4":[12,"cnode"],"8":[2,"cnode"]},"flow_connections":[{"from_cnode":2,"from_connector":0,"to_cnode":5},{"from_cnode":3,"from_connector":0,"to_cnode":6},{"from_cnode":5,"from_connector":0,"to_cnode":34},{"from_cnode":12,"from_connector":0,"to_cnode":14},{"from_cnode":14,"from_connector":0,"to_cnode":35}],"func_item_list":[{"cnode_list":[],"id":9656713941013,"inputs":[{"name":"a","type":"Variant"},{"name":"b","type":"Variant"}],"instances":[{"hash":31,"id":9663710038267,"pos":"Vector2(1182.85, 954.3)","route_inst_id":1,"sub_type":"user_func"},{"hash":35,"id":9764507555823,"pos":"Vector2(-3.83733, 504.924)","route_inst_id":9660287487905,"sub_type":"user_func"}],"name":"my func","outputs":[{"name":"out","type":"bool"}],"start_data":{"input":{"id":9,"pos":"Vector2(0, 0)"},"output":{"id":10,"pos":"Vector2(0, 500)"}}}],"local_var_items":[],"node_counter":35,"signal_item_list":[{"cnode_list":[{"category":"native","hash":14,"inputs":[{"in_prop":"timeout!!!","name":"content","type":"String"}],"name":"print","outputs":[],"pos":"Vector2(-41.181, 217.274)","sub_type":"void"}],"id":9660287487905,"instances":[{"hash":34,"id":9667300366321,"pos":"Vector2(606.814, 788.706)","route_inst_id":1,"sub_type":"signal_connection"}],"name":"signal_2","params":[],"signal_data":{"object_name":"SceneTreeTimer","signal_name":"timeout"},"start_data":{"signal":{"id":12,"pos":"Vector2(0, 0)"}}}],"state_name_counter":1,"states":[{"cnode_list":[{"hash":2,"inputs":[],"name":"enter","outputs":[],"pos":"Vector2(48.0052, 133.012)","sub_type":"virtual"},{"hash":3,"inputs":[],"name":"update","outputs":[{"name":"delta","type":"float"}],"pos":"Vector2(1098.1, 104)","sub_type":"virtual"},{"hash":4,"inputs":[{"name":"Sprite2D","ref":true,"type":"Sprite2D"}],"name":"get_tree","outputs":[{"name":"","type":"SceneTree"}],"pos":"Vector2(-394.254, 354.273)","sub_type":"func"},{"hash":5,"inputs":[{"name":"SceneTree","ref":true,"type":"SceneTree"},{"in_prop":5,"name":"time_sec","type":"float"},{"in_prop":false,"name":"process_always","type":"bool"},{"in_prop":false,"name":"process_in_physics","type":"bool"},{"in_prop":false,"name":"ignore_time_scale","type":"bool"}],"name":"create_timer","outputs":[{"name":"","type":"SceneTreeTimer"}],"pos":"Vector2(166.77, 392.702)","sub_type":"func"},{"hash":6,"inputs":[{"name":"Sprite2D","ref":true,"type":"Sprite2D"},{"in_prop":0.01,"name":"radians","type":"float"}],"name":"rotate","outputs":[],"pos":"Vector2(1065.83, 268.274)","sub_type":"void"}],"events":[{"name":"Start","type":"start"}],"id":1,"name":"State Name 1","pos":"Vector2(-11, -193)","route":{"id":"172901597621351","name":"State Name 1","type":0},"transitions":[]}],"type":"Sprite2D","var_item_list":[{"export_var":false,"id":9659733840366,"instances":[{"hash":32,"id":9665186431457,"pos":"Vector2(1121.83, 652.279)","route_inst_id":1,"sub_type":"var"},{"hash":33,"id":9666058848467,"in_prop_data":{"0":"\"\"\"\"\"\"\"\"\"\""},"pos":"Vector2(1117.83, 728.28)","route_inst_id":1,"sub_type":"set_var"}],"name":"my var","type":"String"}]}

extends Sprite2D

#
# Variables
var my_var = String()

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


func _process(_delta: float) -> void:
	_STATE_CONTROLLER.static_process(_delta)


func _physics_process(_delta: float) -> void:
	_STATE_CONTROLLER.static_physics_process(_delta)

#
# Functions
func my_func(a, b):
	#hen_dbg#var __hen_id__: float = 0.
	return false

#

# Signals Callables
func _on_signal_2_signal_():
	#hen_dbg#var __hen_id__: float = 0.
	print("timeout!!!")
	self.my_func(null, null)
	#hen_dbg#__hen_id__ += 4

	#hen_dbg#EngineDebugger.send_message('hengo:cnode', [__hen_id__])


class StateName1 extends HengoState:
	func enter() -> void:
		#hen_dbg#var __hen_id__: float = 0.

		_ref.get_tree().create_timer(5, false, false, false)
		_ref.get_tree().create_timer(5, false, false, false).connect("timeout", _ref._on_signal_2_signal_)
		#hen_dbg#__hen_id__ += 8
		#hen_dbg#EngineDebugger.send_message('hengo:cnode', [__hen_id__])
		#hen_dbg#EngineDebugger.send_message('hengo:debug_state', [16])

	func update(delta) -> void:
		#hen_dbg#var __hen_id__: float = 0.

		_ref.rotate(0.01)
		#hen_dbg#__hen_id__ += 32
		#hen_dbg#EngineDebugger.send_message('hengo:cnode', [__hen_id__])



