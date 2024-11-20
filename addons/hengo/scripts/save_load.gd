@tool
extends Node

# imports
const _Global = preload('res://addons/hengo/scripts/global.gd')
const _State = preload('res://addons/hengo/scripts/state.gd')
const _Router = preload('res://addons/hengo/scripts/router.gd')
const _ConnectionLine = preload('res://addons/hengo/scripts/connection_line.gd')
const _CNode = preload('res://addons/hengo/scripts/cnode.gd')
const _CodeGeneration = preload('res://addons/hengo/scripts/code_generation.gd')
const _GeneralRoute = preload('res://addons/hengo/scripts/general_route.gd')
const _UtilsName = preload('res://addons/hengo/scripts/utils_name.gd')

# ---------------------------------------------------------------------------- #
#                                    saving                                    #
# ---------------------------------------------------------------------------- #

static func save(_code: String, _debug_symbols: Dictionary) -> void:
    var script_data: Dictionary = {
        type = _Global.script_config.type,
        node_counter = _Global.node_counter,
        debug_symbols = _debug_symbols,
        state_name_counter = _State._name_counter
    }

    # ---------------------------------------------------------------------------- #
    # Generals
    var generals: Array[Dictionary] = []

    for general in _Global.GENERAL_CONTAINER.get_children():
        var data: Dictionary = general.custom_data

        data.pos = var_to_str(general.position)
        data.id = general.id

        for cnode in general.virtual_cnode_list:
            data.cnode_list = get_cnode_list(
                _Router.route_reference[general.route.id],
                ['var', 'set_var', 'user_func', 'signal_connection', 'signal_emit', 'signal_disconnection']
            )

        generals.append(data)

    script_data['generals'] = generals

    # ---------------------------------------------------------------------------- #
    # STATES
    var states: Array[Dictionary] = []

    for state in _Global.STATE_CONTAINER.get_children():
        var data: Dictionary = {
            id = state.hash,
            name = state.get_state_name(),
            pos = var_to_str(state.position),
            cnode_list = get_cnode_list(
                _Router.route_reference[state.route.id],
                ['var', 'set_var', 'user_func', 'signal_connection', 'signal_emit', 'signal_disconnection']
            ),
            events = [],
            transitions = []
        }

        var state_route = state.route.duplicate()
        state_route.erase('state_ref')

        data['route'] = state_route

        # ---------------------------------------------------------------------------- #
        # transitions
        for trans in state.get_node('%TransitionContainer').get_children():
            var trans_data = {
                name = trans.get_transition_name()
            }

            if trans.line:
                trans_data['to_state_id'] = trans.line.to_state.hash

            data['transitions'].append(trans_data)

        var event_container = state.get_node('%EventContainer')

        if event_container.get_child_count() > 0:
            var event_list := event_container.get_child(0).get_node('%EventList')

            for event in event_list.get_children():
                data['events'].append(event.get_meta('config'))

        states.append(data)

    script_data['states'] = states

    # ---------------------------------------------------------------------------- #
    # CONNECTIONS
    var connections: Array[Dictionary] = []
    var flow_connections: Array[Dictionary] = []

    for line in _Router.line_route_reference.values().reduce(func(acc, c): return acc + c):
        if line is _ConnectionLine:
            connections.append({
                from_cnode = line.from_cnode.hash,
                to_cnode = line.to_cnode.hash,
                input = line.input.owner.get_index(),
                output = line.output.owner.get_index()
            })
        # its flow connection
        else:
            flow_connections.append({
                from_cnode = line.from_connector.root.hash,
                from_connector = line.from_connector.get_index(),
                to_cnode = line.to_cnode.hash
            })

    script_data['connections'] = connections
    script_data['flow_connections'] = flow_connections

    # ---------------------------------------------------------------------------- #
    # Variables
    var var_section = _Global.SIDE_BAR.get_node('%Var').get_node('%Container')
    var var_item_list: Array[Dictionary] = []

    for item in var_section.get_children():
        var item_data: Dictionary = {
            id = item.get_instance_id(),
            name = item.res[0].value,
            type = item.res[1].value,
            export_var = item.res[2].value,
            instances = []
        }

        # instances
        for cnode in item.instance_reference:
            # if node is deleted, dont add on data
            if not is_instance_valid(cnode) or cnode.deleted:
                continue

            item_data['instances'].append(_get_cnode_route_instance(cnode))

        var_item_list.append(item_data)

    script_data['var_item_list'] = var_item_list

    # ---------------------------------------------------------------------------- #
    # Funcions
    var func_section = _Global.SIDE_BAR.get_node('%Function').get_node('%Container')
    var func_item_list: Array[Dictionary] = []

    for item in func_section.get_children():
        var item_data: Dictionary = {
            id = item.get_instance_id(),
            name = item.res[0].value,
            start_data = {},
            inputs = [],
            outputs = [],
            instances = [],
            cnode_list = get_cnode_list(
                _Router.route_reference[item.route.id],
                ['var', 'set_var', 'local_var', 'set_local_var', 'user_func', 'func_input', 'func_output']
            )
        }
        
        # inputs
        for input: Dictionary in item.res[1].inputs:
            item_data.inputs.append({
                name = input.res.name,
                type = input.res.type
            })
        
        # outputs
        for output: Dictionary in item.res[2].outputs:
            item_data.outputs.append({
                name = output.res.name,
                type = output.res.type
            })

        # instances
        for cnode in item.instance_reference:
            # if node is deleted, dont add on data
            if not is_instance_valid(cnode) or cnode.deleted:
                continue

            if cnode.type == 'func_input':
                item_data['start_data'].input = {
                    pos = var_to_str(cnode.position),
                    id = cnode.hash
                }
                continue
            elif cnode.type == 'func_output':
                item_data['start_data'].output = {
                    pos = var_to_str(cnode.position),
                    id = cnode.hash
                }
                continue

            item_data['instances'].append(_get_cnode_route_instance(cnode))

        func_item_list.append(item_data)

    script_data['func_item_list'] = func_item_list

    # ---------------------------------------------------------------------------- #
    # SIGNALS
    var signal_section = _Global.SIDE_BAR.get_node('%StateSignal').get_node('%Container')
    var signal_item_list: Array[Dictionary] = []

    for item in signal_section.get_children():
        var item_data: Dictionary = {
            id = item.get_instance_id(),
            name = item.res[0].value,
            signal_data = {
                object_name = item.data.signal_data.object_name,
                signal_name = item.data.signal_data.signal_name
            },
            start_data = {},
            params = [],
            instances = [],
            cnode_list = get_cnode_list(
                _Router.route_reference[item.route.id],
                ['var', 'set_var', 'local_var', 'set_local_var', 'user_func', 'signal_virtual']
            )
        }

        # params
        for input: Dictionary in item.res[1].outputs:
            item_data.params.append({
                name = input.res.name,
                type = input.res.type
            })

        # instances
        for cnode in item.instance_reference:
            # if node is deleted, dont add on data
            if not is_instance_valid(cnode) or cnode.deleted:
                continue

            if cnode.type == 'signal_virtual':
                item_data['start_data']. signal = {
                    pos = var_to_str(cnode.position),
                    id = cnode.hash
                }
                continue

            item_data['instances'].append(_get_cnode_route_instance(cnode))
        
        signal_item_list.append(item_data)

    script_data['signal_item_list'] = signal_item_list

    # ---------------------------------------------------------------------------- #
    # Local Variables
    var local_var_section = _Global.SIDE_BAR.get_node('%LocalVar')
    var local_var_item_list: Array[Dictionary] = []

    for item in local_var_section.get_node('%Container').get_children():
        var item_data: Dictionary = {
            id = item.get_instance_id(),
            name = item.res[0].value,
            type = item.res[1].value,
            route_ref = get_inst_id_by_route(item.route_ref),
            instances = []
        }

        # instances
        for cnode in item.instance_reference:
            item_data['instances'].append(_get_cnode_route_instance(cnode))

        local_var_item_list.append(item_data)

    script_data['local_var_items'] = local_var_item_list
    # ---------------------------------------------------------------------------- #
    # loading comments
    var comment_list: Array[Dictionary] = []
    var comment_node_list: Array = []

    for c_arr in _Router.comment_reference.values():
        comment_node_list += c_arr

    for comment in comment_node_list:
        comment_list.append({
            id = comment.get_instance_id(),
            is_pinned = comment.is_pinned,
            comment = comment.get_comment(),
            # getting the first cnode of router that comment are in (this is needed to get router ref later)
            router_ref_id = _Router.route_reference[comment.route_ref.id][0].hash,
            color = var_to_str(comment.get_color()),
            pos = var_to_str(comment.position),
            size = var_to_str(comment.size),
            cnode_inside_ids = comment.cnode_inside.map(
                func(x: _CNode) -> int:
                    return x.hash
        )
        })

    script_data['comments'] = comment_list


    # ---------------------------------------------------------------------------- #
    var code = '#[hengo] ' + JSON.stringify(script_data) + '\n\n' + _code
    var script: GDScript = GDScript.new()

    print(code)

    script.source_code = code

    var reload_err: int = script.reload()

    if reload_err == OK:
        var err: int = ResourceSaver.save(script, _Global.current_script_path)

        if err == OK:
            print('SAVED HENGO SCRIPT')
    else:
        pass

