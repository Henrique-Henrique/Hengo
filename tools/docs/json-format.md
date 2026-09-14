# JSON format

Schema read by `tools/hengo_actions.gd` (`HenHengoActions`). Every key below is the complete list: an unknown key inside a script, var, state, action, function, macro, use or param is a hard error (`unknown key "x" (valid: ...)`), never ignored.

Contents: [file shapes](#file-shapes) · [script](#script) · [vars](#vars) · [states](#states) · [actions](#actions) · [input values](#input-values) · [branches](#branches) · [body](#body) · [functions](#functions) · [macros](#macros) · [uses](#uses) · [params](#params) · [literal coercion](#literal-coercion)

## File shapes

One script at the top level:

```json
{ "name": "player", "extends": "CharacterBody2D", "collection": "Demo", "vars": [], "states": [] }
```

Many scripts in one collection:

```json
{
  "collection": "Demo",
  "debug": false,
  "scripts": [ { "name": "player", "states": [] }, { "name": "enemy", "states": [] } ]
}
```

| wrapper key | type | default | notes |
|---|---|---|---|
| `scripts` | array of script | none | when absent or empty, the whole file is one script |
| `collection` | string | CLI argument, then `"AI"` | the json value wins over the `[collection_name]` argument |
| `debug` | bool | `false` | emits debug traces for the Hengo state debugger |

Any other wrapper key is an error. Order inside `scripts` does not matter: every script is declared before any action is built.

## Script

| key | type | req | notes |
|---|---|---|---|
| `name` | string | no, default `"generated"` | snake_cased. Output is `res://hengo/scripts/<name>.gd`. Used by cross-script branches |
| `extends` | string | no, default `"Node"` | native Godot class. An unknown class is an error |
| `vars` | array of [var](#vars) | no | script variables |
| `states` | array of [state](#states) | no | top-level states |
| `functions` | array of [function](#functions) | no | |
| `macros` | array of [macro](#macros) | no | state macros |
| `collection` | string | no | read only when the file is a single script |
| `debug` | bool | no | read only when the file is a single script |

Build order inside a script: vars, functions, macros, states (declared), then function bodies, macro states, states (actions built). A state may use a macro and an action may call a function whatever order the json lists them.

## Vars

| key | type | req | notes |
|---|---|---|---|
| `name` | string | yes | snake_cased (`"moveSpeed"` becomes `move_speed`). Duplicates are an error |
| `type` | string | no, default `"Variant"` | `int`, `float`, `bool`, `String`, `StringName`, `NodePath`, `Color`, `Vector2`, `Vector2i`, `Vector3`, `Vector3i`, any Godot class, `Array`, `Dictionary` |
| `value` | any | no | initial value, [coerced](#literal-coercion) by `type`. A node type always starts `null` |
| `export` | bool | no | emits `@export` |

```json
"vars": [
  { "name": "speed", "type": "float", "value": 200.0, "export": true },
  { "name": "dir", "type": "Vector2", "value": [1, 0] },
  { "name": "target", "type": "Variant" }
]
```

Generated code reads a var from a state as `_ref.<name>`.

## States

Used in `states`, `sub_states` and macro `states`.

| key | type | req | notes |
|---|---|---|---|
| `name` | string | yes | unique across the whole script, sub-states and macro states included. Emitted as snake_case key and PascalCase class |
| `start` | bool | no | start state of its level. The first state of each level is start unless a sibling sets `start` |
| `can_reenter` | bool | no, default `false` | when false, a transition to the state that is already running does nothing |
| `description` | string | no | |
| `actions` | array of [action](#actions) | no | |
| `sub_states` | array of state | no | nested machine that runs while this state runs |
| `uses` | array of [use](#uses) | no | macro instances, siblings of `sub_states` |

## Actions

| key | type | req | notes |
|---|---|---|---|
| `id` | string | yes | action id from the catalog, or `fn:<function>`, `finish:<function>`, `run:<hook>`. Unknown id errors with a "did you mean" hint |
| `phase` | string | no, default from the action | `enter`, `update`, `physics`, `exit`. Must be in the action's supported phases. Ignored for nested actions (see below) |
| `inputs` | object | no | slot id or slot name to [value](#input-values). Omitted slots keep their default |
| `branches` | object | no | branch id or branch name to [target](#branches) |
| `body` | array of action | no | only for actions with `has_body` |
| `ref` | string | no | handle so a later step can read this step's outputs with `wire`. Unique across the whole script |
| `label` | string | no | display name in the editor |
| `disabled` | bool | no | kept in the graph, emits nothing |

Nested actions (inside `body`, inside a branch `actions`, or used as an inline input `action`) run at the phase of the action that holds them, so their `phase` is ignored. Inside a function body, `phase` is validated but the steps simply run in order on each call: omit it.

Do not confuse the action key `ref` (a wire handle) with the input slot named `ref` that node actions declare (`"inputs": {"ref": {"path": "Sprite"}}`, the node to act on).

## Input values

An object value is read as `wire`, then `action`, then `expr`, then a source (`bind`, `path`, `arg`, `native`, `prop`). Put one form per object.

| form | meaning | refused on |
|---|---|---|
| `{"wire": {"from": "<ref>", "output": "<output id or name>"}}` | reads an output of an earlier step with that `ref` | `lvalue` slots |
| `{"action": {"id": "...", "inputs": {}}, "output": "<id>"}` | runs a pure producer inline. `output` defaults to its first output | `lvalue` and `bind_only` slots, non-inlinable actions |
| `{"expr": "<gdscript>", "words": {"w": <value>}}` | free expression. Each word is replaced by its binding | `lvalue` slots (reported as exit 2, before writing) |
| `{"bind": "<var>"}` | script variable (snake_cased) | |
| `{"prop": "<property>"}` | property of the owner node, e.g. `"velocity"`, `"position"` | |
| `{"path": "<NodePath>"}` | node relative to the owner, `get_node("...")` | |
| `{"native": "<source>"}` | engine value, see below | sources the script class cannot answer |
| `{"arg": "<input name>"}` | input of the function or macro being built | outside `functions` and `macros` |
| scalar, array | literal, [coerced](#literal-coercion) to the slot type | wrong type after coercion |

Slot flags (shown by `--preview` and the catalog):

- `lvalue`: assignment target. Needs `bind` or `prop`.
- `bind_only`: needs a source (`bind`, `prop`, `path`, `native`, `arg`), no literal.
- `raw`: pasted into the code as written. With `options`, the value must be one of them.
- `optional`: may stay empty.
- `type_from: "<slot>"`: the literal is cast to the type the other slot is bound to.

Expression words: a word value that is an object is a source (`bind`, `prop`, `path`, `native`, `arg`); a scalar is pasted as raw text. Words match whole identifiers outside string literals. Anything that is not a word stays literal GDScript (`sin`, `clampf`, `Vector3`).

```json
"value": { "expr": "dir * speed", "words": { "dir": { "bind": "dir" }, "speed": { "bind": "speed" } } }
```

Native sources: `Self (this node)`, `Delta`, `Mouse Position`, `Mouse X`, `Mouse Y` (CanvasItem), `Mouse Screen Position`, `Screen Size`, `Any Key Pressed`, `Speed`, `Velocity` (RigidBody3D), `Random Float (0-1)`, `Random Bool`, `Random Angle`, `Random Direction`, `Random Color`. Sources with an argument are written `"<name or key>:<argument>"`: `"Action strength:ui_right"`, `"action_pressed:jump"`, `"key_pressed:KEY_SHIFT"`, `"mouse_pressed:MOUSE_BUTTON_LEFT"`, `"path:Hud/Label"`.

Wire example:

```json
{ "id": "get_distance", "ref": "reading", "inputs": { "target": { "path": "../Player" } } },
{ "id": "compare", "inputs": { "a": { "wire": { "from": "reading", "output": "distance" } }, "op": "<", "b": 120.0 },
  "branches": { "true": "Alert" } }
```

Inline example:

```json
"value": { "action": { "id": "math_operator", "inputs": { "a": 3, "op": "*", "b": 2 } }, "output": "result" }
```

## Branches

Key: the branch id (`to`, `true`, `false`, `finished`, ...) or its name. Value, one of:

| form | meaning |
|---|---|
| `"StateName"` | transition to a state of this script |
| `{"state": "StateName", "label": "..."}` | same, with a label |
| `{"script": "<script name>", "state": "StateName", "instance": "<var>", "check_instance": true}` | drive another script's machine. `instance` is a var of this script holding the node |
| `{"script": "...", "state": "...", "path": "<NodePath>"}` | same, the node found by path. `instance` or `path` is required |
| `{"way_out": "<name>", "label": "..."}` | leave the macro or function being built through that way out |
| `{"actions": [ ... ]}` | steps run in place, staying in the state |

A branch runs steps or goes to a state, never both: `{"actions": [...], "state": "X"}` is an error. End the steps with a `transition` action instead:

```json
"branches": {
  "true": { "actions": [
    { "id": "print_value", "inputs": { "value": "hit" } },
    { "id": "transition", "branches": { "to": "Hurt" } }
  ] }
}
```

`check_instance: true` skips the transition when the instance is freed or has no Hengo machine. A sub-state target is only reachable from its parent, a sibling or a descendant. Cross-script targets must be top-level states.

## Body

Only for actions whose `has_body` is true (`do_if`, `repeat`, `for_each`, `every`, ...). The nested list runs inside the loop or condition, at the owner's phase.

```json
{ "id": "every", "phase": "update", "inputs": { "seconds": 2.0 },
  "body": [ { "id": "print_value", "inputs": { "value": "tick" } } ] }
```

## Functions

| key | type | req | notes |
|---|---|---|---|
| `name` | string | yes | unique. Becomes a method of the script |
| `description` | string | no | |
| `inputs` | array of [param](#params) | no | read in the body with `{"arg": "<name>"}` |
| `outputs` | array of [param](#params) | no | |
| `ways_out` | array of `{name, doc}` | no | named exits the caller branches on |
| `actions` | array of action | no | the body, run in order on each call |

Calling: `{"id": "fn:<name>", "inputs": {...}, "branches": {"<way out name>": "State"}}`. Inputs and branches of the call accept the param or way out name. When the function declares `ways_out`, at least one must be wired or the call is unresolved (`no branch target set`). A call is a normal action: give it a `ref` and read its outputs with `wire`, or use it inline when it has no ways out and one output. A `wire` names the output by **id** (`<function snake>_<output snake>`, e.g. `mouse_in_range_distance`), not by name.

Finishing: `{"id": "finish:<name>", "inputs": {"<output id>": value, "branch": "<way out>"}}`. Only inside that function. `branch` takes the way out name (`close`) or its id (`check_player_close`, `<function snake>_<way out snake>`).

A function body cannot transition its own script (cross-script branches are allowed). It runs outside any phase, so an action whose template uses `delta` is refused there (`uses delta, which a function does not have`, exit 2).

Full working file with functions, a macro, hooks and uses: [`examples/04_function_macro.json`](../examples/04_function_macro.json).

```json
"functions": [ {
  "name": "check player",
  "inputs": [ { "name": "range", "type": "float", "value": 120.0 } ],
  "ways_out": [ { "name": "close" }, { "name": "far" } ],
  "actions": [
    { "id": "get_distance", "ref": "reading", "inputs": { "target": { "path": "../Player" } } },
    { "id": "compare",
      "inputs": { "a": { "wire": { "from": "reading", "output": "distance" } }, "op": "<", "b": { "arg": "range" } },
      "branches": {
        "true":  { "actions": [ { "id": "finish:check player", "inputs": { "branch": "check_player_close" } } ] },
        "false": { "actions": [ { "id": "finish:check player", "inputs": { "branch": "check_player_far" } } ] }
      } }
  ]
} ]
```

## Macros

A reusable state machine, instanced by [uses](#uses).

| key | type | req | notes |
|---|---|---|---|
| `name` | string | yes | unique |
| `description` | string | no | |
| `inputs` | array of [param](#params) | no | read inside with `{"arg": "<name>"}` |
| `hooks` | array of `{name, doc}` | no | places each use fills with its own steps. Run inside with `{"id": "run:<hook name>"}` |
| `ways_out` | array of `{name, doc}` | no | exits. Taken inside with a branch `{"way_out": "<name>"}` |
| `states` | array of [state](#states) | yes, at least one | first is start unless one sets `start`. Names are unique across the whole script |

## Uses

An instance of a macro inside a state.

| key | type | req | notes |
|---|---|---|---|
| `macro` | string | yes | macro name |
| `name` | string | no, default macro name | state name of this use, unique across the script. Required when a state has two uses of one macro |
| `start` | bool | no | start of its parent's sub-machine. The first entry of that list starts by default |
| `can_reenter` | bool | no | |
| `inputs` | object | no | input name to literal, or `{bind}`, `{prop}`, `{path}`, `{native}`, `{arg}` (no `expr`, `wire`, `action`) |
| `steps` | object | no | hook name (or `enter`, `update`, `physics`, `exit`) to array of actions |
| `ways_out` | object | no | way out name to a state name of this script |

```json
"uses": [ {
  "macro": "Weapon", "name": "Pistol", "start": true,
  "inputs": { "label": "PISTOL", "rounds": 12 },
  "steps": { "on ready": [ { "id": "print_value", "inputs": { "value": "pistol" } } ] },
  "ways_out": { "next": "Machine" }
} ]
```

## Params

Inputs and outputs of functions and macros.

| key | type | req | notes |
|---|---|---|---|
| `name` | string | yes | slot name. Its id is `<owner snake>_<name snake>` |
| `type` | string | no, default `"Variant"` | |
| `value` | any | no | default, coerced by `type` |
| `doc` | string | no | tooltip |

`ways_out` and `hooks` entries take `name` and `doc` only (not validated for extra keys).

## Literal coercion

JSON has no int, vector or color literal, so the slot type drives the cast:

| type | write | notes |
|---|---|---|
| `int` | `3` | |
| `float` | `3` or `3.0` | |
| `Variant` | `2` | a whole number becomes int, else float |
| `bool` | `true` | |
| `String`, `StringName`, `NodePath` | `"text"` | `\\n` in json for a newline in the string |
| `Color` | `[r, g, b]`, `[r, g, b, a]` or `"#ff8800"` | components 0 to 1 |
| `Vector2`, `Vector2i` | `[x, y]` | |
| `Vector3`, `Vector3i` | `[x, y, z]` | |
| `raw` slot with options | `"MOUSE_MODE_CAPTURED"` | exactly one of `options`, an engine constant, not a word |

A literal whose type still differs after coercion is an error (`input "x" expects Vector2, got String`).
