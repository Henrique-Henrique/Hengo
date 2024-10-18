@tool
extends TextureRect

# imports
const _Global = preload('res://addons/hengo/scripts/global.gd')
const _FlowConnectionLine = preload('res://addons/hengo/scripts/flow_connection_line.gd')
const _Assets = preload('res://addons/hengo/scripts/assets.gd')

@export var root: PanelContainer
@export var type: String = 'cnode'

var connections_lines: Array = []
var is_connected: bool = false

func _ready():
    gui_input.connect(_on_gui)
    mouse_entered.connect(_on_hover)
    mouse_exited.connect(_on_exit)
    item_rect_changed.connect(_on_rect_change)


func _on_hover() -> void:
    if not is_connected:
        texture = load('res://addons/hengo/assets/icons/flow_arrow_hover.svg')


func _on_exit() -> void:
    if not is_connected:
        texture = load('res://addons/hengo/assets/icons/flow_arrow.svg')


# updating line
func _on_rect_change() -> void:
    for line in connections_lines:
        if line.to_cnode.is_inside_tree():
            line.update_line()

func _on_gui(_event: InputEvent) -> void:
    if _event is InputEventMouseButton:
        if _event.pressed:
            if _event.button_index == MOUSE_BUTTON_LEFT:
                _Global.can_make_flow_connection = true
                _Global.flow_cnode_from = root
                _Global.CONNECTION_GUIDE.is_in_out = false
                _Global.CONNECTION_GUIDE.start(_Global.CAM.get_relative_vec2(self.global_position) + self.size / 2)
                _Global.CONNECTION_GUIDE.gradient.colors = [Color.GRAY, Color.GRAY]
        else:
            if _event.button_index == MOUSE_BUTTON_LEFT:
                remove_connection()
                if _Global.can_make_flow_connection and _Global.flow_connection_to_data.is_empty():
                    var method_list = load('res://addons/hengo/scenes/utils/method_picker.tscn').instantiate()
                    method_list.start(_Global.script_config.type, get_global_mouse_position(), true, 'out', {
                        from_flow_connector = self
                    })
                    _Global.GENERAL_POPUP.get_parent().show_content(method_list, 'Pick a Method', get_global_mouse_position())
                elif _Global.can_make_flow_connection and not _Global.flow_connection_to_data.is_empty():
                    var line := create_connection_line(_Global.flow_connection_to_data)

                    _Global.history.create_action('Add Flow Connection')
                    _Global.history.add_do_method(line.add_to_scene)
                    _Global.history.add_do_reference(line)
                    _Global.history.add_undo_method(line.remove_from_scene)
                    _Global.history.commit_action()

                # region effects
                if not _Global.flow_connection_to_data.is_empty():
                    _Global.flow_connection_to_data.from_cnode.scale = Vector2.ONE
                    _Global.flow_connection_to_data.from_cnode.modulate = Color.WHITE
                    _Global.flow_connection_to_data.from_cnode.get_node('%Border').visible = false

                root.scale = Vector2.ONE
                root.modulate = Color.WHITE
                root.get_node('%Border').visible = false
                # endregion

                _Global.flow_connection_to_data = {}
                _Global.can_make_flow_connection = false
                _Global.flow_cnode_from = null
                _Global.CONNECTION_GUIDE.end()


func create_connection_line(_config: Dictionary) -> _FlowConnectionLine:
    var line := _Assets.FlowConnectionLineScene.instantiate()

    line.from_connector = self
    line.to_cnode = _config.from_cnode

    match self.root.type:
        'if':
            self.root.flow_to[type] = _config.from_cnode
            line.flow_type = type
        _:
            self.root.flow_to = {
                cnode = _config.from_cnode
            }
            line.flow_type = 'cnode'

    # signal to update flow connection line
    root.connect('on_move', line.update_line)
    _config.from_cnode.connect('on_move', line.update_line)

    root.connect('resized', line.update_line)
    _config.from_cnode.connect('resized', line.update_line)

    is_connected = true

    return line


func create_connection_line_and_instance(_config: Dictionary) -> _FlowConnectionLine:
    var line = create_connection_line(_config)
    line.add_to_scene()
    return line


func remove_connection() -> void:
    if connections_lines.size() > 0:
        for line in connections_lines.duplicate():
            line.remove_from_scene()