extends HenActionTestSuite

const FIX_PICK: String = 'res://addons/hengo/actions/input/pick_under_mouse_2d.gd'


func _reasons() -> Array:
	return HenGeneratorAction.collect_errors(save_data).map(func(err: Dictionary) -> String: return str(err.reason))


func _reason_text() -> String:
	return '\n'.join(PackedStringArray(_reasons()))


func _print_bound_to(_bind: String) -> HenSaveAction:
	var action: HenSaveAction = _add_action(_register(FIX_PRINT), &'update')

	action.input_bindings['value'] = _bind

	return action


func test_only_nodes_are_valid_bases() -> void:
	assert_bool(HenScriptBaseType.is_valid_base(&'Node3D')).is_true()
	assert_bool(HenScriptBaseType.is_valid_base(&'Resource')).is_false()
	assert_bool(HenScriptBaseType.is_valid_base(&'NotAClass')).is_false()


func test_an_action_outside_its_target_classes_is_an_error() -> void:
	_add_action(_register(FIX_PICK), &'physics')

	assert_str(_reason_text()).not_contains('only works on')

	save_data.identity.type = 'Node3D'

	assert_str(_reason_text()).contains('only works on Node2D, and this script extends Node3D')


func test_an_action_outside_its_target_classes_emits_no_code() -> void:
	save_data.identity.type = 'Node3D'
	_add_action(_register(FIX_PICK), &'physics')

	assert_str(HenTest.get_all_code()).contains('unresolved: only works on')


func test_a_property_the_base_lacks_is_an_error() -> void:
	_print_bound_to('modulate')

	assert_array(_reasons()).is_empty()

	save_data.identity.type = 'Node3D'

	assert_str(_reason_text()).contains('reads the property "modulate", which Node3D does not have')


func test_a_sub_property_is_checked_by_its_root() -> void:
	_print_bound_to('position.x')

	assert_array(_reasons()).is_empty()

	save_data.identity.type = 'Timer'

	assert_str(_reason_text()).contains('"position"')


func test_a_native_source_the_base_lacks_is_an_error() -> void:
	_print_bound_to('get_global_mouse_position()')

	assert_array(_reasons()).is_empty()

	save_data.identity.type = 'Node3D'

	assert_str(_reason_text()).contains('needs a script extending CanvasItem')


func test_a_property_inside_an_expression_is_checked() -> void:
	var action: HenSaveAction = _add_action(_register(FIX_PHASES), &'update')

	action.input_expressions['value'] = _expression('a + 1', ['a'], {a = 'rotation'}, {})
	save_data.identity.type = 'Timer'

	assert_str(_reason_text()).contains('expression word "a" reads the property "rotation"')


func test_a_variable_binding_ignores_the_base() -> void:
	var speed: HenSaveVar = save_data.add_var(false)

	speed.name = 'speed'
	speed.type = 'float'
	_print_bound_to(HenUtils.bind_code_for_var(speed))
	save_data.identity.type = 'Timer'

	assert_array(_reasons()).is_empty()


func test_a_bound_node_slot_keeps_working_on_another_base() -> void:
	var node_var: HenSaveVar = save_data.add_var(false)

	node_var.name = 'sprite_ref'
	node_var.type = 'Node'

	var action: HenSaveAction = _add_action(_register(FIX_NODE_SLOT), &'update')

	action.input_bindings['ref'] = 'sprite_ref'
	save_data.identity.type = 'Timer'

	assert_array(_reasons()).is_empty()


func test_preview_lists_only_the_new_errors_and_keeps_the_type() -> void:
	_add_action(_register(FIX_PICK), &'physics')
	_print_bound_to('get_global_mouse_position()')

	var gone: HenSaveVar = save_data.add_var(false)
	var stale: HenSaveAction = _print_bound_to(HenUtils.bind_code_for_var(gone))

	save_data.variables.erase(gone)

	var broken: Array[Dictionary] = HenScriptBaseType.preview(save_data, &'Node3D')
	var ids: Array = broken.map(func(err: Dictionary) -> StringName: return err.action_id)

	assert_str(str(save_data.identity.type)).is_equal('Sprite2D')
	assert_int(broken.size()).is_equal(2)
	assert_array(ids).not_contains([StringName(str(stale.id))])


func test_preview_of_a_compatible_base_is_empty() -> void:
	_add_action(_register(FIX_PICK), &'physics')
	_print_bound_to('modulate')

	assert_array(HenScriptBaseType.preview(save_data, &'AnimatedSprite2D')).is_empty()


func test_apply_changes_the_base_and_the_generated_extends() -> void:
	HenScriptBaseType.apply(save_data, &'CharacterBody2D')

	assert_str(str(save_data.identity.type)).is_equal('CharacterBody2D')
	assert_str(HenTest.get_all_code()).contains('extends CharacterBody2D')


func test_apply_retypes_the_variables_holding_the_script() -> void:
	var map_deps: HenMapDependencies = Engine.get_singleton(&'MapDependencies')
	var other: HenMapDependencies.ProjectAST = HenMapDependencies.ProjectAST.new()
	var holder: HenSaveVar = HenSaveVar.new()
	var unrelated: HenSaveVar = HenSaveVar.new()

	other.identity = HenSaveDataIdentity.create(&'other_script', 'Node', 'Other')
	holder.type = 'Sprite2D'
	holder.script_id = save_data.identity.id
	unrelated.type = 'Sprite2D'
	other.variables.append(holder)
	other.variables.append(unrelated)
	map_deps.ast_list.set(&'other_script', other)

	HenScriptBaseType.apply(save_data, &'Node3D')

	assert_str(str(holder.type)).is_equal('Node3D')
	assert_str(str(unrelated.type)).is_equal('Sprite2D')
