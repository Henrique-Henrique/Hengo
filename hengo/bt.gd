#[hengo] {"comments":[],"connections":[{"from_cnode":14,"input":0,"output":0,"to_cnode":13},{"from_cnode":12,"input":0,"output":0,"to_cnode":10}],"debug_symbols":{"16":[7],"2":[6,"cnode"],"4":[7],"8":[8,"cnode"]},"flow_connections":[{"from_cnode":6,"from_connector":0,"to_cnode":13},{"from_cnode":8,"from_connector":0,"to_cnode":10}],"func_item_list":[],"generals":[{"cnode_list":[{"hash":2,"inputs":[],"name":"_input","outputs":[{"name":"event","type":"InputEvent"}],"pos":"Vector2(0, 0)","sub_type":"virtual"}],"cnode_name":"_input","id":1,"name":"Input","pos":"Vector2(-120, -200)"},{"cnode_list":[{"hash":4,"inputs":[],"name":"_process","outputs":[{"name":"delta","type":"float"}],"pos":"Vector2(0, 0)","sub_type":"virtual"}],"cnode_name":"_process","color":"#401d3f","id":3,"name":"Process","param":{"name":"delta","type":"float"},"pos":"Vector2(-15, -200)"},{"cnode_list":[{"hash":6,"inputs":[],"name":"_physics_process","outputs":[{"name":"delta","type":"float"}],"pos":"Vector2(0, 0)","sub_type":"virtual"},{"category":"native","hash":13,"inputs":[{"name":"content","type":"Variant"}],"name":"print","outputs":[],"pos":"Vector2(19.7836, 306.518)","sub_type":"void"},{"hash":14,"inputs":[],"name":"","outputs":[{"name":"variable_4","type":"Variant"}],"pos":"Vector2(-201.469, 336.519)","sub_type":"var","type":""}],"cnode_name":"_physics_process","color":"#1f2950","id":5,"name":"Physics Process","param":{"name":"delta","type":"float"},"pos":"Vector2(109, -200)"}],"local_var_items":[],"node_counter":14,"signal_item_list":[],"state_name_counter":1,"states":[{"cnode_list":[{"hash":8,"inputs":[],"name":"enter","outputs":[],"pos":"Vector2(0, 0)","sub_type":"virtual"},{"hash":9,"inputs":[],"name":"update","outputs":[{"name":"delta","type":"float"}],"pos":"Vector2(400, 0)","sub_type":"virtual"},{"category":"native","hash":10,"inputs":[{"name":"content","type":"Variant"}],"name":"print","outputs":[],"pos":"Vector2(-6.46677, 255.268)","sub_type":"void"}],"events":[{"name":"Start","type":"start"}],"id":7,"name":"State Name 1","pos":"Vector2(0, 0)","route":{"id":"173145552865576","name":"State Name 1","type":0},"transitions":[]}],"type":"Sprite2D","var_item_list":[{"export_var":false,"id":7086947765916,"instances":[{"hash":12,"id":7087501412590,"pos":"Vector2(-202.719, 292.768)","route_inst_id":7,"sub_type":"var"},{"hash":14,"id":7151489715520,"pos":"Vector2(-201.469, 336.519)","route_inst_id":5,"sub_type":"var"}],"name":"variable_4","type":"Variant"}]}

extends Sprite2D

#
# Variables
var variable_4 = null

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

	print(self.variable_4)
	#hen_dbg#__hen_id__ += 2
	#hen_dbg#EngineDebugger.send_message('hengo:cnode', [__hen_id__])







#
# Functions
#

# Signals Callables
class StateName1 extends HengoState:
	func enter() -> void:
		#hen_dbg#var __hen_id__: float = 0.

		print(_ref.variable_4)
		#hen_dbg#__hen_id__ += 8
		#hen_dbg#EngineDebugger.send_message('hengo:cnode', [__hen_id__])
		#hen_dbg#EngineDebugger.send_message('hengo:debug_state', [16])



