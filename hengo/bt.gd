#[hengo] {"comments":[],"connections":[{"from_cnode":10,"input":0,"output":0,"to_cnode":12},{"from_cnode":11,"input":0,"output":0,"to_cnode":10},{"from_cnode":13,"input":0,"output":1,"to_cnode":10}],"debug_symbols":{"2":[7],"4":[8,"cnode"],"8":[7]},"flow_connections":[{"from_cnode":8,"from_connector":0,"to_cnode":12}],"func_item_list":[],"generals":[{"cnode_list":[{"hash":2,"inputs":[],"name":"_input","outputs":[{"name":"event","type":"InputEvent"}],"pos":"Vector2(0, 0)","sub_type":"virtual"}],"cnode_name":"_input","id":1,"name":"Input","pos":"Vector2(-120, -200)"},{"cnode_list":[{"hash":4,"inputs":[],"name":"_process","outputs":[{"name":"delta","type":"float"}],"pos":"Vector2(0, 0)","sub_type":"virtual"}],"cnode_name":"_process","color":"#401d3f","id":3,"name":"Process","param":{"name":"delta","type":"float"},"pos":"Vector2(-15, -200)"},{"cnode_list":[{"hash":6,"inputs":[],"name":"_physics_process","outputs":[{"name":"delta","type":"float"}],"pos":"Vector2(0, 0)","sub_type":"virtual"}],"cnode_name":"_physics_process","color":"#1f2950","id":5,"name":"Physics Process","param":{"name":"delta","type":"float"},"pos":"Vector2(109, -200)"}],"local_var_items":[],"node_counter":13,"signal_item_list":[],"state_name_counter":1,"states":[{"cnode_list":[{"hash":8,"inputs":[],"name":"enter","outputs":[],"pos":"Vector2(186.006, 90.0027)","sub_type":"virtual"},{"hash":9,"inputs":[],"name":"update","outputs":[{"name":"delta","type":"float"}],"pos":"Vector2(800.752, 1.3807)","sub_type":"virtual"},{"category":"native","exp":"a + b / (1 - 3)","hash":10,"inputs":[{"name":"a","type":"Variant"},{"name":"b","type":"Variant"}],"name":"Expression","outputs":[{"name":"result","type":"Variant"}],"pos":"Vector2(-122.889, 193.229)","sub_type":"expression","type":"expression"},{"hash":11,"inputs":[{"name":"Sprite2D","ref":true,"type":"Sprite2D"}],"name":"get_position","outputs":[{"name":"","type":"Vector2"}],"pos":"Vector2(-394.243, 217.606)","sub_type":"func"},{"category":"native","hash":12,"inputs":[{"name":"content","type":"Variant"}],"name":"print","outputs":[],"pos":"Vector2(172.762, 220.23)","sub_type":"void"},{"hash":13,"inputs":[{"name":"Sprite2D","ref":true,"type":"Sprite2D"}],"name":"get_global_position","outputs":[{"name":"","type":"Vector2"}],"pos":"Vector2(-377.929, 358.992)","sub_type":"func"}],"events":[{"name":"Start","type":"start"}],"id":7,"name":"State Name 1","pos":"Vector2(0, 0)","route":{"id":"1732062360484135","name":"State Name 1","type":0},"transitions":[]}],"type":"Sprite2D","var_item_list":[]}

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
		EngineDebugger.send_message('hengo:debug_state', [2])
		_STATE_CONTROLLER.change_state("state_name_1")


func _process(delta: float) -> void:
	_STATE_CONTROLLER.static_process(delta)



func _physics_process(delta: float) -> void:
	_STATE_CONTROLLER.static_physics_process(delta)








#
# Functions
#

# Signals Callables
class StateName1 extends HengoState:
	func enter() -> void:
		#hen_dbg#var __hen_id__: float = 0.

		print(_ref.get_position() + _ref.get_global_position() / (1 - 3))
		#hen_dbg#__hen_id__ += 4
		#hen_dbg#EngineDebugger.send_message('hengo:cnode', [__hen_id__])
		#hen_dbg#EngineDebugger.send_message('hengo:debug_state', [8])



