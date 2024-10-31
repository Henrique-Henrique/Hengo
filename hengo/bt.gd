#[hengo] {"comments":[],"connections":[{"from_cnode":20,"input":0,"output":0,"to_cnode":9},{"from_cnode":21,"input":0,"output":1,"to_cnode":23}],"debug_symbols":{"2":[4],"4":[5,"cnode"],"8":[4]},"flow_connections":[{"from_cnode":5,"from_connector":0,"to_cnode":9}],"func_item_list":[],"generals":[{"cnode_list":[{"hash":1,"inputs":[],"name":"_input","outputs":[{"name":"event","type":"InputEvent"}],"pos":"Vector2(0, 0)","sub_type":"virtual"}],"cnode_name":"_input","name":"Input","pos":"Vector2(-120, -200)"},{"cnode_list":[{"hash":2,"inputs":[],"name":"_process","outputs":[{"name":"delta","type":"float"}],"pos":"Vector2(0, 0)","sub_type":"virtual"}],"cnode_name":"_process","color":"#401d3f","name":"Process","param":{"name":"delta","type":"float"},"pos":"Vector2(9, -200)"},{"cnode_list":[{"hash":3,"inputs":[],"name":"_physics_process","outputs":[{"name":"delta","type":"float"}],"pos":"Vector2(0, 0)","sub_type":"virtual"}],"cnode_name":"_physics_process","color":"#1f2950","name":"Physics Process","param":{"name":"delta","type":"float"},"pos":"Vector2(167, -200)"}],"local_var_items":[],"node_counter":23,"signal_item_list":[],"state_name_counter":1,"states":[{"cnode_list":[{"hash":5,"inputs":[],"name":"enter","outputs":[],"pos":"Vector2(0, 0)","sub_type":"virtual"},{"hash":6,"inputs":[],"name":"update","outputs":[{"name":"delta","type":"float"}],"pos":"Vector2(400, 0)","sub_type":"virtual"},{"category":"native","hash":7,"inputs":[],"name":"Vector2","outputs":[{"category":"const","name":"to","out_prop":"Node","sub_type":"@dropdown","type":"Variant"}],"pos":"Vector2(-598.661, -1.48157)","sub_type":"const"},{"category":"native","hash":8,"inputs":[],"name":"Vector2","outputs":[{"category":"const","name":"to","out_prop":"RIGHT","sub_type":"@dropdown","type":"Vector2"}],"pos":"Vector2(-528.682, 615.585)","sub_type":"const"},{"category":"native","hash":9,"inputs":[{"name":"content","type":"Variant"}],"name":"print","outputs":[],"pos":"Vector2(-13.0279, 329.041)","sub_type":"void"},{"category":"native","hash":10,"inputs":[],"name":"Projection","outputs":[{"category":"const","name":"to","out_prop":"PLANE_FAR","sub_type":"@dropdown","type":"int"}],"pos":"Vector2(-505.048, 785.07)","sub_type":"const"},{"category":"native","hash":12,"inputs":[],"name":"Vector2","outputs":[{"category":"const","name":"to","out_prop":"AXIS_X","sub_type":"@dropdown","type":"int"}],"pos":"Vector2(-502.941, 945.791)","sub_type":"const"},{"category":"native","hash":13,"inputs":[],"name":"Vector2","outputs":[{"category":"const","name":"to","out_prop":"AXIS_X","sub_type":"@dropdown","type":"int"}],"pos":"Vector2(130.088, 494.871)","sub_type":"const"},{"category":"native","hash":14,"inputs":[],"name":"Quaternion","outputs":[{"category":"const","name":"to","out_prop":"IDENTITY","sub_type":"@dropdown","type":"Quaternion"}],"pos":"Vector2(-511.768, 392.864)","sub_type":"const"},{"hash":15,"inputs":[{"name":"Sprite2D","ref":true,"type":"Sprite2D"},{"name":"event","type":"InputEvent"}],"name":"make_input_local","outputs":[{"name":"","type":"InputEvent"}],"pos":"Vector2(308.59, 739.741)","sub_type":"func"},{"category":"native","hash":16,"inputs":[],"name":"Input","outputs":[{"category":"const","name":"to","out_prop":"CURSOR_ARROW","sub_type":"@dropdown","type":"int"}],"pos":"Vector2(-524.058, 1122.04)","sub_type":"const"},{"category":"native","hash":17,"inputs":[],"name":"Input","outputs":[{"category":"const","name":"to","out_prop":"MOUSE_MODE_CONFINED_HIDDEN","sub_type":"@dropdown","type":"int"}],"pos":"Vector2(-498.987, 1252.69)","sub_type":"const"},{"category":"native","hash":18,"inputs":[],"name":"InputEvent","outputs":[{"category":"const","name":"to","out_prop":"DEVICE_ID_EMULATION","sub_type":"@dropdown","type":"Variant"}],"pos":"Vector2(-494.344, 1426.47)","sub_type":"const"},{"category":"native","hash":19,"inputs":[],"name":"FileAccess","outputs":[{"category":"const","name":"to","out_prop":"COMPRESSION_ZSTD","sub_type":"@dropdown","type":"int"}],"pos":"Vector2(-63.4195, 1131.64)","sub_type":"const"},{"category":"native","hash":20,"inputs":[],"name":"AnimationNodeOneShot","outputs":[{"category":"const","name":"to","out_prop":"MIX_MODE_ADD","sub_type":"@dropdown","type":"int"}],"pos":"Vector2(-500.712, 212.287)","sub_type":"const"},{"category":"native","hash":21,"inputs":[],"name":"Vector2","outputs":[{"category":"const","name":"to","out_prop":"INF","sub_type":"@dropdown","type":"Vector2"}],"pos":"Vector2(-257.697, 583.307)","sub_type":"const"},{"hash":22,"inputs":[{"name":"Sprite2D","ref":true,"type":"Sprite2D"},{"in_prop":false,"name":"flip_v","type":"bool"}],"name":"set_flip_v","outputs":[],"pos":"Vector2(19.3048, 578.308)","sub_type":"void"},{"hash":23,"inputs":[{"name":"Sprite2D","ref":true,"type":"Sprite2D"},{"name":"scale","type":"Vector2"}],"name":"set_scale","outputs":[],"pos":"Vector2(-3.69533, 837.31)","sub_type":"void"}],"events":[{"name":"Start","type":"start"}],"id":4,"name":"State Name 1","pos":"Vector2(0, 0)","route":{"id":"17304061896928","name":"State Name 1","type":0},"transitions":[]}],"type":"Sprite2D","var_item_list":[]}

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

		print(AnimationNodeOneShot.MIX_MODE_ADD)
		#hen_dbg#__hen_id__ += 4
		#hen_dbg#EngineDebugger.send_message('hengo:cnode', [__hen_id__])
		#hen_dbg#EngineDebugger.send_message('hengo:debug_state', [8])



