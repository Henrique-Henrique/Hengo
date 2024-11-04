#[hengo] {"comments":[],"connections":[{"from_cnode":9,"input":0,"output":0,"to_cnode":8}],"debug_symbols":{"2":[4],"4":[5,"cnode"],"8":[4]},"flow_connections":[{"from_cnode":5,"from_connector":0,"to_cnode":8}],"func_item_list":[],"generals":[{"cnode_list":[{"hash":1,"inputs":[],"name":"_input","outputs":[{"name":"event","type":"InputEvent"}],"pos":"Vector2(0, 0)","sub_type":"virtual"}],"cnode_name":"_input","name":"Input","pos":"Vector2(-120, -200)"},{"cnode_list":[{"hash":2,"inputs":[],"name":"_process","outputs":[{"name":"delta","type":"float"}],"pos":"Vector2(0, 0)","sub_type":"virtual"}],"cnode_name":"_process","color":"#401d3f","name":"Process","param":{"name":"delta","type":"float"},"pos":"Vector2(9, -200)"},{"cnode_list":[{"hash":3,"inputs":[],"name":"_physics_process","outputs":[{"name":"delta","type":"float"}],"pos":"Vector2(0, 0)","sub_type":"virtual"}],"cnode_name":"_physics_process","color":"#1f2950","name":"Physics Process","param":{"name":"delta","type":"float"},"pos":"Vector2(167, -200)"}],"local_var_items":[],"node_counter":11,"signal_item_list":[],"state_name_counter":1,"states":[{"cnode_list":[{"hash":5,"inputs":[],"name":"enter","outputs":[],"pos":"Vector2(0, 0)","sub_type":"virtual"},{"hash":6,"inputs":[],"name":"update","outputs":[{"name":"delta","type":"float"}],"pos":"Vector2(400, 0)","sub_type":"virtual"},{"fantasy_name":"Input -> set_mouse_mode","hash":7,"inputs":[{"category":"enum_list","data":["set_mouse_mode","MouseMode"],"name":"mode","type":"MouseMode"}],"name":"Input.set_mouse_mode","outputs":[],"pos":"Vector2(564.923, 268.097)","sub_type":"singleton"},{"fantasy_name":"Input -> set_mouse_mode","hash":8,"inputs":[{"category":"enum_list","data":["set_mouse_mode","MouseMode"],"name":"mode","type":"MouseMode"}],"name":"Input.set_mouse_mode","outputs":[],"pos":"Vector2(162.888, 471.092)","sub_type":"singleton"},{"category":"native","hash":9,"inputs":[],"name":"Input","outputs":[{"category":"const","name":"","out_prop":"MOUSE_MODE_HIDDEN","sub_type":"@dropdown","type":"MouseMode"}],"pos":"Vector2(-328.238, 475.633)","sub_type":"const"},{"fantasy_name":"DisplayServer -> window_set_mouse_passthrough","hash":10,"inputs":[{"name":"region","type":"PackedVector2Array"},{"in_prop":0,"name":"window_id","type":"int"}],"name":"DisplayServer.window_set_mouse_passthrough","outputs":[],"pos":"Vector2(608.845, 633.647)","sub_type":"singleton"},{"fantasy_name":"Input -> set_mouse_mode","hash":11,"inputs":[{"category":"enum_list","data":["set_mouse_mode","MouseMode"],"name":"mode","type":"MouseMode"}],"name":"Input.set_mouse_mode","outputs":[],"pos":"Vector2(166.806, 727.656)","sub_type":"singleton"}],"events":[{"name":"Start","type":"start"}],"id":4,"name":"State Name 1","pos":"Vector2(0, 0)","route":{"id":"173075346766340","name":"State Name 1","type":0},"transitions":[]}],"type":"Sprite2D","var_item_list":[]}

extends Sprite2D

#
# Variables

var _STATE_CONTROLLER = HengoStateController.new()

func _init() -> void:
	_STATE_CONTROLLER.set_states({
		state_name_1 = StateName1.new(self)
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
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		#hen_dbg#__hen_id__ += 4
		#hen_dbg#EngineDebugger.send_message('hengo:cnode', [__hen_id__])
		#hen_dbg#EngineDebugger.send_message('hengo:debug_state', [8])
