@tool
extends OptionButton

#imports
const _Global = preload('res://addons/hengo/scripts/global.gd')

var left_mouse_check: Control
var right_mouse_check: Control

var is_showing: bool = false
var x_size: float = INF
var hover_type: Type = Type.NONE

enum Type {LEFT, RIGHT, NONE}


func _ready() -> void:
    item_selected.connect(_on_item)

    await RenderingServer.frame_post_draw

    left_mouse_check = _Global.CNODE_CAM.get_parent().get_node('LeftMouseCheck')
    right_mouse_check = _Global.CNODE_CAM.get_parent().get_node('RightMouseCheck')

    left_mouse_check.mouse_entered.connect(_on_hover.bind(Type.LEFT))
    right_mouse_check.mouse_entered.connect(_on_hover.bind(Type.RIGHT))

    (_Global.CNODE_CAM.get_parent() as Panel).mouse_entered.connect(_on_cnode_state_ui_hover)

    config_mouse_filter(get_selected_id())

func _on_cnode_state_ui_hover() -> void:
    if is_showing:
        match hover_type:
            Type.LEFT:
                var state_ui: Panel = _Global.STATE_CAM.get_parent()
                var split_container: SplitContainer = state_ui.get_parent()
                var tween: Tween = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

                tween.tween_property(split_container, 'split_offset', int(-split_container.size.x / 2), .1)
                tween.tween_callback(func(): state_ui.visible = false)
            
            Type.RIGHT:
                var split_container: SplitContainer = _Global.SIDE_BAR.get_parent()
                var tween: Tween = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

                tween.tween_property(split_container, 'split_offset', 0, .1)
                tween.tween_callback(func(): _Global.SIDE_BAR.visible = false)
        
        is_showing = false


func _on_hover(_type: Type) -> void:
    match _type:
        Type.LEFT:
            var state_ui: Panel = _Global.STATE_CAM.get_parent()

            if not state_ui.visible:
                var split_container: SplitContainer = state_ui.get_parent()

                state_ui.visible = true

                var tween: Tween = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

                split_container.split_offset = int(-split_container.size.x / 2)
                tween.tween_property(split_container, 'split_offset', 0, .1)

                is_showing = true
                x_size = state_ui.size.x
            
        Type.RIGHT:
            if not _Global.SIDE_BAR.visible:
                var split_container: SplitContainer = _Global.SIDE_BAR.get_parent()

                _Global.SIDE_BAR.visible = true
                split_container.split_offset = 0

                var tween: Tween = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
                tween.tween_property(split_container, 'split_offset', -380, .1)

                is_showing = true
    
    hover_type = _type


func _on_item(_id: int) -> void:
    var state_ui: Panel = _Global.STATE_CAM.get_parent()
    var split_container: SplitContainer = state_ui.get_parent()

    split_container.split_offset = -380
    is_showing = false

    match _id:
        # both
        0:
            _Global.SIDE_BAR.visible = true
            state_ui.visible = true
        # none
        1:
            state_ui.visible = false
            _Global.SIDE_BAR.visible = false
        # only states
        2:
            state_ui.visible = true
            _Global.SIDE_BAR.visible = false
        # only side bar
        3:
            _Global.SIDE_BAR.visible = true
            state_ui.visible = false
        
    config_mouse_filter(_id)


func config_mouse_filter(_id: int) -> void:
    match _id:
        # both
        0:
            left_mouse_check.mouse_filter = Control.MOUSE_FILTER_IGNORE
            right_mouse_check.mouse_filter = Control.MOUSE_FILTER_IGNORE
        # none
        1:
            left_mouse_check.mouse_filter = Control.MOUSE_FILTER_STOP
            right_mouse_check.mouse_filter = Control.MOUSE_FILTER_STOP
        # only states
        2:
            left_mouse_check.mouse_filter = Control.MOUSE_FILTER_IGNORE
            right_mouse_check.mouse_filter = Control.MOUSE_FILTER_STOP
        # only side bar
        3:
            left_mouse_check.mouse_filter = Control.MOUSE_FILTER_STOP
            right_mouse_check.mouse_filter = Control.MOUSE_FILTER_IGNORE