#
#
#
#
#
#
#
#
#
#
#
# ---------------------------------------------------------------------------- #
static func get_cnode_list(_cnode_list: Array, _ignore_list: Array) -> Array:
    var arr: Array = []

    for cnode in _cnode_list:
        # ignore cnode types
        if _ignore_list.has(cnode.type):
            continue

        var cnode_data: Dictionary = {
            # id = cnode.get_instance_id(),
            pos = var_to_str(cnode.position),
            name = cnode.get_cnode_name(),
            sub_type = cnode.type,
            hash = cnode.hash,
            inputs = [],
            outputs = []
        }

        var fantasy_name: String = cnode.get_fantasy_name()

        if cnode_data.name != fantasy_name:
            cnode_data['fantasy_name'] = fantasy_name

        if cnode.cnode_type != 'default':
            cnode_data['type'] = cnode.cnode_type

        for input in cnode.get_node('%InputContainer').get_children():
            var input_data: Dictionary = {
                name = input.get_in_out_name(),
                type = input.connection_type,
            }

            if input.is_ref:
                input_data['ref'] = true

            if input.category:
                if ['state_transition'].has(input.category):
                    input_data['type'] = '@dropdown'

                input_data['category'] = input.category

            if input.custom_data:
                input_data['data'] = input.custom_data

            var cname_input = input.get_node('%CNameInput')

            if cname_input.get_child_count() > 2:
                var in_prop = cname_input.get_child(2)

                if in_prop is not Label:
                    var value = in_prop.get_value()

                    input_data['in_prop'] = value if [TYPE_STRING, TYPE_INT, TYPE_FLOAT, TYPE_BOOL].has(typeof(value)) else var_to_str(value)

            cnode_data.inputs.append(input_data)

        for output in cnode.get_node('%OutputContainer').get_children():
            var output_data: Dictionary = {
                name = output.get_in_out_name(),
                type = output.connection_type
            }

            if output.category:
                output_data['category'] = output.category
            
            if output.sub_type:
                output_data.sub_type = output.sub_type

            var cname_output = output.get_node('%CNameOutput')

            if cname_output.get_child_count() > 2:
                var out_prop = cname_output.get_child(0)

                if out_prop is not Label:
                    output_data['out_prop'] = out_prop.get_value()

            cnode_data.outputs.append(output_data)

        if cnode.category:
            cnode_data['category'] = cnode.category

        match cnode.type:
            'expression':
                cnode_data['exp'] = cnode.get_node('%Container').get_child(1).get_child(0).raw_text

        arr.append(cnode_data)

    return arr

