#[hengo] {"comments":[{"cnode_inside_ids":[14,15],"color":"Color(0.188998, 0.187807, 0.177515, 1)","comment":"COMMENT","id":4686195262876,"is_pinned":true,"pos":"Vector2(-324.016, 160.05)","router_ref_id":6,"size":"Vector2(508.984, 230.358)"},{"cnode_inside_ids":[10,11],"color":"Color(0.188998, 0.187807, 0.177515, 1)","comment":"COMMENT","id":4613935794118,"is_pinned":true,"pos":"Vector2(-283.021, 142.497)","router_ref_id":8,"size":"Vector2(459.181, 192.211)"}],"connections":[{"from_cnode":15,"input":0,"output":0,"to_cnode":14},{"from_cnode":11,"input":0,"output":0,"to_cnode":10}],"debug_symbols":{"16":[7],"2":[6,"cnode"],"4":[7],"8":[8,"cnode"]},"flow_connections":[{"from_cnode":6,"from_connector":0,"to_cnode":14},{"from_cnode":8,"from_connector":0,"to_cnode":10}],"func_item_list":[],"generals":[{"cnode_list":[{"hash":2,"inputs":[],"name":"_input","outputs":[{"name":"event","type":"InputEvent"}],"pos":"Vector2(0, 0)","sub_type":"virtual"}],"cnode_name":"_input","id":1,"name":"Input","pos":"Vector2(-120, -200)"},{"cnode_list":[{"hash":4,"inputs":[],"name":"_process","outputs":[{"name":"delta","type":"float"}],"pos":"Vector2(0, 0)","sub_type":"virtual"}],"cnode_name":"_process","color":"#401d3f","id":3,"name":"Process","param":{"name":"delta","type":"float"},"pos":"Vector2(-15, -200)"},{"cnode_list":[{"hash":6,"inputs":[],"name":"_physics_process","outputs":[{"name":"delta","type":"float"}],"pos":"Vector2(0, 0)","sub_type":"virtual"},{"category":"native","hash":14,"inputs":[{"name":"content","type":"Variant"}],"name":"print","outputs":[],"pos":"Vector2(28.9685, 234.05)","sub_type":"void"},{"hash":15,"inputs":[{"name":"Sprite2D","ref":true,"type":"Sprite2D"}],"name":"get_frame","outputs":[{"name":"","type":"int"}],"pos":"Vector2(-284.016, 276.408)","sub_type":"func"}],"cnode_name":"_physics_process","color":"#1f2950","id":5,"name":"Physics Process","param":{"name":"delta","type":"float"},"pos":"Vector2(113.064, -187.806)"}],"local_var_items":[],"node_counter":15,"signal_item_list":[],"state_name_counter":1,"states":[{"cnode_list":[{"hash":8,"inputs":[],"name":"enter","outputs":[],"pos":"Vector2(18.9491, 18.9491)","sub_type":"virtual"},{"hash":9,"inputs":[],"name":"update","outputs":[{"name":"delta","type":"float"}],"pos":"Vector2(400, 0)","sub_type":"virtual"},{"category":"native","hash":10,"inputs":[{"name":"content","type":"Variant"}],"name":"print","outputs":[],"pos":"Vector2(20.1601, 216.497)","sub_type":"void"},{"hash":11,"inputs":[{"name":"Sprite2D","ref":true,"type":"Sprite2D"}],"name":"get_position","outputs":[{"name":"","type":"Vector2"}],"pos":"Vector2(-243.021, 220.708)","sub_type":"func"}],"events":[{"name":"Start","type":"start"}],"id":7,"name":"State Name 1","pos":"Vector2(-8.12949, 48.7771)","route":{"id":"173213195514444","name":"State Name 1","type":0},"transitions":[]}],"type":"Sprite2D","var_item_list":[]}

extends Sprite2D

#
# Variables

var _STATE_CONTROLLER = HengoStateController.new()

func _init() -> void:
	_STATE_CONTROLLER.set_states({
		state_name_1=StateName1.new(self)
	})


func go_to_event(_obj_ref: Node, _state_name: StringName) -> void:
	_obj_ref._STATE_CONTROLLER.change_state(_state_name)


func _ready() -> void:
	if not _STATE_CONTROLLER.current_state:
		EngineDebugger.send_message('hengo:debug_state', [4])
		_STATE_CONTROLLER.change_state("state_name_1")


func _process(delta: float) -> void:
	_STATE_CONTROLLER.static_process(delta)



func _physics_process(delta: float) -> void:
	_STATE_CONTROLLER.static_physics_process(delta)
	#hen_dbg#var __hen_id__: float = 0.

	print(self.get_frame())
	#hen_dbg#__hen_id__ += 2
	#hen_dbg#EngineDebugger.send_message('hengo:cnode', [__hen_id__])







#
# Functions
#

# Signals Callables
class StateName1 extends HengoState:
	func enter() -> void:
		#hen_dbg#var __hen_id__: float = 0.

		print(_ref.get_position())
		#hen_dbg#__hen_id__ += 8
		#hen_dbg#EngineDebugger.send_message('hengo:cnode', [__hen_id__])
		#hen_dbg#EngineDebugger.send_message('hengo:debug_state', [16])



