#[hengo] {"comments":[],"connections":[],"debug_symbols":{"16":[49],"2":[6,"cnode"],"4":[7],"8":[7]},"flow_connections":[{"from_cnode":6,"from_connector":0,"to_cnode":48}],"func_item_list":[],"generals":[{"cnode_list":[{"hash":2,"inputs":[],"name":"_input","outputs":[{"name":"event","type":"InputEvent"}],"pos":"Vector2(0, 0)","sub_type":"virtual"}],"cnode_name":"_input","id":1,"name":"Input","pos":"Vector2(-120, -201)"},{"cnode_list":[{"hash":4,"inputs":[],"name":"_process","outputs":[{"name":"delta","type":"float"}],"pos":"Vector2(0, 0)","sub_type":"virtual"}],"cnode_name":"_process","color":"#401d3f","id":3,"name":"Process","param":{"name":"delta","type":"float"},"pos":"Vector2(-126.013, -137.993)"},{"cnode_list":[{"hash":6,"inputs":[],"name":"_physics_process","outputs":[{"name":"delta","type":"float"}],"pos":"Vector2(0, 0)","sub_type":"virtual"},{"category":"native","hash":48,"inputs":[{"in_prop":"cccc","name":"content","type":"String"}],"name":"print","outputs":[],"pos":"Vector2(-6.86002, 184.295)","sub_type":"void"}],"cnode_name":"_physics_process","color":"#1f2950","id":5,"name":"Physics Process","param":{"name":"delta","type":"float"},"pos":"Vector2(-15.0142, -199)"}],"local_var_items":[],"node_counter":57,"props":[{"export":false,"name":"novo","prop_type":"VARIABLE","type":"String"},{"export":false,"name":"ahaha","prop_type":"VARIABLE","type":"Variant"}],"signal_item_list":[],"state_name_counter":2,"states":[{"cnode_list":[{"hash":8,"inputs":[],"name":"enter","outputs":[],"pos":"Vector2(-2.18843, 200.047)","sub_type":"virtual"},{"hash":9,"inputs":[],"name":"update","outputs":[{"name":"delta","type":"float"}],"pos":"Vector2(600.976, 201.675)","sub_type":"virtual"},{"hash":57,"inputs":[{"in_prop":"","name":"xxx","type":"String"},{"in_prop":false,"name":"ata","type":"bool"},{"name":"dsa","type":"Vector3"}],"name":"Func -> name","outputs":[],"pos":"Vector2(127.218, 475.584)","sub_type":"user_func"}],"events":[{"name":"Start","type":"start"}],"id":7,"name":"State Name 1","pos":"Vector2(-6.31064, 91.0141)","route":{"id":"173413037978259","name":"State Name 1","type":0},"transitions":[]},{"cnode_list":[{"hash":50,"inputs":[],"name":"enter","outputs":[],"pos":"Vector2(0, 0)","sub_type":"virtual"},{"hash":51,"inputs":[],"name":"update","outputs":[{"name":"delta","type":"float"}],"pos":"Vector2(400, 0)","sub_type":"virtual"},{"category":"native","hash":52,"inputs":[{"in_prop":"novo","is_prop":true,"name":"content","prop_idx":"0","type":"String"}],"name":"print","outputs":[],"pos":"Vector2(-64.9086, 321.327)","sub_type":"void"}],"events":[],"id":49,"name":"State Name 2","pos":"Vector2(163.92, 311.389)","route":{"id":"17341303797960","name":"State Name 2","type":0},"transitions":[]}],"type":"Sprite2D","var_item_list":[]}

extends Sprite2D

# Variables #
var novo = String()
var ahaha = null

var _STATE_CONTROLLER = HengoStateController.new()

func _init() -> void:
	_STATE_CONTROLLER.set_states({
		state_name_1=StateName1.new(self),
		state_name_2=StateName2.new(self)
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

	print("cccc")
	#hen_dbg#__hen_id__ += 2
	#hen_dbg#EngineDebugger.send_message('hengo:cnode', [__hen_id__])







#
# Functions
#

# Signals Callables
class StateName1 extends HengoState:
	func enter() -> void:
		#hen_dbg#EngineDebugger.send_message('hengo:debug_state', [8])
		pass



class StateName2 extends HengoState:
	func enter() -> void:
		#hen_dbg#EngineDebugger.send_message('hengo:debug_state', [16])
		pass



