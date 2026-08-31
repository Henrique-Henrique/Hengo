extends HenTestSuite

# covers the scope the canvas edits: how the crumbs are built, which definition an
# action list belongs to and what opening one from each place does.


func after_test() -> void:
	HenRoute.go_base()
	await super()


func _function(_name: String) -> HenSaveFunc:
	var func_res: HenSaveFunc = save_data.add_function()

	func_res.name = _name

	return func_res


func _macro(_name: String) -> HenSaveStateMacro:
	var macro: HenSaveStateMacro = save_data.add_macro()

	macro.name = _name

	return macro


# the sidebar lists the definitions of the script, so picking one there is a path
# of its own: two of them are siblings, never one inside the other
func test_opening_from_the_sidebar_replaces_the_path() -> void:
	var first: HenSaveFunc = _function('first')
	var second: HenSaveFunc = _function('second')

	HenRoute.enter(HenRoute.KIND_FUNCTION, first.id)
	HenRoute.enter(HenRoute.KIND_FUNCTION, second.id)

	assert_int(HenRoute.stack().size()).is_equal(1)
	assert_str(str(HenRoute.current_id())).is_equal(str(second.id))


# reached from inside the open one, it nests: that is the path the reader walked
func test_opening_from_inside_nests() -> void:
	var macro: HenSaveStateMacro = _macro('alarm')
	var func_res: HenSaveFunc = _function('helper')

	HenRoute.enter(HenRoute.KIND_MACRO, macro.id)
	HenRoute.enter(HenRoute.KIND_FUNCTION, func_res.id, true)

	var crumbs: Array[Dictionary] = HenRoute.crumbs(save_data)

	assert_int(crumbs.size()).is_equal(3)
	assert_str(str(crumbs[1].name)).is_equal('alarm')
	assert_str(str(crumbs[2].name)).is_equal('helper')


func test_a_crumb_already_open_goes_back_to_it() -> void:
	var macro: HenSaveStateMacro = _macro('alarm')
	var func_res: HenSaveFunc = _function('helper')

	HenRoute.enter(HenRoute.KIND_MACRO, macro.id)
	HenRoute.enter(HenRoute.KIND_FUNCTION, func_res.id, true)
	HenRoute.enter(HenRoute.KIND_MACRO, macro.id, true)

	assert_int(HenRoute.stack().size()).is_equal(1)
	assert_str(str(HenRoute.current_id())).is_equal(str(macro.id))


# a deleted definition cannot leave the canvas pointing at nothing
func test_a_gone_definition_drops_out_of_the_path() -> void:
	var func_res: HenSaveFunc = _function('gone')

	HenRoute.enter(HenRoute.KIND_FUNCTION, func_res.id)
	save_data.functions.clear()
	HenRoute.validate(save_data)

	assert_bool(HenRoute.is_base()).is_true()


# --- which definition an action list belongs to ------------------------------


func test_a_function_body_belongs_to_the_function() -> void:
	var func_res: HenSaveFunc = _function('reach')

	assert_object(HenRoute.definition_of(save_data, func_res.scope_state().id)).is_equal(func_res)


func test_a_state_of_a_macro_belongs_to_the_macro() -> void:
	var macro: HenSaveStateMacro = _macro('alarm')
	var inner: HenSaveState = macro.get_states(save_data)[0]
	var deeper: HenSaveState = inner.add_sub_state(save_data)

	assert_object(HenRoute.definition_of(save_data, inner.id)).is_equal(macro)
	# however deep it sits, it still belongs to the macro
	assert_object(HenRoute.definition_of(save_data, deeper.id)).is_equal(macro)


func test_a_state_of_the_script_belongs_to_no_definition() -> void:
	var state: HenSaveState = save_data.add_state(false)

	assert_object(HenRoute.definition_of(save_data, state.id)).is_null()
	assert_array(HenRoute.stack_for(save_data, state.id)).is_empty()


# picking a state of a macro while the script is on screen has to open the macro
func test_the_stack_of_a_state_opens_its_macro() -> void:
	var macro: HenSaveStateMacro = _macro('alarm')
	var inner: HenSaveState = macro.get_states(save_data)[0]
	var wanted: Array = HenRoute.stack_for(save_data, inner.id)

	assert_int(wanted.size()).is_equal(1)
	assert_str(str(wanted[0].kind)).is_equal(str(HenRoute.KIND_MACRO))
	assert_str(str(wanted[0].id)).is_equal(str(macro.id))


# the stack is a typed array, so a plain one coming from a lookup has to be
# assigned into it instead of replacing it
func test_the_stack_takes_a_plain_array() -> void:
	var macro: HenSaveStateMacro = _macro('alarm')
	var inner: HenSaveState = macro.get_states(save_data)[0]

	HenRoute.set_stack(HenRoute.stack_for(save_data, inner.id))

	assert_str(str(HenRoute.current_kind())).is_equal(str(HenRoute.KIND_MACRO))
	assert_object(HenRoute.current_scope(save_data)).is_equal(macro)

	HenRoute.set_stack([])

	assert_bool(HenRoute.is_base()).is_true()
