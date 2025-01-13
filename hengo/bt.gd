#[hengo] {"comments":[],"connections":[{"from_cnode":15,"input":0,"output":1,"to_cnode":14}],"debug_symbols":{"2":[7],"4":[8,"cnode"],"8":[7]},"flow_connections":[{"from_cnode":8,"from_connector":0,"to_cnode":10},{"from_cnode":10,"from_connector":0,"to_cnode":11},{"from_cnode":11,"from_connector":0,"to_cnode":14}],"func_list":[],"generals":[{"cnode_list":[{"hash":2,"inputs":[],"name":"_input","outputs":[{"name":"event","type":"InputEvent"}],"pos":"Vector2(0, 0)","sub_type":9}],"cnode_name":"_input","id":1,"name":"Input","pos":"Vector2(-120, -200)"},{"cnode_list":[{"hash":4,"inputs":[],"name":"_process","outputs":[{"name":"delta","type":"float"}],"pos":"Vector2(0, 0)","sub_type":9}],"cnode_name":"_process","color":"#401d3f","id":3,"name":"Process","param":{"name":"delta","type":"float"},"pos":"Vector2(9, -200)"},{"cnode_list":[{"hash":6,"inputs":[],"name":"_physics_process","outputs":[{"name":"delta","type":"float"}],"pos":"Vector2(0, 0)","sub_type":9}],"cnode_name":"_physics_process","color":"#1f2950","id":5,"name":"Physics Process","param":{"name":"delta","type":"float"},"pos":"Vector2(167, -200)"}],"node_counter":15,"props":[],"state_name_counter":1,"states":[{"cnode_list":[{"hash":8,"inputs":[],"name":"enter","outputs":[],"pos":"Vector2(99.2146, 90.1951)","sub_type":9},{"hash":9,"inputs":[],"name":"update","outputs":[{"name":"delta","type":"float"}],"pos":"Vector2(400, 0)","sub_type":9},{"category":"native","hash":10,"inputs":[{"name":"content","type":"Variant"}],"name":"print","outputs":[],"pos":"Vector2(42.3076, 227.418)","sub_type":1},{"hash":11,"inputs":[{"name":"Sprite2D","ref":true,"type":"Sprite2D"}],"name":"get_vframes","outputs":[{"name":"","type":"int"}],"pos":"Vector2(357.99, 429.856)","sub_type":0},{"hash":14,"inputs":[{"name":"Sprite2D","ref":true,"type":"Sprite2D"},{"name":"radians","type":"float"}],"name":"set_rotation","outputs":[],"pos":"Vector2(38.2989, 538.09)","sub_type":1},{"hash":15,"inputs":[{"name":"Sprite2D","ref":true,"type":"Sprite2D"}],"name":"get_rotation","outputs":[{"name":"","type":"float"}],"pos":"Vector2(-271.371, 583.188)","sub_type":0}],"events":[{"name":"Start","type":"start"}],"id":7,"name":"State Name 1","pos":"Vector2(0, 0)","route":{"id":"1736793746217116","name":"State Name 1","type":0},"transitions":[]}],"type":"Sprite2D"}

extends Sprite2D

# Variables #

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








# Functions
class StateName1 extends HengoState:
	func enter() -> void:
		#hen_dbg#var __hen_id__: float = 0.

		print(null)
		_ref.get_vframes()
		_ref.set_rotation(_ref.get_rotation())
		#hen_dbg#__hen_id__ += 4
		#hen_dbg#EngineDebugger.send_message('hengo:cnode', [__hen_id__])
		#hen_dbg#EngineDebugger.send_message('hengo:debug_state', [8])



