#[hengo] {"comments":[],"connections":[{"from_cnode":7,"input":0,"output":0,"to_cnode":8},{"from_cnode":7,"input":1,"output":0,"to_cnode":9},{"from_cnode":9,"input":0,"output":1,"to_cnode":8},{"from_cnode":7,"input":0,"output":0,"to_cnode":10},{"from_cnode":7,"input":2,"output":0,"to_cnode":11},{"from_cnode":11,"input":0,"output":1,"to_cnode":10},{"from_cnode":18,"input":0,"output":3,"to_cnode":17},{"from_cnode":13,"input":0,"output":0,"to_cnode":19},{"from_cnode":13,"input":0,"output":0,"to_cnode":20},{"from_cnode":23,"input":0,"output":4,"to_cnode":17}],"debug_symbols":{"16":[6,"cnode"],"2":[4],"4":[5,"cnode"],"8":[4]},"flow_connections":[{"from_cnode":6,"from_connector":0,"to_cnode":8},{"from_cnode":5,"from_connector":0,"to_cnode":17}],"func_item_list":[],"generals":[{"cnode_list":[{"hash":1,"inputs":[],"name":"_input","outputs":[{"name":"event","type":"InputEvent"}],"pos":"Vector2(0, 0)","sub_type":"virtual"}],"cnode_name":"_input","name":"Input","pos":"Vector2(-120, -200)"},{"cnode_list":[{"hash":2,"inputs":[],"name":"_process","outputs":[{"name":"delta","type":"float"}],"pos":"Vector2(0, 0)","sub_type":"virtual"}],"cnode_name":"_process","color":"#401d3f","name":"Process","param":{"name":"delta","type":"float"},"pos":"Vector2(-15, -200)"},{"cnode_list":[{"hash":3,"inputs":[],"name":"_physics_process","outputs":[{"name":"delta","type":"float"}],"pos":"Vector2(0, 0)","sub_type":"virtual"}],"cnode_name":"_physics_process","color":"#1f2950","name":"Physics Process","param":{"name":"delta","type":"float"},"pos":"Vector2(109, -200)"}],"local_var_items":[],"node_counter":23,"signal_item_list":[],"state_name_counter":1,"states":[{"cnode_list":[{"hash":5,"inputs":[],"name":"enter","outputs":[],"pos":"Vector2(1202.42, 944.938)","sub_type":"virtual"},{"hash":6,"inputs":[],"name":"update","outputs":[{"name":"delta","type":"float"}],"pos":"Vector2(718.949, 141.053)","sub_type":"virtual"},{"fantasy_name":"Get Prop -> offset","hash":7,"inputs":[{"name":"Sprite2D","ref":true,"type":"Sprite2D"}],"name":"offset","outputs":[{"name":"offset","type":"Vector2"},{"name":"x","type":"float"},{"name":"y","type":"float"}],"pos":"Vector2(67.0917, 320.604)","sub_type":"get_prop"},{"fantasy_name":"Set Prop -> x","hash":8,"inputs":[{"name":"Vector2","ref":true,"type":"Vector2"},{"name":"x","type":"float"}],"name":"x","outputs":[],"pos":"Vector2(700.083, 322.609)","sub_type":"set_prop"},{"category":"plus","hash":9,"inputs":[{"name":"","type":"float"},{"in_prop":1,"name":"","type":"float"}],"name":"+","outputs":[{"name":"","type":"float"}],"pos":"Vector2(467.45, 491.031)","sub_type":"img","type":"img"},{"fantasy_name":"Set Prop -> y","hash":10,"inputs":[{"name":"Vector2","ref":true,"type":"Vector2"},{"name":"y","type":"float"}],"name":"y","outputs":[],"pos":"Vector2(704.696, 746.373)","sub_type":"set_prop"},{"category":"plus","hash":11,"inputs":[{"name":"","type":"float"},{"in_prop":1,"name":"","type":"float"}],"name":"+","outputs":[{"name":"","type":"float"}],"pos":"Vector2(471.947, 797.678)","sub_type":"img","type":"img"},{"fantasy_name":"Get Prop -> region_rect","hash":13,"inputs":[{"name":"Sprite2D","ref":true,"type":"Sprite2D"}],"name":"region_rect","outputs":[{"name":"region_rect","type":"Rect2"},{"name":"position","type":"Vector2"},{"name":"size","type":"Vector2"},{"name":"end","type":"Vector2"}],"pos":"Vector2(-138.422, 1182.31)","sub_type":"get_prop"},{"fantasy_name":"Set Prop -> region_rect","hash":17,"inputs":[{"name":"Sprite2D","ref":true,"type":"Sprite2D"},{"name":"region_rect","ref":true,"type":"Rect2"},{"in_prop":"Vector2(0, 0)","name":"position","type":"Vector2"},{"name":"size","type":"Vector2"},{"name":"end","type":"Vector2"}],"name":"region_rect","outputs":[],"pos":"Vector2(1113.66, 1109.35)","sub_type":"set_prop"},{"hash":18,"inputs":[{"name":"Sprite2D","ref":true,"type":"Sprite2D"}],"name":"get_position","outputs":[{"name":"","type":"Vector2"}],"pos":"Vector2(829.66, 1247.93)","sub_type":"func"},{"fantasy_name":"Set Prop -> size","hash":19,"inputs":[{"name":"Rect2","ref":true,"type":"Rect2"},{"in_prop":"Vector2(0, 0)","name":"size","type":"Vector2"}],"name":"size","outputs":[],"pos":"Vector2(440.649, 1179.81)","sub_type":"set_prop"},{"fantasy_name":"Set Prop -> end","hash":20,"inputs":[{"name":"Rect2","ref":true,"type":"Rect2"},{"in_prop":"Vector2(0, 0)","name":"end","type":"Vector2"}],"name":"end","outputs":[],"pos":"Vector2(436.649, 1362.81)","sub_type":"set_prop"},{"hash":23,"inputs":[{"name":"Sprite2D","ref":true,"type":"Sprite2D"}],"name":"get_global_position","outputs":[{"name":"","type":"Vector2"}],"pos":"Vector2(802.895, 1391.92)","sub_type":"func"}],"events":[{"name":"Start","type":"start"}],"id":4,"name":"State Name 1","pos":"Vector2(0, 0)","route":{"id":"17314311712244","name":"State Name 1","type":0},"transitions":[]}],"type":"Sprite2D","var_item_list":[]}

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


		_ref.region_rect.size = _ref.get_position()
		_ref.region_rect.end = _ref.get_global_position()
		#hen_dbg#__hen_id__ += 4
		#hen_dbg#EngineDebugger.send_message('hengo:cnode', [__hen_id__])
		#hen_dbg#EngineDebugger.send_message('hengo:debug_state', [8])

	func update(delta) -> void:
		#hen_dbg#var __hen_id__: float = 0.

		_ref.offset.x = _ref.offset.x + 1
		#hen_dbg#__hen_id__ += 16
		#hen_dbg#EngineDebugger.send_message('hengo:cnode', [__hen_id__])



