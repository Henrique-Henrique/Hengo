#[hengo] {"comments":[],"connections":[{"from_cnode":1,"input":0,"output":0,"to_cnode":13},{"from_cnode":13,"input":0,"output":0,"to_cnode":12},{"from_cnode":16,"input":0,"output":0,"to_cnode":8}],"debug_symbols":{"16":[3,"cnode"],"2":[12,"true_flow"],"32":[4],"4":[1,"cnode"],"64":[4],"8":[8,"true_flow"]},"flow_connections":[{"from_cnode":1,"from_connector":0,"to_cnode":12},{"from_cnode":12,"from_connector":0,"to_cnode":14},{"from_cnode":3,"from_connector":0,"to_cnode":8},{"from_cnode":8,"from_connector":0,"to_cnode":10}],"func_item_list":[],"generals":[{"cnode_list":[{"hash":1,"inputs":[],"name":"_input","outputs":[{"name":"event","type":"InputEvent"}],"pos":"Vector2(0, 0)","sub_type":"virtual"},{"hash":12,"inputs":[],"name":"IF","outputs":[],"pos":"Vector2(39.7792, 346.729)","sub_type":"if","type":"if"},{"hash":13,"inputs":[{"name":"InputEvent","ref":true,"type":"InputEvent"},{"category":"action","in_prop":"ui_select","name":"action","type":"@dropdown"},{"in_prop":true,"name":"allow_echo","type":"bool"},{"in_prop":false,"name":"exact_match","type":"bool"}],"name":"is_action_pressed","outputs":[{"name":"","type":"bool"}],"pos":"Vector2(-436.016, 338.308)","sub_type":"func"},{"category":"native","hash":14,"inputs":[{"in_prop":"zzz","name":"content","type":"String"}],"name":"print","outputs":[],"pos":"Vector2(53.4636, 579.363)","sub_type":"void"}],"cnode_name":"_input","name":"Input","pos":"Vector2(-120, -203)"},{"cnode_list":[{"hash":2,"inputs":[],"name":"_process","outputs":[{"name":"delta","type":"float"}],"pos":"Vector2(0, 0)","sub_type":"virtual"}],"cnode_name":"_process","color":"#401d3f","name":"Process","param":{"name":"delta","type":"float"},"pos":"Vector2(9, -205)"},{"cnode_list":[{"hash":3,"inputs":[],"name":"_physics_process","outputs":[{"name":"delta","type":"float"}],"pos":"Vector2(0, 0)","sub_type":"virtual"},{"hash":8,"inputs":[],"name":"IF","outputs":[],"pos":"Vector2(68.9903, 296.727)","sub_type":"if","type":"if"},{"category":"native","hash":10,"inputs":[{"in_prop":"xxxxxx","name":"content","type":"String"}],"name":"print","outputs":[],"pos":"Vector2(164.059, 797.215)","sub_type":"void"},{"fantasy_name":"Input -> is_action_just_pressed","hash":16,"inputs":[{"category":"action","in_prop":"ui_select","name":"action","type":"@dropdown"},{"in_prop":false,"name":"exact_match","type":"bool"}],"name":"Input.is_action_just_pressed","outputs":[{"name":"","type":"bool"}],"pos":"Vector2(-461.331, 574.048)","sub_type":"singleton"}],"cnode_name":"_physics_process","color":"#1f2950","name":"Physics Process","param":{"name":"delta","type":"float"},"pos":"Vector2(167, -200)"}],"local_var_items":[],"node_counter":16,"signal_item_list":[],"state_name_counter":1,"states":[{"cnode_list":[{"hash":5,"inputs":[],"name":"enter","outputs":[],"pos":"Vector2(0, 0)","sub_type":"virtual"},{"hash":6,"inputs":[],"name":"update","outputs":[{"name":"delta","type":"float"}],"pos":"Vector2(400, 0)","sub_type":"virtual"}],"events":[{"name":"Start","type":"start"}],"id":4,"name":"State Name 1","pos":"Vector2(0, 0)","route":{"id":"173074669228948","name":"State Name 1","type":0},"transitions":[]}],"type":"Sprite2D","var_item_list":[]}

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
		EngineDebugger.send_message('hengo:debug_state', [32])
		_STATE_CONTROLLER.change_state("state_name_1")


func _process(delta: float) -> void:
	_STATE_CONTROLLER.static_process(delta)



func _physics_process(delta: float) -> void:
	_STATE_CONTROLLER.static_physics_process(delta)
	#hen_dbg#var __hen_id__: float = 0.

	if Input.is_action_just_pressed("ui_select", false):
		print("xxxxxx")
		#hen_dbg#__hen_id__ += 8


	#hen_dbg#__hen_id__ += 16
	#hen_dbg#EngineDebugger.send_message('hengo:cnode', [__hen_id__])

func _input(event: InputEvent) -> void:
	#hen_dbg#var __hen_id__: float = 0.

	if event.is_action_pressed("ui_select", true, false):
		print("zzz")
		#hen_dbg#__hen_id__ += 2


	#hen_dbg#__hen_id__ += 4
	#hen_dbg#EngineDebugger.send_message('hengo:cnode', [__hen_id__])





#
# Functions
#

# Signals Callables
class StateName1 extends HengoState:
	func enter() -> void:
		#hen_dbg#EngineDebugger.send_message('hengo:debug_state', [64])
		pass



