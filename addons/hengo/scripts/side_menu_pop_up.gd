@tool
extends PanelContainer

const _Assets = preload('res://addons/hengo/scripts/assets.gd')
const _Enums = preload('res://addons/hengo/references/enums.gd')
const _Global = preload('res://addons/hengo/scripts/global.gd')

var ref

func _ready() -> void:
	get_node('%Delete').pressed.connect(_on_delete)

func _on_delete() -> void:
	if not ref:
		return

	_Global.history.create_action('Delete SideBar Item')
	_Global.history.add_do_method(ref.remove_from_scene)
	_Global.history.add_undo_method(ref.add_to_scene)
	_Global.history.add_undo_reference(ref)

	# item's references will erased too
	for cnode in ref.instance_reference:
		_Global.history.add_undo_reference(cnode)

	_Global.history.commit_action()

	get_parent().hide()

func mount(_props: Array, _config: Dictionary) -> void:
	var container = get_node('Container/Props')

	ref = _config.ref

	# cleaning previous props
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()

	await get_tree().process_frame

	# creating props
	for prop in _props:
		var prop_container = _Assets.PropContainerScene.instantiate()

		prop_container.get_node('Name').text = prop.name


		match prop.type:
			_Enums.PROP_TYPE.STRING:
				var str = load('res://addons/hengo/scenes/props/string.tscn').instantiate()
				prop_container.add_child(str)
				str.set_default(prop.value)
				str.connect('value_changed', on_prop_change_value.bind(prop))
				container.add_child(prop_container)
			_Enums.PROP_TYPE.FUNCTION_INPUT, _Enums.PROP_TYPE.FUNCTION_OUTPUT:
				var in_out = load('res://addons/hengo/scenes/props/function_input_output.tscn').instantiate()
				prop_container.add_child(in_out)
				in_out.set_default(
					prop.get('inputs') if prop.type == _Enums.PROP_TYPE.FUNCTION_INPUT
					else prop.get('outputs')
				)
				var in_out_type := 'in' if prop.type == _Enums.PROP_TYPE.FUNCTION_INPUT else 'out'

				in_out.connect('moved_param', prop.move_up_down.bind(in_out_type))
				in_out.connect('added_param', prop.add_in_out.bind(in_out_type))
				in_out.connect('removed_param', prop.remove_in_out.bind(in_out_type))
				container.add_child(prop_container)
			_Enums.PROP_TYPE.DROPDOWN:
				var dropdown = load('res://addons/hengo/scenes/props/dropdown.tscn').instantiate()
				dropdown.set_default(prop.value)
				dropdown.options = prop.dropdown_options
				dropdown.type = prop.sub_type
				prop_container.add_child(dropdown)
				dropdown.connect('value_changed', on_prop_change_value.bind(prop))
				container.add_child(prop_container)
			_Enums.PROP_TYPE.BOOL:
				var boolean = load('res://addons/hengo/scenes/props/boolean.tscn').instantiate()
				boolean.set_default(str(prop.value))
				boolean.connect('value_changed', on_prop_change_value.bind(prop))
				prop_container.add_child(boolean)
				container.add_child(prop_container)

	await get_tree().process_frame
	size = Vector2.ZERO

func on_prop_change_value(_value, _prop: Resource) -> void:
	_prop.value = _value