#[hengo] {"comments":[],"connections":[{"from_cnode":47,"input":0,"output":0,"to_cnode":46}],"debug_symbols":{"2":[7],"4":[8,"cnode"],"8":[7]},"flow_connections":[{"from_cnode":44,"from_connector":0,"to_cnode":45},{"from_cnode":8,"from_connector":0,"to_cnode":44},{"from_cnode":45,"from_connector":0,"to_cnode":46}],"func_item_list":[],"generals":[{"cnode_list":[{"hash":2,"inputs":[],"name":"_input","outputs":[{"name":"event","type":"InputEvent"}],"pos":"Vector2(0, 0)","sub_type":"virtual"}],"cnode_name":"_input","id":1,"name":"Input","pos":"Vector2(-120, -200)"},{"cnode_list":[{"hash":4,"inputs":[],"name":"_process","outputs":[{"name":"delta","type":"float"}],"pos":"Vector2(0, 0)","sub_type":"virtual"}],"cnode_name":"_process","color":"#401d3f","id":3,"name":"Process","param":{"name":"delta","type":"float"},"pos":"Vector2(-15, -200)"},{"cnode_list":[{"hash":6,"inputs":[],"name":"_physics_process","outputs":[{"name":"delta","type":"float"}],"pos":"Vector2(0, 0)","sub_type":"virtual"}],"cnode_name":"_physics_process","color":"#1f2950","id":5,"name":"Physics Process","param":{"name":"delta","type":"float"},"pos":"Vector2(109, -200)"}],"local_var_items":[],"node_counter":47,"props":[{"export":false,"name":"teste 133xcxz","prop_type":"VARIABLE","type":"Variant"},{"export":false,"name":"ataxxccxz","prop_type":"VARIABLE","type":"Variant"}],"signal_item_list":[],"state_name_counter":1,"states":[{"cnode_list":[{"hash":8,"inputs":[],"name":"enter","outputs":[],"pos":"Vector2(-8.34216, 226.2)","sub_type":"virtual"},{"hash":9,"inputs":[],"name":"update","outputs":[{"name":"delta","type":"float"}],"pos":"Vector2(396.364, 190.906)","sub_type":"virtual"},{"category":"native","hash":44,"inputs":[{"in_prop":"ataxxccxz","is_prop":true,"name":"content","prop_idx":"1","type":"Variant"}],"name":"print","outputs":[],"pos":"Vector2(-69.7536, 387.772)","sub_type":"void"},{"category":"native","hash":45,"inputs":[{"in_prop":"teste 133xcxz","is_prop":true,"name":"content","prop_idx":"0","type":"String"}],"name":"print","outputs":[],"pos":"Vector2(-61.5181, 552.482)","sub_type":"void"},{"category":"native","hash":46,"inputs":[{"name":"content","type":"Variant"}],"name":"print","outputs":[],"pos":"Vector2(49.073, 767.781)","sub_type":"void"},{"hash":47,"inputs":[],"name":"","outputs":[{"group_idx":0,"name":"teste 133xcxz","type":"Variant"}],"pos":"Vector2(-233.287, 743.075)","sub_type":"var","type":""}],"events":[{"name":"Start","type":"start"}],"id":7,"name":"State Name 1","pos":"Vector2(0, 0)","route":{"id":"1733759218656240","name":"State Name 1","type":0},"transitions":[]}],"type":"Sprite2D","var_item_list":[]}

extends Sprite2D

# Variables #
var teste_133_xcxz = null
var ataxxccxz = null

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

		print(_ref.ataxxccxz)
		print(_ref.teste_133_xcxz)
		print(_ref.teste_133_xcxz)
		#hen_dbg#__hen_id__ += 4
		#hen_dbg#EngineDebugger.send_message('hengo:cnode', [__hen_id__])
		#hen_dbg#EngineDebugger.send_message('hengo:debug_state', [8])



