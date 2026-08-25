extends HenActionTestSuite

# covers the ref slot every action that acts on a node opens with: unbound it is
# the node the script sits on, bound it is whatever node was handed to it.

const FIX_COLOR: String = 'res://addons/hengo/actions/render/change_color.gd'
const FIX_GET_NODE: String = 'res://addons/hengo/actions/scene/get_node.gd'


func _node_var(_name: String, _type: String) -> HenSaveVar:
	var node_var: HenSaveVar = save_data.add_var(false)

	node_var.name = _name
	node_var.type = _type

	return node_var


# --- unbound: the node the script sits on ------------------------------------


func test_an_unbound_ref_acts_on_the_owner() -> void:
	_add_action(_register(FIX_COLOR), &'update')

	assert_str(HenTest.get_all_code()).contains('_ref.modulate = Color(')


# nothing to bind means nothing to report: the action is emitted, not skipped
func test_an_unbound_ref_never_skips_the_action() -> void:
	_add_action(_register(FIX_COLOR), &'update')

	assert_array(HenGeneratorAction.collect_errors(save_data)).is_empty()


# --- bound: another node -----------------------------------------------------


func test_a_bound_ref_acts_on_the_bound_node() -> void:
	_node_var('mesh_ref', 'Node')

	var action: HenSaveAction = _add_action(_register(FIX_COLOR), &'update')

	action.input_bindings['ref'] = 'mesh_ref'

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('_ref.mesh_ref.modulate = Color(')
	assert_str(code).not_contains('\n\t\t_ref.modulate')


# a ref typed narrower than the script picks the side its own class needs, so a
# mesh handed to a 2d script is still painted through its material
func test_a_typed_ref_drives_the_dispatch() -> void:
	_node_var('hit_mesh', 'MeshInstance3D')

	var action: HenSaveAction = _add_action(_register(FIX_COLOR), &'update')

	action.input_bindings['ref'] = 'hit_mesh'

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('albedo_color = Color(')
	assert_str(code).not_contains('.modulate = Color(')


# Node says nothing about the dimension, so the script keeps deciding
func test_an_untyped_ref_leaves_the_dispatch_to_the_script() -> void:
	save_data.identity.type = 'Node3D'
	_node_var('hit_node', 'Node')

	var action: HenSaveAction = _add_action(_register(FIX_COLOR), &'update')

	action.input_bindings['ref'] = 'hit_node'

	assert_str(HenTest.get_all_code()).contains('albedo_color = Color(')


func test_a_bound_ref_compiles() -> void:
	_node_var('hit_mesh', 'MeshInstance3D')

	var action: HenSaveAction = _add_action(_register(FIX_COLOR), &'update')

	action.input_bindings['ref'] = 'hit_mesh'

	var script := GDScript.new()
	script.source_code = HenTest.get_all_code()

	assert_int(script.reload()).is_equal(OK)


# --- a lookup starts from the ref too ----------------------------------------


func test_get_node_starts_from_the_owner_by_default() -> void:
	var action: HenSaveAction = _add_action(_register(FIX_GET_NODE), &'enter')

	action.output_bindings['result'] = HenUtils.bind_code_for_var(_node_var('found', 'Node'))

	assert_str(HenTest.get_all_code()).contains('_ref.get_node_or_null(')


# reaching a child of the node a raycast returned is the whole point of the slot
func test_get_node_starts_from_the_bound_node() -> void:
	_node_var('hit_body', 'Node')

	var action: HenSaveAction = _add_action(_register(FIX_GET_NODE), &'enter')

	action.input_bindings['ref'] = 'hit_body'
	action.output_bindings['result'] = HenUtils.bind_code_for_var(_node_var('found', 'Node'))

	assert_str(HenTest.get_all_code()).contains('_ref.hit_body.get_node_or_null(')


# --- an action saved before the slot existed ---------------------------------


# the clone is made once, at creation: a saved action never draws a slot the macro
# gained later unless the load path puts it back
func test_a_saved_action_gets_the_slot_the_macro_gained() -> void:
	var action: HenSaveAction = _add_action(_register(FIX_COLOR), &'update')
	var survivor: String = str(action.inputs[-1].id)

	action.input_bindings[survivor] = 'hit_color'
	action.inputs.remove_at(0)

	HenSaveAction.sync_macro_inputs(save_data)

	assert_int(action.inputs.size()).is_equal(2)
	assert_str(str(action.inputs[0].id)).is_equal('ref')
	assert_str(str(action.inputs[1].id)).is_equal(survivor)
	assert_str(str(action.input_bindings.get(survivor, ''))).is_equal('hit_color')


func test_the_slot_reaches_a_step_nested_in_a_branch() -> void:
	var loop: HenSaveAction = _add_action(_register(FIX_GET_NODE), &'enter')
	var nested: HenSaveAction = HenSaveAction.create(_register(FIX_COLOR))

	nested.inputs.remove_at(0)
	loop.branch_actions['found'] = [nested]

	HenSaveAction.sync_macro_inputs(save_data)

	assert_str(str(nested.inputs[0].id)).is_equal('ref')


func test_syncing_twice_adds_nothing() -> void:
	var action: HenSaveAction = _add_action(_register(FIX_COLOR), &'update')

	HenSaveAction.sync_macro_inputs(save_data)
	HenSaveAction.sync_macro_inputs(save_data)

	assert_int(action.inputs.size()).is_equal(2)
