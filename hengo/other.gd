#[hengo] {"comments":[],"connections":[],"debug_symbols":{"2":[1],"4":[2,"cnode"],"8":[1]},"flow_connections":[{"from_cnode":2,"from_connector":0,"to_cnode":4}],"func_item_list":[],"local_var_items":[],"node_counter":4,"signal_item_list":[],"state_name_counter":1,"states":[{"cnode_list":[{"hash":2,"inputs":[],"name":"enter","outputs":[],"pos":"Vector2(0, 0)","sub_type":"virtual"},{"hash":3,"inputs":[],"name":"update","outputs":[{"name":"delta","type":"float"}],"pos":"Vector2(384, -97)","sub_type":"virtual"},{"category":"native","hash":4,"inputs":[{"in_prop":"dsadas","name":"content","type":"String"}],"name":"print","outputs":[],"pos":"Vector2(45.409, 299.242)","sub_type":"void"}],"events":[{"name":"Start","type":"start"}],"id":1,"name":"State Name 1","pos":"Vector2(0, 0)","route":{"id":"172979924474715","name":"State Name 1","type":0},"transitions":[]}],"type":"Sprite2D","var_item_list":[]}

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


func _process(_delta: float) -> void:
	_STATE_CONTROLLER.static_process(_delta)


func _physics_process(_delta: float) -> void:
	_STATE_CONTROLLER.static_physics_process(_delta)

#
# Functions
#

# Signals Callables
class StateName1 extends HengoState:
	func enter() -> void:
		#hen_dbg#var __hen_id__: float = 0.

		print("dsadas")
		#hen_dbg#__hen_id__ += 4
		#hen_dbg#EngineDebugger.send_message('hengo:cnode', [__hen_id__])
		#hen_dbg#EngineDebugger.send_message('hengo:debug_state', [8])



