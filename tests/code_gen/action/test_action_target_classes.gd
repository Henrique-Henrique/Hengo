extends HenActionTestSuite

# covers the class an action dispatches on: the emitted body follows the class
# the script extends, never the node running it.

# dispatches on the class the script extends, never on the node at runtime
const FIX_FLASH: String = 'res://addons/hengo/actions/render/flash.gd'


# --- target classes ---------------------------------------------------------


const FIX_COLOR: String = 'res://addons/hengo/actions/render/change_color.gd'


# the same action emits the 2d path when the script extends a Node2D
func test_target_class_dispatches_to_node_2d() -> void:
	_add_action(_register(FIX_COLOR), &'update')

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('_ref.modulate = Color(')
	assert_str(code).not_contains('albedo_color')


# and the 3d path when it extends a Node3D, from the very same macro file
func test_target_class_dispatches_to_node_3d() -> void:
	save_data.identity.type = 'MeshInstance3D'
	_add_action(_register(FIX_COLOR), &'update')

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('albedo_color = Color(')
	assert_str(code).not_contains('_ref.modulate')


# both branches must be valid gdscript under their own base class
func test_target_class_bodies_compile() -> void:
	save_data.identity.type = 'MeshInstance3D'
	_add_action(_register(FIX_COLOR), &'update')

	var script := GDScript.new()
	script.source_code = HenTest.get_all_code()

	assert_int(script.reload()).is_equal(OK)


# emits the body for the owner and asserts the generated script compiles
func _color_code_for(_owner: String) -> String:
	save_data.identity.type = _owner
	_add_action(_register(FIX_COLOR), &'update')

	var code: String = HenTest.get_all_code()
	var script := GDScript.new()
	script.source_code = code

	assert_int(script.reload()).override_failure_message('change_color does not compile for ' + _owner + ':\n' + code).is_equal(OK)
	return code


# a 2d light owns its color, so it writes .color instead of tinting via modulate
func test_target_class_dispatches_to_light_2d() -> void:
	var code: String = _color_code_for('PointLight2D')

	assert_str(code).contains('(_ref as Light2D).color = Color(')
	assert_str(code).not_contains('_ref.modulate')


# a 3d light writes light_color, never touching a material override
func test_target_class_dispatches_to_light_3d() -> void:
	var code: String = _color_code_for('OmniLight3D')

	assert_str(code).contains('(_ref as Light3D).light_color = Color(')
	assert_str(code).not_contains('albedo_color')


# a 3d sprite tints via modulate, not the albedo path meshes take
func test_target_class_dispatches_to_sprite_3d() -> void:
	var code: String = _color_code_for('Sprite3D')

	assert_str(code).contains('(_ref as SpriteBase3D).modulate = Color(')
	assert_str(code).not_contains('albedo_color')


# a polygon writes its fill color prop directly
func test_target_class_dispatches_to_polygon_2d() -> void:
	assert_str(_color_code_for('Polygon2D')).contains('(_ref as Polygon2D).color = Color(')


# a canvas modulate tints the whole canvas through its color prop
func test_target_class_dispatches_to_canvas_modulate() -> void:
	assert_str(_color_code_for('CanvasModulate')).contains('(_ref as CanvasModulate).color = Color(')


# a line writes default_color, the prop that drives its stroke
func test_target_class_dispatches_to_line_2d() -> void:
	assert_str(_color_code_for('Line2D')).contains('(_ref as Line2D).default_color = Color(')


# a macro is offered to whoever inherits from its targets, and to no one else
func test_macro_is_offered_only_to_declared_classes() -> void:
	var color: HenSaveMacro = _register(FIX_COLOR)

	assert_bool(color.serves_class(&'Sprite2D')).is_true()
	assert_bool(color.serves_class(&'MeshInstance3D')).is_true()
	# change_color absorbed set_modulate, so it targets CanvasItem too (Control included)
	assert_bool(color.serves_class(&'Button')).is_true()
	assert_bool(color.serves_class(&'Timer')).is_false()

	var only_control: HenSaveMacro = HenSaveMacro.new()
	only_control.target_classes = [&'Control']

	assert_bool(only_control.serves_class(&'Button')).is_true()
	assert_bool(only_control.serves_class(&'Sprite2D')).is_false()

	# no targets declared -> every class, and an unknown base never hides the pool
	var universal: HenSaveMacro = HenSaveMacro.new()

	assert_bool(universal.serves_class(&'Sprite2D')).is_true()
	assert_bool(only_control.serves_class(&'MyCustomBase')).is_true()


# the recipe is mtime-cached, so the targets must survive the real loader path
func test_native_loader_carries_target_classes() -> void:
	HenScriptMacroLoader.load_native_actions()

	var color: HenSaveMacro = null
	for macro: HenSaveMacro in (Engine.get_singleton(&'Global') as HenGlobal).action_macros:
		if macro.id == &'change_color':
			color = macro

	assert_object(color).is_not_null()
	assert_array(color.target_classes).contains([&'CanvasItem', &'Node3D'])


# --- dispatching on the script class, not on the running node ---------------


# a 2d script only ever tints through modulate, so the mesh half of the action is
# never compiled and no `is` reaches the game
func test_an_action_compiles_only_the_side_its_script_needs() -> void:
	var node_var: HenSaveVar = save_data.add_var(false)

	node_var.name = 'sprite_ref'
	node_var.type = 'Node'

	var action: HenSaveAction = _add_action(_register(FIX_FLASH), &'enter')

	action.input_bindings['target'] = 'sprite_ref'

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('"modulate"')
	assert_str(code).not_contains(' is CanvasItem')
	assert_str(code).not_contains('albedo_color')


# the same action on a 3d script compiles the material half instead
func test_the_same_action_compiles_the_other_side_on_a_3d_script() -> void:
	save_data.identity.type = 'Node3D'

	var node_var: HenSaveVar = save_data.add_var(false)

	node_var.name = 'mesh_ref'
	node_var.type = 'Node'

	var action: HenSaveAction = _add_action(_register(FIX_FLASH), &'enter')

	action.input_bindings['target'] = 'mesh_ref'

	var code: String = HenTest.get_all_code()

	assert_str(code).contains('albedo_color')
	assert_str(code).not_contains(' is CanvasItem')
	assert_str(code).not_contains(' is GeometryInstance3D')
