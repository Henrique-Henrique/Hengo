#[hengo] {"comments":[],"connections":[],"debug_symbols":{"2":[7],"4":[7],"8":[17]},"flow_connections":[],"func_item_list":[],"func_list":[{"cnode_list":[{"group":"f_10","hash":11,"inputs":[],"name":"input","outputs":[{"name":"cxz","type":"Variant"}],"pos":"Vector2(0, 0)","sub_type":"func_input"},{"group":"f_10","hash":12,"inputs":[{"name":"cxz","type":"Variant"}],"name":"output","outputs":[],"pos":"Vector2(0, 500)","sub_type":"func_output"}],"hash":10,"pos":"Vector2(293.107, -209.558)","props":[{"name":"name","type":"String","value":"my function"},{"name":"inputs","type":"in_out","value":[{"group":"fi_10_0","name":"cxz"}]},{"name":"outputs","type":"in_out","value":[{"group":"fo_10_0","name":"cxz"}]}],"ref_count":2},{"cnode_list":[{"group":"f_14","hash":15,"inputs":[],"name":"input","outputs":[],"pos":"Vector2(0, 0)","sub_type":"func_input"},{"group":"f_14","hash":16,"inputs":[],"name":"output","outputs":[],"pos":"Vector2(0, 500)","sub_type":"func_output"}],"hash":14,"pos":"Vector2(289.111, -143.875)","props":[{"name":"name","type":"String","value":"other function"},{"name":"inputs","type":"in_out","value":[]},{"name":"outputs","type":"in_out","value":[]}],"ref_count":0}],"generals":[{"cnode_list":[{"hash":2,"inputs":[],"name":"_input","outputs":[{"name":"event","type":"InputEvent"}],"pos":"Vector2(0, 0)","sub_type":"virtual"}],"cnode_name":"_input","id":1,"name":"Input","pos":"Vector2(-120, -200)"},{"cnode_list":[{"hash":4,"inputs":[],"name":"_process","outputs":[{"name":"delta","type":"float"}],"pos":"Vector2(0, 0)","sub_type":"virtual"}],"cnode_name":"_process","color":"#401d3f","id":3,"name":"Process","param":{"name":"delta","type":"float"},"pos":"Vector2(-119, -141)"},{"cnode_list":[{"hash":6,"inputs":[],"name":"_physics_process","outputs":[{"name":"delta","type":"float"}],"pos":"Vector2(0, 0)","sub_type":"virtual"}],"cnode_name":"_physics_process","color":"#1f2950","id":5,"name":"Physics Process","param":{"name":"delta","type":"float"},"pos":"Vector2(-120, -76)"}],"local_var_items":[],"node_counter":20,"props":[{"export":false,"name":"myvar","prop_type":"VARIABLE","type":"Variant"},{"export":false,"name":"s","prop_type":"VARIABLE","type":"Variant"},{"export":false,"name":"v","prop_type":"VARIABLE","type":"Variant"},{"export":false,"name":"d","prop_type":"VARIABLE","type":"Variant"}],"signal_item_list":[],"state_name_counter":2,"states":[{"cnode_list":[{"hash":8,"inputs":[],"name":"enter","outputs":[],"pos":"Vector2(0, 0)","sub_type":"virtual"},{"hash":9,"inputs":[],"name":"update","outputs":[{"name":"delta","type":"float"}],"pos":"Vector2(400, 0)","sub_type":"virtual"},{"fantasy_name":"Func -> func_name","group":"f_10","hash":13,"inputs":[{"name":"cxz","type":"Variant"}],"name":"func_name","outputs":[{"name":"cxz","type":"Variant"}],"pos":"Vector2(145, 392)","sub_type":"user_func"}],"events":[{"name":"Start","type":"start"}],"id":7,"name":"State Name 1","pos":"Vector2(150, 205.001)","route":{"id":"173471000995692","name":"State Name 1","type":0},"transitions":[]},{"cnode_list":[{"hash":18,"inputs":[],"name":"enter","outputs":[],"pos":"Vector2(0, 0)","sub_type":"virtual"},{"hash":19,"inputs":[],"name":"update","outputs":[{"name":"delta","type":"float"}],"pos":"Vector2(400, 0)","sub_type":"virtual"},{"fantasy_name":"Func -> my function","group":"f_10","hash":20,"inputs":[{"name":"cxz","type":"Variant"}],"name":"my function","outputs":[{"name":"cxz","type":"Variant"}],"pos":"Vector2(-697.877, 218.092)","sub_type":"user_func"}],"events":[],"id":17,"name":"State Name 2","pos":"Vector2(407, 538)","route":{"id":"173471004526693","name":"State Name 2","type":0},"transitions":[]}],"type":"Sprite2D","var_item_list":[]}

extends Sprite2D

# Variables #
var myvar = null
var s = null
var v = null
var d = null

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
		EngineDebugger.send_message('hengo:debug_state', [2])
		_STATE_CONTROLLER.change_state("state_name_1")


func _process(delta: float) -> void:
	_STATE_CONTROLLER.static_process(delta)



func _physics_process(delta: float) -> void:
	_STATE_CONTROLLER.static_physics_process(delta)








# Functions
func my_function(cxz):
	#hen_dbg#var __hen_id__: float = 0.
	return null

func other_function():
	#hen_dbg#var __hen_id__: float = 0.
	pass

#

# Signals Callables
class StateName1 extends HengoState:
	func enter() -> void:
		#hen_dbg#EngineDebugger.send_message('hengo:debug_state', [4])
		pass



class StateName2 extends HengoState:
	func enter() -> void:
		#hen_dbg#EngineDebugger.send_message('hengo:debug_state', [8])
		pass