# ---------------------------------------------------------------------------- #

static func _get_cnode_route_instance(_cnode: _CNode) -> Dictionary:
    var cnode_data: Dictionary = {
        id = _cnode.get_instance_id(),
        pos = var_to_str(_cnode.position),
        route_inst_id = get_inst_id_by_route(_cnode.route_ref),
        sub_type = _cnode.type,
        hash = _cnode.hash
    }

    var in_prop_values: Dictionary = {}
    
    for input in _cnode.get_node('%InputContainer').get_children():
        var cname_input = input.get_node('%CNameInput')

        if cname_input.get_child_count() > 2:
            var in_prop = cname_input.get_child(2)

            if in_prop is not Label:
                in_prop_values[input.get_index()] = in_prop.get_generated_code()

    if not in_prop_values.is_empty():
        cnode_data['in_prop_data'] = in_prop_values

    return cnode_data

# ---------------------------------------------------------------------------- #

static func _load_cnode(_cnode_list: Array, _route, _inst_id_refs) -> void:
    for cnode: Dictionary in _cnode_list:
        var cnode_data: Dictionary = {
            pos = cnode.pos,
            name = cnode.name,
            sub_type = cnode.sub_type,
            inputs = cnode.inputs,
            outputs = cnode.outputs,
            hash = cnode.hash,
            route = _route
        }

        if cnode.has('fantasy_name'):
            cnode_data['fantasy_name'] = cnode.get('fantasy_name')

        if cnode.has('type'):
            cnode_data['type'] = cnode.type

        if cnode.has('category'):
            cnode_data['category'] = cnode.get('category')

        if cnode.has('exp'):
            cnode_data['exp'] = cnode.get('exp')

        var cnode_inst = _CNode.instantiate_cnode(cnode_data)

        _inst_id_refs[cnode.hash] = cnode_inst

