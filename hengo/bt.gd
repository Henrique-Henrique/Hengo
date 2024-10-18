#[hengo] {"comments":[],"connections":[{"from_cnode":9,"input":0,"output":0,"to_cnode":8},{"from_cnode":23,"input":0,"output":0,"to_cnode":24},{"from_cnode":24,"input":0,"output":0,"to_cnode":22},{"from_cnode":9,"input":0,"output":0,"to_cnode":26},{"from_cnode":26,"input":0,"output":0,"to_cnode":10},{"from_cnode":17,"input":0,"output":0,"to_cnode":16},{"from_cnode":16,"input":0,"output":0,"to_cnode":15},{"from_cnode":28,"input":0,"output":0,"to_cnode":29},{"from_cnode":29,"input":0,"output":0,"to_cnode":35},{"from_cnode":32,"input":0,"output":0,"to_cnode":34},{"from_cnode":46,"input":0,"output":0,"to_cnode":47},{"from_cnode":47,"input":0,"output":0,"to_cnode":45}],"debug_symbols":{"1024":[5,"cnode"],"128":[3,"cnode"],"16":[10,"true_flow"],"2":[1],"2048":[4],"256":[45,"true_flow"],"32":[22,"true_flow"],"4":[1],"4096":[15,"true_flow"],"512":[45,"false_flow"],"64":[10,"false_flow"],"8":[8],"8192":[6,"cnode"]},"flow_connections":[{"from_cnode":3,"from_connector":0,"to_cnode":7},{"from_cnode":7,"from_connector":0,"to_cnode":8},{"from_cnode":8,"from_connector":0,"to_cnode":10},{"from_cnode":10,"from_connector":2,"to_cnode":20},{"from_cnode":10,"from_connector":0,"to_cnode":21},{"from_cnode":20,"from_connector":0,"to_cnode":22},{"from_cnode":22,"from_connector":0,"to_cnode":25},{"from_cnode":6,"from_connector":0,"to_cnode":14},{"from_cnode":14,"from_connector":0,"to_cnode":15},{"from_cnode":15,"from_connector":0,"to_cnode":19},{"from_cnode":19,"from_connector":0,"to_cnode":18},{"from_cnode":29,"from_connector":0,"to_cnode":35},{"from_cnode":32,"from_connector":0,"to_cnode":34},{"from_cnode":5,"from_connector":0,"to_cnode":44},{"from_cnode":44,"from_connector":0,"to_cnode":45},{"from_cnode":45,"from_connector":0,"to_cnode":48},{"from_cnode":45,"from_connector":2,"to_cnode":49}],"func_item_list":[{"cnode_list":[],"id":9718403770581,"inputs":[],"instances":[{"hash":40,"id":9754357344029,"pos":"Vector2(-802.193, 2761.79)","route_inst_id":4,"sub_type":"user_func"}],"name":"my function","outputs":[],"start_data":{"input":{"id":36,"pos":"Vector2(0, 0)"},"output":{"id":37,"pos":"Vector2(0, 500)"}}}],"local_var_items":[],"node_counter":49,"signal_item_list":[{"cnode_list":[],"id":9330933964460,"instances":[{"hash":35,"id":9332175478375,"pos":"Vector2(-1729.43, 693.972)","route_inst_id":4,"sub_type":"signal_connection"},{"hash":41,"id":9762058076565,"pos":"Vector2(-404.184, 2733.79)","route_inst_id":4,"sub_type":"signal_connection"},{"hash":42,"id":9770748674519,"pos":"Vector2(-403.184, 2880.79)","route_inst_id":4,"sub_type":"signal_disconnection"},{"hash":43,"id":9781049882934,"pos":"Vector2(-401.184, 3009.79)","route_inst_id":4,"sub_type":"signal_emit"}],"name":"my timeout","params":[],"signal_data":{"object_name":"SceneTreeTimer","signal_name":"timeout"},"start_data":{"signal":{"id":30,"pos":"Vector2(0, 0)"}}}],"state_name_counter":2,"states":[{"cnode_list":[{"hash":2,"inputs":[],"name":"enter","outputs":[],"pos":"Vector2(-756, -16)","sub_type":"virtual"},{"hash":3,"inputs":[],"name":"update","outputs":[{"name":"delta","type":"float"}],"pos":"Vector2(2008.22, 53.4544)","sub_type":"virtual"},{"hash":7,"inputs":[{"name":"Sprite2D","ref":true,"type":"Sprite2D"},{"in_prop":0.03,"name":"radians","type":"float"}],"name":"rotate","outputs":[],"pos":"Vector2(1969.85, 281.134)","sub_type":"void"},{"category":"native","fantasy_name":"Debug Value","hash":8,"inputs":[{"name":"content","type":"Variant"}],"name":"","outputs":[],"pos":"Vector2(1981.85, 556.147)","sub_type":"debug_value"},{"hash":9,"inputs":[{"name":"Sprite2D","ref":true,"type":"Sprite2D"}],"name":"get_rotation","outputs":[{"name":"","type":"float"}],"pos":"Vector2(1431.67, 656.76)","sub_type":"func"},{"hash":10,"inputs":[],"name":"IF","outputs":[],"pos":"Vector2(1952.59, 1014.97)","sub_type":"if","type":"if"},{"category":"native","hash":20,"inputs":[{"in_prop":"Bigger!!!","name":"content","type":"String"}],"name":"print","outputs":[],"pos":"Vector2(2891.62, 1226.08)","sub_type":"void"},{"category":"native","hash":21,"inputs":[{"in_prop":"Less!!","name":"content","type":"String"}],"name":"print","outputs":[],"pos":"Vector2(1575.75, 1240.26)","sub_type":"void"},{"hash":22,"inputs":[],"name":"IF","outputs":[],"pos":"Vector2(2893.15, 1529.18)","sub_type":"if","type":"if"},{"hash":23,"inputs":[{"name":"Sprite2D","ref":true,"type":"Sprite2D"}],"name":"get_rotation","outputs":[{"name":"","type":"float"}],"pos":"Vector2(2360.14, 1467.18)","sub_type":"func"},{"category":"greater","hash":24,"inputs":[{"name":"","type":"float"},{"in_prop":10,"name":"","type":"float"}],"name":">","outputs":[{"name":"","type":"bool"}],"pos":"Vector2(2642.15, 1511.18)","sub_type":"img","type":"img"},{"hash":25,"inputs":[{"name":"Sprite2D","ref":true,"type":"Sprite2D"},{"in_prop":0,"name":"radians","type":"float"}],"name":"set_rotation","outputs":[],"pos":"Vector2(2589.57, 1754.48)","sub_type":"void"},{"category":"less","hash":26,"inputs":[{"name":"","type":"float"},{"in_prop":5,"name":"","type":"float"}],"name":"<","outputs":[{"name":"","type":"bool"}],"pos":"Vector2(1721.44, 995.935)","sub_type":"img","type":"img"}],"events":[{"name":"Start","type":"start"}],"id":1,"name":"Idle State","pos":"Vector2(-466.737, -224.697)","route":{"id":"172892912192428","name":"Idle State","type":0},"transitions":[{"name":"move","to_state_id":4}]},{"cnode_list":[{"hash":5,"inputs":[],"name":"enter","outputs":[],"pos":"Vector2(-2181.62, 1410.42)","sub_type":"virtual"},{"hash":6,"inputs":[],"name":"update","outputs":[{"name":"delta","type":"float"}],"pos":"Vector2(571.028, -37.0028)","sub_type":"virtual"},{"hash":14,"inputs":[{"name":"Sprite2D","ref":true,"type":"Sprite2D"},{"in_prop":0.03,"name":"radians","type":"float"}],"name":"rotate","outputs":[],"pos":"Vector2(495.794, 280.721)","sub_type":"void"},{"hash":15,"inputs":[],"name":"IF","outputs":[],"pos":"Vector2(473.734, 621.642)","sub_type":"if","type":"if"},{"category":"greater","hash":16,"inputs":[{"name":"","type":"float"},{"in_prop":5,"name":"","type":"float"}],"name":">","outputs":[{"name":"","type":"bool"}],"pos":"Vector2(225.063, 604.596)","sub_type":"img","type":"img"},{"hash":17,"inputs":[{"name":"Sprite2D","ref":true,"type":"Sprite2D"}],"name":"get_rotation","outputs":[{"name":"","type":"float"}],"pos":"Vector2(-62.7143, 343.892)","sub_type":"func"},{"category":"native","hash":18,"inputs":[{"category":"state_transition","in_prop":"stop","name":"name","type":"@dropdown"}],"name":"make_transition","outputs":[],"pos":"Vector2(159.844, 1166.41)","sub_type":"func"},{"hash":19,"inputs":[{"name":"Sprite2D","ref":true,"type":"Sprite2D"},{"in_prop":0,"name":"radians","type":"float"}],"name":"set_rotation","outputs":[],"pos":"Vector2(167.842, 845.361)","sub_type":"void"},{"hash":28,"inputs":[{"name":"Sprite2D","ref":true,"type":"Sprite2D"}],"name":"get_tree","outputs":[{"name":"","type":"SceneTree"}],"pos":"Vector2(-2593.45, 261.963)","sub_type":"func"},{"hash":29,"inputs":[{"name":"SceneTree","ref":true,"type":"SceneTree"},{"in_prop":0,"name":"time_sec","type":"float"},{"in_prop":false,"name":"process_always","type":"bool"},{"in_prop":false,"name":"process_in_physics","type":"bool"},{"in_prop":false,"name":"ignore_time_scale","type":"bool"}],"name":"create_timer","outputs":[{"name":"","type":"SceneTreeTimer"}],"pos":"Vector2(-2179.44, 265.963)","sub_type":"func"},{"hash":32,"inputs":[{"in_prop":0,"name":"start","type":"int"},{"in_prop":10,"name":"end","type":"int"},{"in_prop":1,"name":"step","type":"int"}],"name":"For -> Range","outputs":[{"name":"index","type":"int"}],"pos":"Vector2(-484.529, 1334.13)","sub_type":"for"},{"category":"native","hash":34,"inputs":[{"name":"content","type":"Variant"}],"name":"print","outputs":[],"pos":"Vector2(-151.519, 1661.14)","sub_type":"void"},{"category":"native","hash":44,"inputs":[{"in_prop":"Start!","name":"content","type":"String"}],"name":"print","outputs":[],"pos":"Vector2(-2238.33, 1563.96)","sub_type":"void"},{"hash":45,"inputs":[],"name":"IF","outputs":[],"pos":"Vector2(-2252.33, 1793.96)","sub_type":"if","type":"if"},{"hash":46,"inputs":[{"name":"Sprite2D","ref":true,"type":"Sprite2D"}],"name":"get_rotation","outputs":[{"name":"","type":"float"}],"pos":"Vector2(-2811.34, 1733.96)","sub_type":"func"},{"category":"greater","hash":47,"inputs":[{"name":"","type":"float"},{"in_prop":10,"name":"","type":"float"}],"name":">","outputs":[{"name":"","type":"bool"}],"pos":"Vector2(-2513.33, 1775.96)","sub_type":"img","type":"img"},{"category":"native","hash":48,"inputs":[{"in_prop":"Left","name":"content","type":"String"}],"name":"print","outputs":[],"pos":"Vector2(-2596.33, 2016.96)","sub_type":"void"},{"category":"native","hash":49,"inputs":[{"in_prop":"Right","name":"content","type":"String"}],"name":"print","outputs":[],"pos":"Vector2(-1855.33, 2002.96)","sub_type":"void"}],"events":[],"id":4,"name":"Moving State","pos":"Vector2(1.85634, -194.282)","route":{"id":"172892912198129","name":"Moving State","type":0},"transitions":[{"name":"stop","to_state_id":1}]}],"type":"Sprite2D","var_item_list":[{"export_var":false,"id":9712363972024,"instances":[{"hash":38,"id":9726725268571,"pos":"Vector2(-1198.2, 2760.79)","route_inst_id":4,"sub_type":"var"},{"hash":39,"id":9743351487308,"pos":"Vector2(-1199.2, 2840.79)","route_inst_id":4,"sub_type":"set_var"}],"name":"some test","type":"Variant"}]}