# ---------------------------------------------------------------------------- #
#                                 load and edit                                #
# ---------------------------------------------------------------------------- #

static func load_and_edit(_path: StringName) -> void:
    # ---------------------------------------------------------------------------- #
    # remove start message
    var state_msg: PanelContainer = _Global.STATE_CAM.get_parent().get_node_or_null('StartMessage')
    var cnode_msg: PanelContainer = _Global.CNODE_CAM.get_parent().get_node_or_null('StartMessage')
    var compile_bt: Button = _Global.STATE_CAM.get_parent().get_node('%Compile')

    if state_msg:
        state_msg.get_parent().remove_child(state_msg)
    
    if cnode_msg:
        cnode_msg.get_parent().remove_child(cnode_msg)

    if not _Global.SIDE_BAR.visible:
        _Global.SIDE_BAR.visible = true

    compile_bt.disabled = false

    # reseting plugin
    _Global.ERROR_BT.reset()

    for state in _Global.STATE_CONTAINER.get_children():
        state.queue_free()

    for state in _Global.GENERAL_CONTAINER.get_children():
        state.queue_free()
    
    for cnode in _Global.CNODE_CONTAINER.get_children():
        cnode.queue_free()

    for cnode in _Global.COMMENT_CONTAINER.get_children():
        cnode.queue_free()
    
    for cnode_line in _Global.CNODE_CAM.get_node('Lines').get_children():
        cnode_line.queue_free()
    
    for state_line in _Global.STATE_CAM.get_node('Lines').get_children():
        state_line.queue_free()

    # cleaning vars
    var var_container = _Global.SIDE_BAR.get_node('%Var').get_node('%Container')
    for var_item in var_container.get_children():
        var_item.queue_free()
    
    # cleaning funcions
    var func_container = _Global.SIDE_BAR.get_node('%Function').get_node('%Container')
    for func_item in func_container.get_children():
        func_item.queue_free()

    # cleaning signals
    var signal_container = _Global.SIDE_BAR.get_node('%StateSignal').get_node('%Container')
    for signal_item in signal_container.get_children():
        signal_item.queue_free()
    
    # cleaning local vars
    var local_var_section = _Global.SIDE_BAR.get_node('%LocalVar')
    var local_var_container = local_var_section.get_node('%Container')

    local_var_section.local_vars = {}

    for local_var_item in local_var_container.get_children():
        local_var_item.queue_free()

    # ---------------------------------------------------------------------------- #
    # setting other scripts config
    var dir: DirAccess = DirAccess.open('res://hengo')
    _Global.SCRIPTS_INFO = []
    parse_other_scripts_data(dir)

    # ---------------------------------------------------------------------------- #

    _Global.current_script_path = _path
    _Router.current_route = {}
    _Router.route_reference = {}
    _Router.line_route_reference = {}
    _Router.comment_reference = {}
    _Global.history = UndoRedo.new()

    var script: GDScript = ResourceLoader.load(_path, '', ResourceLoader.CACHE_MODE_IGNORE)

    if script.source_code.begins_with('extends '):
        # setting script type
        var type: String = script.source_code.split('\n').slice(0, 1)[0].split(' ')[1]
    
        _Global.script_config['type'] = type
        _Global.node_counter = 0
        _State._name_counter = 0

        if ClassDB.is_parent_class(type, 'Node'):
            var spacing: Vector2 = Vector2(-150, -200)

            # creating inputs
            for general_data in [
                {
                    name = 'Input',
                    cnode_name = '_input',
                },
                # {
                #     name = 'Shortcut Input',
                #     cnode_name = '_shortcut_input',
                #     color = '#1e3033'
                # },
                # {
                #     name = 'Unhandled Input',
                #     cnode_name = '_unhandled_input',
                #     color = '#352b19'
                # },
                # {
                #     name = 'Unhandled Key Input',
                #     cnode_name = '_unhandled_key_input',
                #     color = '#44201e'
                # },
                {
                    name = 'Process',
                    cnode_name = '_process',
                    color = '#401d3f',
                    param = {
                        name = 'delta',
                        type = 'float'
                    }
                },
                {
                    name = 'Physics Process',
                    cnode_name = '_physics_process',
                    color = '#1f2950',
                    param = {
                        name = 'delta',
                        type = 'float'
                    }
                },
            ]:
                var data: Dictionary = {
                    route = {
                        name = general_data.name,
                        type = _Router.ROUTE_TYPE.INPUT,
                        id = _UtilsName.get_unique_name()
                    },
                    custom_data = general_data,
                    type = 'input',
                    icon = 'res://addons/hengo/assets/icons/mouse.svg'
                }

                if general_data.has('color'):
                    data.color = general_data.color

                var general := _GeneralRoute.instantiate_general(data)

                general.position = spacing + Vector2(30, 0)

                _CNode.instantiate_and_add({
                    name = general_data.cnode_name,
                    sub_type = 'virtual',
                    outputs = [ {
                        name = 'event',
                        type = 'InputEvent'
                    } if not general_data.has('param') else general_data.param],
                    route = general.route,
                    position = Vector2.ZERO
                })

                spacing = Vector2(general.position.x + general.size.x, general.position.y)

        # It's a new project
        var state := _State.instantiate_and_add_to_scene()
        state.add_event({
            name = 'Start',
            type = 'start'
        })

        state.select()

    #   
    #
    # loading hengo script data
    elif script.source_code.begins_with('#[hengo] '):
        var data: Dictionary = parse_hengo_json(script.source_code)

        var inst_id_refs: Dictionary = {}
        var cnode_to_route_list: Array[Dictionary] = []
        var state_trans_connections: Array = []
    
        # setting script configs
        _Global.script_config['type'] = data.type
        _Global.node_counter = data.node_counter
        _Global.current_script_debug_symbols = data.debug_symbols
        _State._name_counter = data.state_name_counter

        # generating generals (like inputs)
        for general_config: Dictionary in data['generals']:
            var dt: Dictionary = general_config.duplicate()

            dt.route = {
                name = general_config.name,
                type = _Router.ROUTE_TYPE.INPUT,
                id = _UtilsName.get_unique_name()
            }

            dt.type = 'input'
            dt.icon = 'res://addons/hengo/assets/icons/mouse.svg'
            dt.custom_data = general_config

            var general := _GeneralRoute.instantiate_general(dt)

            _load_cnode(general_config.cnode_list, general.route, inst_id_refs)

            inst_id_refs[float(general.id)] = general


        for state: Dictionary in data['states']:
            var state_inst = _State.instantiate_and_add_to_scene({
                name = state.name,
                pos = state.pos,
                hash = state.id
            })

            # transition
            for trans: Dictionary in state['transitions']:
                var trans_inst = state_inst.add_transition(trans.name)

                if trans.has('to_state_id'):
                    state_trans_connections.append({
                        to_state_id = trans.get('to_state_id'),
                        ref = trans_inst
                    })

            # cnodes
            _load_cnode(state.cnode_list, state_inst.route, inst_id_refs)
            
            for event_config: Dictionary in state['events']:
                state_inst.add_event(event_config)
            
            inst_id_refs[state.id] = state_inst

        # creating state transitions connection
        for trans_config: Dictionary in state_trans_connections:
            trans_config.ref.add_connection({
                state_from = inst_id_refs[trans_config.to_state_id]
            })

        # ---------------------------------------------------------------------------- #
        # creating func

        for func_config: Dictionary in data['func_item_list']:
            var item = _Global.SIDE_BAR.get_node('%Function').add_prop(func_config, false)
            var inputs: Array[Dictionary] = []
            var outputs: Array[Dictionary] = []

            # inputs
            for input: Dictionary in func_config['inputs']:
                var res: Resource = load('res://addons/hengo/resources/cnode_function_in_out.tres').duplicate()
                res.name = input.name
                res.type = input.type
                inputs.append({res = res})
            
            item.res[1].inputs = inputs

            # outputs
            for output: Dictionary in func_config['outputs']:
                var res: Resource = load('res://addons/hengo/resources/cnode_function_in_out.tres').duplicate()
                res.name = output.name
                res.type = output.type
                outputs.append({res = res})
            
            item.res[2].outputs = outputs

            func_config['start_data']['cnode_refs'] = inst_id_refs
            item.start_item(func_config['start_data'])

            # cnodes
            _load_cnode(func_config['cnode_list'], item.route, inst_id_refs)

            # func instances
            for cnode_config: Dictionary in func_config['instances']:
                var cnode_data: Dictionary = {
                    type = 'func',
                    item = item,
                    cnode_id = cnode_config.hash,
                    route_inst_id = cnode_config.route_inst_id,
                    data = {
                        pos = cnode_config.pos,
                        route = item.route
                    }
                }

                if cnode_config.has('in_prop_data'):
                    cnode_data['in_prop_data'] = cnode_config.get('in_prop_data')
                
                cnode_to_route_list.append(cnode_data)
            
            inst_id_refs[func_config.id] = item

        # ---------------------------------------------------------------------------- #
        # creating vars
        for var_config: Dictionary in data['var_item_list']:
            var item = _Global.SIDE_BAR.get_node('%Var').add_prop(var_config)

            # instances
            for cnode_config: Dictionary in var_config['instances']:
                var id = -1
                match cnode_config['sub_type']:
                    'var':
                        id = 0
                    'set_var':
                        id = 1
                
                var cnode_data: Dictionary = {
                    type = 'var',
                    item = item,
                    id = id,
                    cnode_id = cnode_config.hash,
                    route_inst_id = cnode_config.route_inst_id,
                    data = {
                        pos = cnode_config.pos,
                    }
                }

                if cnode_config.has('in_prop_data'):
                    cnode_data['in_prop_data'] = cnode_config.get('in_prop_data')
                
                cnode_to_route_list.append(cnode_data)
            
            inst_id_refs[var_config.id] = item
        
        # ---------------------------------------------------------------------------- #
        # creating signals
        for signal_config: Dictionary in data['signal_item_list']:
            var item = _Global.SIDE_BAR.get_node('%StateSignal').add_prop(signal_config, false)
            var params: Array[Dictionary] = []

            # params
            for input: Dictionary in signal_config['params']:
                var res: Resource = load('res://addons/hengo/resources/cnode_function_in_out.tres').duplicate()
                res.name = input.name
                res.type = input.type
                params.append({res = res})
            
            item.res[1].outputs = params

            signal_config['start_data']['cnode_refs'] = inst_id_refs
            item.start_item(signal_config['start_data'])

            # cnodes
            _load_cnode(signal_config['cnode_list'], item.route, inst_id_refs)

            # signal instances
            for cnode_config: Dictionary in signal_config['instances']:
                var id = -1
                match cnode_config['sub_type']:
                    'signal_connection':
                        id = 0
                    'signal_disconnection':
                        id = 1
                    'signal_emit':
                        id = 2
                
                var cnode_data: Dictionary = {
                    type = 'signal',
                    item = item,
                    id = id,
                    cnode_id = cnode_config.hash,
                    route_inst_id = cnode_config.route_inst_id,
                    data = {
                        pos = cnode_config.pos,
                    }
                }

                if cnode_config.has('in_prop_data'):
                    cnode_data['in_prop_data'] = cnode_config.get('in_prop_data')

                cnode_to_route_list.append(cnode_data)

            inst_id_refs[signal_config.id] = item

                # ---------------------------------------------------------------------------- #
        # creating local_vars
        for local_var_config: Dictionary in data['local_var_items']:
            # local var route ref
            local_var_config['route_ref'] = inst_id_refs[
                local_var_config['route_ref']
            ].route

            var item = local_var_section.add_prop(local_var_config)

            # instances
            for cnode_config: Dictionary in local_var_config['instances']:
                var id = -1
                match cnode_config['sub_type']:
                    'local_var':
                        id = 0
                    'set_local_var':
                        id = 1
                
                var cnode_data: Dictionary = {
                    type = 'local_var',
                    item = item,
                    id = id,
                    cnode_id = cnode_config.hash,
                    route_inst_id = cnode_config.route_inst_id,
                    data = {
                        pos = cnode_config.pos,
                    }
                }

                if cnode_config.has('in_prop_data'):
                    cnode_data['in_prop_data'] = cnode_config.get('in_prop_data')
                
                cnode_to_route_list.append(cnode_data)
            
            inst_id_refs[local_var_config.id] = item

        # ---------------------------------------------------------------------------- #
        # instancing side bar items references
        for cnode_config: Dictionary in cnode_to_route_list:
            var id = -1

            if cnode_config.has('id'):
                id = cnode_config.id

            _Global.DROP_PROP_MENU.mount(cnode_config.item.type, cnode_config.item, cnode_config.item.data, false)
            
            var cnode_data: Dictionary = {
                pos = cnode_config.data.pos,
                route = inst_id_refs[cnode_config.route_inst_id].route,
                hash = cnode_config.cnode_id
            }

            if cnode_config.has('in_prop_data'):
                cnode_data['in_prop_data'] = cnode_config.get('in_prop_data')

            var cnode = _Global.DROP_PROP_MENU.add_instance(id, cnode_data)

            inst_id_refs[cnode_config.cnode_id] = cnode

        # ---------------------------------------------------------------------------- #
        # creating comments
        var comment_scene = load('res://addons/hengo/scenes/utils/comment.tscn')
        for comment_config: Dictionary in data['comments']:
            var comment = comment_scene.instantiate()
            var router = inst_id_refs[comment_config.router_ref_id].route_ref

            comment.route_ref = router
            _Router.comment_reference[router.id].append(comment)

            comment.is_pinned = comment_config.is_pinned
            comment.position = str_to_var(comment_config.pos)
            comment.size = str_to_var(comment_config.size)
            comment.cnode_inside = comment_config.cnode_inside_ids.map(
                func(x: int) -> Variant:
                    return inst_id_refs[float(x)]
            )
            _Global.COMMENT_CONTAINER.add_child(comment)
            comment.check_pin.button_pressed = comment_config.is_pinned
            comment._on_color(str_to_var(comment_config.color as String) as Color)
            comment.get_node('%ColorButton').color = str_to_var(comment_config.color as String) as Color
            comment.set_comment(comment_config.comment)

        # ---------------------------------------------------------------------------- #
        # creating connections
        for connection: Dictionary in data['connections']:
            var from_in_out = (inst_id_refs[connection.from_cnode] as _CNode).get_node('%OutputContainer').get_child(connection.input)
            var to_cnode = (inst_id_refs[connection.to_cnode] as _CNode)
            var to_in_out

            match to_cnode.type:
                'if':
                    to_in_out = to_cnode.get_node('%TitleContainer').get_child(0).get_child(connection.output)
                _:
                    to_in_out = to_cnode.get_node('%InputContainer').get_child(connection.output)

            from_in_out.create_connection_and_instance({
                from = to_in_out,
                type = to_in_out.type,
                conn_type = to_in_out.connection_type,
            })
        
        # flow connections
        for flow_connection: Dictionary in data['flow_connections']:
            var cnode = inst_id_refs[flow_connection.from_cnode] as _CNode

            match cnode.cnode_type:
                'default':
                    var connector = cnode.get_node('%Container').get_children()[-1].get_child(0)

                    connector.create_connection_line_and_instance({
                        from_cnode = (inst_id_refs[flow_connection.to_cnode] as _CNode)
                    })
                'if':
                    var connector = cnode.get_node('%Container').get_child(2).get_node('%FlowContainer').get_child(flow_connection.from_connector)
                    
                    connector.create_connection_line_and_instance({
                        from_cnode = (inst_id_refs[flow_connection.to_cnode] as _CNode)
                    })

        _Router.change_route(_Global.start_state.route)

        # folding comments after add to scene
        for comment in _Global.COMMENT_CONTAINER.get_children():
            comment.pin_to_cnodes(true)

    # confirming queue free before check errors
    await _Global.CNODE_CAM.get_tree().process_frame

    # checking errors
    for state: _State in _Global.STATE_CONTAINER.get_children():
        _CodeGeneration.check_state_errors(state)

    # checking if debugging
    # change debugger script path
    if _Global.HENGO_DEBUGGER_PLUGIN:
        _Global.HENGO_DEBUGGER_PLUGIN.reload_script()