extends Sprite2D

#
# Variables
var some_test = null

var _STATE_CONTROLLER = HengoStateController.new()

func _init() -> void:
	_STATE_CONTROLLER.set_states({
		idle_state=IdleState.new(self, {
			move="moving_state"
		}),
		moving_state=MovingState.new(self, {
			stop="idle_state"
		})
	})


func go_to_event(_obj_ref: Node, _state_name: StringName) -> void:
	_obj_ref._STATE_CONTROLLER.change_state(_state_name)


func _ready() -> void:
	if not _STATE_CONTROLLER.current_state:
		EngineDebugger.send_message('hengo:debug_state', [2])
		_STATE_CONTROLLER.change_state("idle_state")


func _process(_delta: float) -> void:
	_STATE_CONTROLLER.static_process(_delta)


func _physics_process(_delta: float) -> void:
	_STATE_CONTROLLER.static_physics_process(_delta)

#
# Functions
func my_function():
	#hen_dbg#var __hen_id__: float = 0.
	pass

#

# Signals Callables
func _on_my_timeout_signal_():
	#hen_dbg#var __hen_id__: float = 0.
	pass

class IdleState extends HengoState:
	func enter() -> void:
		#hen_dbg#EngineDebugger.send_message('hengo:debug_state', [4])
		pass

	func update(delta) -> void:
		#hen_dbg#var __hen_id__: float = 0.

		_ref.rotate(0.03)
		#hen_dbg#EngineDebugger.send_message('hengo:debug_value', [8, var_to_str(_ref.get_rotation())])
		if _ref.get_rotation() < 5:
			print("Less!!")
			#hen_dbg#__hen_id__ += 16
		else:
			print("Bigger!!!")
			if _ref.get_rotation() > 10:
				_ref.set_rotation(0)
				#hen_dbg#__hen_id__ += 32


			#hen_dbg#__hen_id__ += 64



		#hen_dbg#__hen_id__ += 128
		#hen_dbg#EngineDebugger.send_message('hengo:cnode', [__hen_id__])



class MovingState extends HengoState:
	func enter() -> void:
		#hen_dbg#var __hen_id__: float = 0.

		print("Start!")
		if _ref.get_rotation() > 10:
			print("Left")
			#hen_dbg#__hen_id__ += 256
		else:
			print("Right")
			#hen_dbg#__hen_id__ += 512



		#hen_dbg#__hen_id__ += 1024
		#hen_dbg#EngineDebugger.send_message('hengo:cnode', [__hen_id__])
		#hen_dbg#EngineDebugger.send_message('hengo:debug_state', [2048])

	func update(delta) -> void:
		#hen_dbg#var __hen_id__: float = 0.

		_ref.rotate(0.03)
		if _ref.get_rotation() > 5:
			_ref.set_rotation(0)
			make_transition("stop")
			#hen_dbg#__hen_id__ += 4096


		#hen_dbg#__hen_id__ += 8192
		#hen_dbg#EngineDebugger.send_message('hengo:cnode', [__hen_id__])