static func get_inst_id_by_route(_route: Dictionary) -> int:
    if _route.has('state_ref'):
        return _route.state_ref.hash
    elif _route.has('item_ref'):
        return _route.item_ref.get_instance_id()
    elif _route.has('general_ref'):
        return _route.general_ref.id

    return -1


static func parse_hengo_json(_source: String) -> Dictionary:
    var hengo_json: String = _source.split('\n').slice(0, 1)[0].split('#[hengo] ')[1]
    return JSON.parse_string(hengo_json)


static func parse_other_scripts_data(_dir: DirAccess) -> void:
    _dir.list_dir_begin()

    var file_name: String = _dir.get_next()

    # TODO cache script that don't changed
    while file_name != '':
        if _dir.current_is_dir():
            parse_other_scripts_data(DirAccess.open('res://hengo/' + file_name))
        else:
            var script: GDScript = ResourceLoader.load(_dir.get_current_dir() + '/' + file_name, '', ResourceLoader.CACHE_MODE_IGNORE)

            if script.source_code.begins_with('#[hengo] '):
                var data: Dictionary = parse_hengo_json(script.source_code)

                _Global.SCRIPTS_STATES[file_name.get_basename()] = []

                for state_dict: Dictionary in data['states'] as Array:
                    (_Global.SCRIPTS_STATES[file_name.get_basename()] as Array).append({name = state_dict.name})
                
                _Global.SCRIPTS_INFO.append({
                    name = 'Go to \'' + file_name.get_basename() + '\' state',
                    data = {
                        name = 'go_to_event',
                        fantasy_name = 'Go to \'' + file_name.get_basename() + '\' state',
                        sub_type = 'go_to_void',
                        inputs = [
                            {
                                name = 'hengo',
                                type = 'Node',
                            },
                            {
                                name = 'state',
                                type = '@dropdown',
                                category = 'hengo_states',
                                data = file_name.get_basename()
                            }
                        ]
                    }
                })
        
        file_name = _dir.get_next()

    _dir.list_dir_end()


static func script_has_state(_script_name: String, _state_name: String) -> bool:
    var has_state: bool = false

    var script: GDScript = ResourceLoader.load('res://hengo/' + _script_name + '.gd', '', ResourceLoader.CACHE_MODE_IGNORE)

    if script.source_code.begins_with('#[hengo] '):
        var data: Dictionary = parse_hengo_json(script.source_code)
    
        return data['states'].map(func(x: Dictionary) -> String: return x.name.to_lower()).has(_state_name)
    
    return has_state